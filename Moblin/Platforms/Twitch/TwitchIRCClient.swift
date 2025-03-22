import Foundation
import Network

/// Protocol defining the interface for Twitch IRC client
protocol TwitchIRCClientProtocol: AnyObject {
    var delegate: TwitchIRCClientDelegate? { get set }
    func connect()
    func disconnect()
    func joinChannel(_ channel: String)
    func sendMessage(_ message: String, to channel: String)
    func sendPing()
}

/// Delegate protocol for TwitchIRCClient events
protocol TwitchIRCClientDelegate: AnyObject {
    func ircClient(_ client: TwitchIRCClient, didReceiveMessage message: TwitchChatMessage)
    func ircClient(_ client: TwitchIRCClient, didConnect connection: NWConnection)
    func ircClient(_ client: TwitchIRCClient, didDisconnect error: Error?)
}

/// Represents a parsed Twitch chat message
struct TwitchChatMessage {
    // MARK: - Basic Message Properties
    let raw: String
    let tags: [String: String]
    let prefix: String?
    let command: String
    let parameters: [String]
    let channel: String?
    let message: String?
    
    // MARK: - User Information
    let userId: String?              // user-id
    let username: String?            // login
    let displayName: String?         // display-name
    let color: String?               // color
    let isModerator: Bool            // mod
    let isSubscriber: Bool           // subscriber
    let isTurbo: Bool               // turbo
    let isVIP: Bool                 // vip
    let isBroadcaster: Bool         // broadcaster
    let isMe: Bool                  // me
    
    // MARK: - Message Metadata
    let emotes: [TwitchEmote]       // emotes
    let badges: [TwitchBadge]       // badges
    let badgeInfo: [TwitchBadge]    // badge-info
    let bits: Int?                  // bits
    let bitsLeader: Int?            // bits-leader
    let roomId: String?             // room-id
    let messageId: String?          // id
    let clientNonce: String?        // client-nonce
    let customRewardId: String?     // custom-reward-id
    
    // MARK: - Message Flags
    let isAction: Bool              // action (/me)
    let isHighlighted: Bool         // highlighted
    let isFirstMessage: Bool        // first-msg
    let isReturningChatter: Bool    // returning-chatter
    let isEmoteOnly: Bool           // emote-only
    let isSlowMode: Bool            // slow
    let isFollowersOnly: Bool       // followers-only
    let isSubscribersOnly: Bool     // subscribers-only
    let isR9K: Bool                // r9k
    let isEmoteOnlyMode: Bool       // emote-only-mode
    
    // MARK: - Channel Information
    let channelFollowers: Int?      // followers
    let channelSubscribers: Int?    // subscribers
    let channelViewers: Int?        // viewers
    let channelHost: String?        // host
    let channelHostViewers: Int?    // host-viewers
    
    // MARK: - Timestamps
    let timestamp: Date?            // tmi-sent-ts
    let sentTimestamp: Date?        // sent-ts
    
    // MARK: - Initialization
    
