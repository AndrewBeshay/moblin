//
//  TwitchAPI.swift
//  Moblin
//

import Foundation
import os.log

final class TwitchAPI {
    static let shared = TwitchAPI()

    private let clientId: String
    private var accessToken: String
    private let urlSession: URLSession

    // Example logger reference:
    private let logger = Logger(subsystem: "com.moblin.TwitchAPI", category: "Networking")

    lazy var chat = TwitchAPIChat(api: self)
    lazy var streams = TwitchAPIStreams(api: self)
    lazy var users = TwitchAPIUsers(api: self)
    lazy var channels = TwitchAPIChannel(api: self)
    lazy var channelPoints = TwitchAPIChannelPoints(api: self)
    lazy var eventSub = TwitchAPIEventSub(api: self)
    lazy var bits = TwitchAPIBits(api: self)
    lazy var ads = TwitchAPIAds(api: self)
    lazy var subscriptions = TwitchAPISubscriptions(api: self)

    private init(clientId: String = twitchMoblinAppClientId, accessToken: String = "") {
        self.clientId = clientId
        self.accessToken = accessToken
        self.urlSession = URLSession.shared
    }

    /// Dynamically update the access token
    func setAccessToken(_ newToken: String) {
        accessToken = newToken
    }

    /// Internal method for making API calls (now with detailed logging)
    func sendRequest(
        method: String,
        subPath: String,
        body: Data? = nil,
        onComplete: @escaping (Data?, URLResponse?) -> Void
    ) {
        guard let url = URL(string: "https://api.twitch.tv/helix/\(subPath)") else {
            logger.error("❌ Invalid URL: \(subPath)")
            onComplete(nil, nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(clientId, forHTTPHeaderField: "Client-Id")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        if let body = body, method != "GET" {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body

            // Log the body payload (if JSON)
            if let jsonString = String(data: body, encoding: .utf8) {
                logger.debug("📨 Request Body: \(jsonString, privacy: .public)")
            }
        }

        // Log the full URL and method + optional token
        logger.info("📡 Sending \(method, privacy: .public) request to \(url.absoluteString, privacy: .public)")
        logger.info("🔹 Bearer Token: \(self.accessToken, privacy: .private)")

        let task = urlSession.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                // 1) Check for any network error
                if let error = error {
                    self.logger.error("❌ Network error: \(error.localizedDescription, privacy: .public)")
                    onComplete(nil, response)
                    return
                }

                // 2) Check HTTP response code
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.logger.error("❌ Invalid HTTP response.")
                    onComplete(nil, response)
                    return
                }

                self.logger.info("📡 HTTP Status: \(httpResponse.statusCode, privacy: .public) for \(url.absoluteString, privacy: .public)")

                if httpResponse.statusCode == 204 {
                    // ✅ Handle 204 No Content as success
                    self.logger.info("✅ Success: 204 No Content received - No response body expected.")
                    onComplete(nil, response) // No body expected for 204
                    return
                }
                
                // If not 200-299, log and return nil
                guard (200...299).contains(httpResponse.statusCode), let data = data else {
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        self.logger.error("❌ Non-200 Response Body: \(responseString, privacy: .public)")
                    } else {
                        self.logger.error("❌ No data or non-success status.")
                    }
                    onComplete(nil, response)
                    return
                }
                
                // 5) Finally, call completion with the data
                onComplete(data, response)
            }
        }
        task.resume()
    }
}
