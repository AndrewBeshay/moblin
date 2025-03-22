import SwiftUI
import WebKit
import Foundation
import Security
import OSLog

private let twitchServer = "www.twitch.tv"
private let authorizeUrl = "https://id.twitch.tv/oauth2/authorize"
let twitchMoblinAppClientId = "qv6bnocuwapqigeqjoamfhif0cv2xn"
private let scopes = [
    "user:read:chat",
    "user:write:chat",
    "moderator:read:followers",
    "channel:read:subscriptions",
    "channel:read:redemptions",
    "channel:read:stream_key",
    "channel:read:hype_train",
    "channel:read:ads",
    "channel:manage:broadcast",
    "channel:edit:commercial",
    "bits:read",
    "user:bot",
    "channel:bot"
]


private let redirectHost = "localhost"
private let redirectUri = "https://\(redirectHost)"

// MARK: - Configuration
struct TwitchAuthConfig {
    static let clientId = "your_client_id"
    static let clientSecret = "your_client_secret"
    static let redirectUri = "your_redirect_uri"
    static let scopes = [
        "user:read:chat",
        "user:write:chat",
        "moderator:read:followers",
        "channel:read:subscriptions",
        "channel:read:redemptions",
        "channel:read:stream_key",
        "channel:read:hype_train",
        "channel:read:ads",
        "channel:manage:broadcast",
        "channel:edit:commercial",
        "bits:read",
        "user:bot",
        "channel:bot"
    ]
    static let tokenRefreshThreshold: TimeInterval = 300 // 5 minutes
    static let userInfoCacheTimeout: TimeInterval = 300 // 5 minutes
    static let minimumApiCallInterval: TimeInterval = 1.0
}

// MARK: - Error Types
enum TwitchAuthError: Error {
    case invalidToken
    case networkError(Error)
    case invalidResponse
    case unauthorized
    case tokenRefreshFailed
    case userInfoFetchFailed
    case invalidUserData
    case rateLimitExceeded
    case invalidState
    
    var localizedDescription: String {
        switch self {
        case .invalidToken:
            return "Invalid authentication token"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Unauthorized access"
        case .tokenRefreshFailed:
            return "Failed to refresh authentication token"
        case .userInfoFetchFailed:
            return "Failed to fetch user information"
        case .invalidUserData:
            return "Invalid user data received"
        case .rateLimitExceeded:
            return "Rate limit exceeded"
        case .invalidState:
            return "Invalid authentication state"
        }
    }
}

// MARK: - State Management
enum AuthState {
    case unauthenticated
    case authenticating
    case authenticated
    case error(TwitchAuthError)
}

// MARK: - Protocols
protocol TwitchAuthProtocol {
    var accessToken: String? { get }
    var refreshToken: String? { get }
    var userInfo: TwitchUserInfo? { get }
    func refreshToken() async throws
    func fetchUserInfo() async throws
    func cleanup()
}

protocol TwitchAuthDelegate: AnyObject {
    func twitchAuthStateDidChange(_ state: AuthState)
    func twitchAuthDidReceiveUserInfo(_ userInfo: TwitchUserInfo)
}

struct TwitchAuthView: UIViewRepresentable {
    let twitchAuth: TwitchAuth

    func makeUIView(context _: Context) -> WKWebView {
        return twitchAuth.getWebBrowser()
    }

    func updateUIView(_: WKWebView, context _: Context) {}
}

class TwitchAuth: NSObject, TwitchAuthProtocol {
    // MARK: - Properties
    private let logger = Logger(subsystem: "com.moblin.twitch", category: "auth")
    private var webBrowser: WKWebView?
    private var onAccessToken: ((String) -> Void)?
    private var currentState: AuthState = .unauthenticated {
        didSet {
            delegate?.twitchAuthStateDidChange(currentState)
        }
    }
    
    private var tokenExpirationDate: Date?
    private var cachedUserInfo: TwitchUserInfo?
    private var lastUserInfoFetch: Date?
    private var lastApiCall: Date?
    
    private var isTokenExpired: Bool {
        guard let expirationDate = tokenExpirationDate else { return true }
        return Date() >= expirationDate
    }
    
    private var shouldRefreshToken: Bool {
        guard let expirationDate = tokenExpirationDate else { return true }
        return Date().addingTimeInterval(TwitchAuthConfig.tokenRefreshThreshold) >= expirationDate
    }
    
    private var shouldRefreshUserInfo: Bool {
        guard let lastFetch = lastUserInfoFetch else { return true }
        return Date().timeIntervalSince(lastFetch) > TwitchAuthConfig.userInfoCacheTimeout
    }
    
    weak var delegate: TwitchAuthDelegate?
    
    // MARK: - Token Management
    var accessToken: String? {
        get {
            KeychainService.get(key: "twitch_access_token")
        }
        set {
            if let token = newValue {
                KeychainService.save(key: "twitch_access_token", data: token.utf8Data)
            } else {
                KeychainService.delete(key: "twitch_access_token")
            }
        }
    }
    