    init(
        raw: String,
        tags: [String: String],
        prefix: String?,
        command: String,
        parameters: [String],
        channel: String?,
        message: String?,
        userId: String?,
        username: String?,
        displayName: String?,
        color: String?,
        isModerator: Bool,
        isSubscriber: Bool,
        isTurbo: Bool,
        isVIP: Bool,
        isBroadcaster: Bool,
        isMe: Bool,
        emotes: [TwitchEmote],
        badges: [TwitchBadge],
        badgeInfo: [TwitchBadge],
        bits: Int?,
        bitsLeader: Int?,
        roomId: String?,
        messageId: String?,
        clientNonce: String?,
        customRewardId: String?,
        isHighlighted: Bool,
        isFirstMessage: Bool,
        isReturningChatter: Bool,
        isEmoteOnly: Bool,
        isSlowMode: Bool,
        isFollowersOnly: Bool,
        isSubscribersOnly: Bool,
        isR9K: Bool,
        isEmoteOnlyMode: Bool,
        channelFollowers: Int?,
        channelSubscribers: Int?,
        channelViewers: Int?,
        channelHost: String?,
        channelHostViewers: Int?,
        timestamp: Date?,
        sentTimestamp: Date?
    ) {
        self.raw = raw
        self.tags = tags
        self.prefix = prefix
        self.command = command
        self.parameters = parameters
        self.channel = channel
        self.message = message
        
        // User Information
        self.userId = userId
        self.username = username
        self.displayName = displayName
        self.color = color
        self.isModerator = isModerator
        self.isSubscriber = isSubscriber
        self.isTurbo = isTurbo
        self.isVIP = isVIP
        self.isBroadcaster = isBroadcaster
        self.isMe = isMe
        
        // Message Metadata
        self.emotes = emotes
        self.badges = badges
        self.badgeInfo = badgeInfo
        self.bits = bits
        self.bitsLeader = bitsLeader
        self.roomId = roomId
        self.messageId = messageId
        self.clientNonce = clientNonce
        self.customRewardId = customRewardId
        
        // Message Flags
        self.isAction = isMe
        self.isHighlighted = isHighlighted
        self.isFirstMessage = isFirstMessage
        self.isReturningChatter = isReturningChatter
        self.isEmoteOnly = isEmoteOnly
        self.isSlowMode = isSlowMode
        self.isFollowersOnly = isFollowersOnly
        self.isSubscribersOnly = isSubscribersOnly
        self.isR9K = isR9K
        self.isEmoteOnlyMode = isEmoteOnlyMode
        
        // Channel Information
        self.channelFollowers = channelFollowers
        self.channelSubscribers = channelSubscribers
        self.channelViewers = channelViewers
        self.channelHost = channelHost
        self.channelHostViewers = channelHostViewers
        
        // Timestamps
        self.timestamp = timestamp
        self.sentTimestamp = sentTimestamp
    }
}

/// Represents a Twitch emote in a message
struct TwitchEmote {
    let id: String
    let name: String
    let range: Range<Int>
    let url: URL
}

/// Represents a Twitch badge in a message
struct TwitchBadge {
    let name: String
    let version: String
    let url: URL?
}

/// Main IRC client implementation for Twitch
final class TwitchIRCClient: TwitchIRCClientProtocol {
    // MARK: - Properties
    
    weak var delegate: TwitchIRCClientDelegate?
    private var connection: NWConnection?
    private let endpoint: NWEndpoint
    private let queue = DispatchQueue(label: "com.moblin.twitch.irc")
    private var isConnected = false
    private var pingTimer: Timer?
    private let oauthToken: String
    private let nickname: String
    
    // MARK: - Constants
    
    private enum Constants {
        static let host = "irc.chat.twitch.tv"
        static let port: UInt16 = 6697
        static let pingInterval: TimeInterval = 30
    }
    
    // MARK: - Initialization
    
    init(oauthToken: String, nickname: String) {
        self.oauthToken = oauthToken
        self.nickname = nickname
        
        let host = NWEndpoint.Host(Constants.host)
        let port = NWEndpoint.Port(integerLiteral: Constants.port)
        self.endpoint = NWEndpoint.hostPort(host: host, port: port)
    }
    
    // MARK: - TwitchIRCClientProtocol
    
    func connect() {
        let parameters = NWParameters.tls
        parameters.allowLocalEndpointReuse = true
        
        connection = NWConnection(to: endpoint, using: parameters)
        connection?.stateUpdateHandler = { [weak self] state in
            self?.handleConnectionState(state)
        }
        
        connection?.start(queue: queue)
        startPingTimer()
    }
    
    func disconnect() {
        stopPingTimer()
        connection?.cancel()
        isConnected = false
    }
    
    func joinChannel(_ channel: String) {
        sendCommand("JOIN #\(channel.lowercased())")
    }
    
    func sendMessage(_ message: String, to channel: String) {
        sendCommand("PRIVMSG #\(channel.lowercased()) :\(message)")
    }
    