    var refreshToken: String? {
        get {
            KeychainService.get(key: "twitch_refresh_token")
        }
        set {
            if let token = newValue {
                KeychainService.save(key: "twitch_refresh_token", data: token.utf8Data)
            } else {
                KeychainService.delete(key: "twitch_refresh_token")
            }
        }
    }
    
    // MARK: - User Info
    var userInfo: TwitchUserInfo? {
        cachedUserInfo
    }
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupTokenExpiration()
    }
    
    private func setupTokenExpiration() {
        if let token = accessToken {
            // Set expiration to 1 hour from now (Twitch tokens typically last 1 hour)
            tokenExpirationDate = Date().addingTimeInterval(3600)
            scheduleTokenRefresh()
        }
    }
    
    // MARK: - Public Methods
    func refreshToken() async throws {
        guard let refreshToken = refreshToken else {
            throw TwitchAuthError.invalidToken
        }
        
        currentState = .authenticating
        logAuthEvent("Refreshing token", level: .info)
        
        do {
            try await rateLimitCheck()
            let (newAccessToken, newRefreshToken) = try await refreshAccessToken(refreshToken)
            
            self.accessToken = newAccessToken
            self.refreshToken = newRefreshToken
            self.tokenExpirationDate = Date().addingTimeInterval(3600)
            
            scheduleTokenRefresh()
            currentState = .authenticated
            
            logAuthEvent("Token refreshed successfully", level: .info)
        } catch {
            currentState = .error(.tokenRefreshFailed)
            logAuthEvent("Token refresh failed: \(error.localizedDescription)", level: .error)
            throw TwitchAuthError.tokenRefreshFailed
        }
    }
    
    func fetchUserInfo() async throws {
        guard let accessToken = accessToken else {
            throw TwitchAuthError.invalidToken
        }
        
        if !shouldRefreshUserInfo, let cachedInfo = cachedUserInfo {
            return
        }
        
        do {
            try await rateLimitCheck()
            let userInfo = try await fetchUserInfoFromTwitch(accessToken)
            
            self.cachedUserInfo = userInfo
            self.lastUserInfoFetch = Date()
            
            delegate?.twitchAuthDidReceiveUserInfo(userInfo)
            logAuthEvent("User info fetched successfully", level: .info)
        } catch {
            currentState = .error(.userInfoFetchFailed)
            logAuthEvent("Failed to fetch user info: \(error.localizedDescription)", level: .error)
            throw TwitchAuthError.userInfoFetchFailed
        }
    }
    
    func cleanup() {
        cachedUserInfo = nil
        lastUserInfoFetch = nil
        lastApiCall = nil
        tokenExpirationDate = nil
        accessToken = nil
        refreshToken = nil
        currentState = .unauthenticated
    }
    
    // MARK: - Private Methods
    private func refreshAccessToken(_ refreshToken: String) async throws -> (String, String) {
        let url = URL(string: "https://id.twitch.tv/oauth2/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyParams = [
            "client_id": twitchMoblinAppClientId,
            "client_secret": TwitchAuthConfig.clientSecret,
            "grant_type": "refresh_token",
            "refresh_token": refreshToken
        ]
        
        request.httpBody = bodyParams
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TwitchAuthError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            logger.error("Token refresh failed with status code: \(httpResponse.statusCode)")
            throw TwitchAuthError.tokenRefreshFailed
        }
        
        struct TokenResponse: Codable {
            let access_token: String
            let refresh_token: String
            let expires_in: Int
            let token_type: String
            let scope: [String]
        }
        
        let decoder = JSONDecoder()
        let tokenResponse = try decoder.decode(TokenResponse.self, from: data)
        
        return (tokenResponse.access_token, tokenResponse.refresh_token)
    }
    
    private func fetchUserInfoFromTwitch(_ accessToken: String) async throws -> TwitchUserInfo {
        let url = URL(string: "https://api.twitch.tv/helix/users")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(twitchMoblinAppClientId, forHTTPHeaderField: "Client-Id")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TwitchAuthError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            logger.error("User info fetch failed with status code: \(httpResponse.statusCode)")
            throw TwitchAuthError.userInfoFetchFailed
        }
        
        struct UserResponse: Codable {
            let data: [TwitchUserInfo]
        }
        
        let decoder = JSONDecoder()
        let userResponse = try decoder.decode(UserResponse.self, from: data)
        
        guard let userInfo = userResponse.data.first else {
            throw TwitchAuthError.invalidUserData
        }
        
        return userInfo
    }
    
    private func scheduleTokenRefresh() {
        guard let expirationDate = tokenExpirationDate else { return }
        let refreshInterval = expirationDate.timeIntervalSinceNow - TwitchAuthConfig.tokenRefreshThreshold
        DispatchQueue.global().asyncAfter(deadline: .now() + refreshInterval) { [weak self] in
            Task {
                try? await self?.refreshToken()
            }
        }
    }
    
    private func rateLimitCheck() async throws {
        if let lastCall = lastApiCall {
            let timeSinceLastCall = Date().timeIntervalSince(lastCall)
            if timeSinceLastCall < TwitchAuthConfig.minimumApiCallInterval {
                try await Task.sleep(nanoseconds: UInt64((TwitchAuthConfig.minimumApiCallInterval - timeSinceLastCall) * 1_000_000_000))
            }
        }
        lastApiCall = Date()
    }
    
    private func logAuthEvent(_ event: String, level: OSLogType = .debug) {
        logger.log(level: level, "\(event)")
    }
    
    // MARK: - Web Browser
    func getWebBrowser() -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        webBrowser = WKWebView(frame: .zero, configuration: configuration)
        webBrowser!.navigationDelegate = self
        webBrowser!.load(URLRequest(url: buildAuthUrl()!))
        return webBrowser!
    }
    
    func setOnAccessToken(onAccessToken: @escaping ((String) -> Void)) {
        self.onAccessToken = onAccessToken
    }
    
    private func buildAuthUrl() -> URL? {
        guard var urlComponents = URLComponents(string: authorizeUrl) else {
            return nil
        }
        urlComponents.queryItems = [
            .init(name: "client_id", value: twitchMoblinAppClientId),
            .init(name: "redirect_uri", value: redirectUri),
            .init(name: "response_type", value: "token"),
            .init(name: "scope", value: scopes.joined(separator: "+")),
        ]
        return urlComponents.url
    }
    
    // ... rest of existing code ...
}

// MARK: - WKNavigationDelegate
extension TwitchAuth: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {
        guard let url = webView.url else {
            return
        }
        guard url.host() == redirectHost else {
            return
        }
        guard let fragment = url.fragment() else {
            return
        }
        guard let urlComponents = URLComponents(string: "foo:///?\(fragment)") else {
            return
        }
        guard let token = urlComponents.queryItems?.first(where: { item in
            item.name == "access_token"
        }) else {
            return
        }
        guard let accessToken = token.value else {
            return
        }
        onAccessToken?(accessToken)
    }
}

private func updateAccessTokenInKeychain(streamId: String, accessTokenData: Data) -> Bool {
    let query: [String: Any] = [
        kSecClass as String: kSecClassInternetPassword,
        kSecAttrServer as String: twitchServer,
        kSecAttrAccount as String: streamId,
    ]
    let attributes: [String: Any] = [
        kSecAttrAccount as String: streamId,
        kSecValueData as String: accessTokenData,
    ]
    let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    guard status != errSecItemNotFound else {
        return false
    }
    guard status == errSecSuccess else {
        logger.info("twitch: auth: Failed to update item in keychain")
        return false
    }
    return true
}

private func addAccessTokenInKeychain(streamId: String, accessTokenData: Data) {
    let attributes: [String: Any] = [
        kSecClass as String: kSecClassInternetPassword,
        kSecAttrServer as String: twitchServer,
        kSecAttrAccount as String: streamId,
        kSecValueData as String: accessTokenData,
    ]
    let status = SecItemAdd(attributes as CFDictionary, nil)
    guard status == errSecSuccess else {
        logger.info("twitch: auth: Failed to add item to keychain")
        return
    }
}

func storeTwitchAccessTokenInKeychain(streamId: UUID, accessToken: String) {
    guard let accessTokenData = accessToken.data(using: .utf8) else {
        return
    }
    let streamId = streamId.uuidString
    if !updateAccessTokenInKeychain(streamId: streamId, accessTokenData: accessTokenData) {
        addAccessTokenInKeychain(streamId: streamId, accessTokenData: accessTokenData)
    }
}

func loadTwitchAccessTokenFromKeychain(streamId: UUID) -> String? {
    let query: [String: Any] = [
        kSecClass as String: kSecClassInternetPassword,
        kSecAttrServer as String: twitchServer,
        kSecAttrAccount as String: streamId.uuidString,
        kSecMatchLimit as String: kSecMatchLimitOne,
        kSecReturnAttributes as String: true,
        kSecReturnData as String: true,
    ]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    guard status != errSecItemNotFound else {
        return nil
    }
    guard status == errSecSuccess else {
        logger.info("twitch: auth: Failed to query item to keychain")
        return nil
    }
    guard let existingItem = item as? [String: Any],
          let accessTokenData = existingItem[kSecValueData as String] as? Data,
          let accessToken = String(data: accessTokenData, encoding: String.Encoding.utf8)
    else {
        logger.info("twitch: auth: Failed to lookup attributes")
        return nil
    }
    return accessToken
}

func removeTwitchAccessTokenInKeychain(streamId: UUID) {
    let query: [String: Any] = [
        kSecClass as String: kSecClassInternetPassword,
        kSecAttrServer as String: twitchServer,
        kSecAttrAccount as String: streamId.uuidString,
    ]
    let status = SecItemDelete(query as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
        logger.info("twitch: auth: Keychain delete failed")
        return
    }
}