    func sendPing() {
        sendCommand("PING :tmi.twitch.tv")
    }
    
    // MARK: - Private Methods
    
    private func handleConnectionState(_ state: NWConnection.State) {
        switch state {
        case .ready:
            isConnected = true
            authenticate()
            delegate?.ircClient(self, didConnect: connection!)
        case .failed(let error):
            isConnected = false
            delegate?.ircClient(self, didDisconnect: error)
        case .cancelled:
            isConnected = false
            delegate?.ircClient(self, didDisconnect: nil)
        default:
            break
        }
    }
    
    private func authenticate() {
        sendCommand("PASS oauth:\(oauthToken)")
        sendCommand("NICK \(nickname)")
        sendCommand("CAP REQ :twitch.tv/membership twitch.tv/tags twitch.tv/commands")
    }
    
    private func sendCommand(_ command: String) {
        let message = command + "\r\n"
        connection?.send(content: message.utf8Data, completion: .contentProcessed { [weak self] error in
            if let error = error {
                self?.delegate?.ircClient(self!, didDisconnect: error)
            }
        })
    }
    
    private func startPingTimer() {
        pingTimer = Timer.scheduledTimer(withTimeInterval: Constants.pingInterval, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }
    
    private func stopPingTimer() {
        pingTimer?.invalidate()
        pingTimer = nil
    }
    
    private func receiveData() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] content, _, isComplete, error in
            if let error = error {
                self?.delegate?.ircClient(self!, didDisconnect: error)
                return
            }
            
            if let data = content, let message = String(data: data, encoding: .utf8) {
                self?.handleMessage(message)
            }
            
            if !isComplete {
                self?.receiveData()
            }
        }
    }
    
    private func handleMessage(_ raw: String) {
        // Split message into lines and handle each line
        let lines = raw.components(separatedBy: "\r\n")
        for line in lines where !line.isEmpty {
            if let message = parseMessage(line) {
                delegate?.ircClient(self, didReceiveMessage: message)
            }
        }
    }
    
    private func parseMessage(_ raw: String) -> TwitchChatMessage? {
        // Basic IRC message format: [:prefix] command [params] [:trailing]
        var tags: [String: String] = [:]
        var prefix: String?
        var command: String
        var parameters: [String] = []
        var message: String?
        
        // Parse tags if present
        if raw.hasPrefix("@") {
            let tagEnd = raw.firstIndex(of: " ")!
            let tagString = String(raw[raw.index(after: raw.startIndex)..<tagEnd])
            tags = parseTags(tagString)
            let remaining = String(raw[raw.index(after: tagEnd)...])
            return parseMessage(remaining)
        }
        
        // Parse prefix if present
        if raw.hasPrefix(":") {
            let prefixEnd = raw.firstIndex(of: " ")!
            prefix = String(raw[raw.index(after: raw.startIndex)..<prefixEnd])
            let remaining = String(raw[raw.index(after: prefixEnd)...])
            return parseMessage(remaining)
        }
        
        // Parse command and parameters
        let components = raw.split(separator: " ", maxSplits: 1)
        command = String(components[0])
        
        if components.count > 1 {
            let params = components[1]
            if params.hasPrefix(":") {
                message = String(params.dropFirst())
            } else {
                parameters = params.split(separator: " ").map(String.init)
            }
        }
        
        // Extract channel from parameters
        let channel = parameters.first?.hasPrefix("#") == true ? parameters[0] : nil
        
        // Parse emotes from tags
        let emotes = parseEmotes(from: tags["emotes"])
        
        // Parse badges from tags
        let badges = parseBadges(from: tags["badges"])
        
        // Extract other metadata
        let bits = Int(tags["bits"] ?? "")
        let color = tags["color"]
        let displayName = tags["display-name"]
        let userId = tags["user-id"]
        let username = prefix?.components(separatedBy: "!").first
        
        // Check if it's an action message
        let isAction = command == "PRIVMSG" && message?.hasPrefix("\u{001}ACTION ") == true
        
        return TwitchChatMessage(
            raw: raw,
            tags: tags,
            prefix: prefix,
            command: command,
            parameters: parameters,
            channel: channel,
            message: message,
            userId: userId,
            username: username,
            displayName: displayName,
            color: color,
            isModerator: tags["mod"] == "1",
            isSubscriber: tags["subscriber"] == "1",
            isTurbo: tags["turbo"] == "1",
            isVIP: tags["vip"] == "1",
            isBroadcaster: tags["broadcaster"] == "1",
            isMe: isAction,
            emotes: emotes,
            badges: badges,
            badgeInfo: parseBadges(from: tags["badge-info"]),
            bits: bits,
            bitsLeader: Int(tags["bits-leader"] ?? ""),
            roomId: tags["room-id"],
            messageId: tags["id"],
            clientNonce: tags["client-nonce"],
            customRewardId: tags["custom-reward-id"],
            isHighlighted: tags["highlighted"] == "1",
            isFirstMessage: tags["first-msg"] == "1",
            isReturningChatter: tags["returning-chatter"] == "1",
            isEmoteOnly: tags["emote-only"] == "1",
            isSlowMode: tags["slow"] == "1",
            isFollowersOnly: tags["followers-only"] == "1",
            isSubscribersOnly: tags["subscribers-only"] == "1",
            isR9K: tags["r9k"] == "1",
            isEmoteOnlyMode: tags["emote-only-mode"] == "1",
            channelFollowers: Int(tags["followers"] ?? ""),
            channelSubscribers: Int(tags["subscribers"] ?? ""),
            channelViewers: Int(tags["viewers"] ?? ""),
            channelHost: tags["host"],
            channelHostViewers: Int(tags["host-viewers"] ?? ""),
            timestamp: tags["tmi-sent-ts"].flatMap { Double($0) }.map { Date(timeIntervalSince1970: $0 / 1000) },
            sentTimestamp: tags["sent-ts"].flatMap { Double($0) }.map { Date(timeIntervalSince1970: $0 / 1000) }
        )
    }
    
    private func parseTags(_ tagString: String) -> [String: String] {
        var tags: [String: String] = [:]
        let components = tagString.split(separator: ";")
        
        for component in components {
            let parts = component.split(separator: "=", maxSplits: 1)
            if parts.count == 2 {
                tags[String(parts[0])] = String(parts[1])
            }
        }
        
        return tags
    }
    
    private func parseEmotes(from tag: String?) -> [TwitchEmote] {
        guard let tag = tag else { return [] }
        var emotes: [TwitchEmote] = []
        
        let components = tag.split(separator: "/")
        for component in components {
            let parts = component.split(separator: ":")
            guard parts.count >= 2,
                  let id = parts.first,
                  let ranges = parts[1].split(separator: ",").first?.split(separator: "-"),
                  ranges.count == 2,
                  let start = Int(ranges[0]),
                  let end = Int(ranges[1]) else {
                continue
            }
            
            // Convert ClosedRange to Range by excluding the end
            let range = start..<end + 1
            let url = URL(string: "https://static-cdn.jtvnw.net/emoticons/v2/\(id)/default/dark/3.0")!
            
            emotes.append(TwitchEmote(id: String(id), name: "", range: range, url: url))
        }
        
        return emotes
    }
    
    private func parseBadges(from tag: String?) -> [TwitchBadge] {
        guard let tag = tag else { return [] }
        var badges: [TwitchBadge] = []
        
        let components = tag.split(separator: ",")
        for component in components {
            let parts = component.split(separator: "/")
            guard parts.count == 2 else { continue }
            
            let name = String(parts[0])
            let version = String(parts[1])
            let url = URL(string: "https://static-cdn.jtvnw.net/badges/v1/\(name)/\(version)/3")
            
            badges.append(TwitchBadge(name: name, version: version, url: url))
        }
        
        return badges
    }
} 