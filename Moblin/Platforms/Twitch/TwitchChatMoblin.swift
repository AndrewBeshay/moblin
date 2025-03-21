import Network
import SwiftUI

// MARK: - Structures

//struct ChatMessageEmote {
//    let url: URL
//    let range: Range<Int>
//}

struct TwitchBadge {
    let id: String
    let version: String
    let imageUrl: String
}

struct TwitchCheermoteTier {
    let minBits: Int
    let imageUrl: String
}

struct TwitchCheermote {
    let prefix: String
    let tiers: [TwitchCheermoteTier]
}

// MARK: - Badges Manager

private class Badges {
    private var channelId: String = ""
    private var accessToken: String = ""
    private var urlSession = URLSession.shared
    private var badges: [String: TwitchBadge] = [:]
    private var tryFetchAgainTimer = SimpleTimer(queue: .main)

    func start(channelId: String, accessToken: String, urlSession: URLSession) {
        self.channelId = channelId
        self.accessToken = accessToken
        self.urlSession = urlSession
        guard !accessToken.isEmpty else {
            return
        }
        tryFetch()
    }

    func stop() {
        stopTryFetchAgainTimer()
    }

    func getUrl(badgeId: String) -> String? {
        return badges[badgeId]?.imageUrl
    }

    func tryFetch() {
        startTryFetchAgainTimer()
        TwitchApi(accessToken, urlSession).getGlobalChatBadges { data in
            guard let data else {
                return
            }
            DispatchQueue.main.async {
                self.addBadges(badges: data)
                TwitchApi(self.accessToken, self.urlSession)
                    .getChannelChatBadges(broadcasterId: self.channelId) { data in
                        guard let data else {
                            return
                        }
                        DispatchQueue.main.async {
                            self.addBadges(badges: data)
                            self.stopTryFetchAgainTimer()
                        }
                    }
            }
        }
    }

    private func startTryFetchAgainTimer() {
        tryFetchAgainTimer.startSingleShot(timeout: 30) { [weak self] in
            self?.tryFetch()
        }
    }

    private func stopTryFetchAgainTimer() {
        tryFetchAgainTimer.stop()
    }

    private func addBadges(badges: [TwitchApiChatBadgesData]) {
        for badge in badges {
            for version in badge.versions {
                self.badges["\(badge.set_id)/\(version.id)"] = TwitchBadge(
                    id: badge.set_id,
                    version: version.id,
                    imageUrl: version.image_url_2x
                )
            }
        }
    }
}

// MARK: - Cheermotes Manager

private class Cheermotes {
    private var channelId: String = ""
    private var accessToken: String = ""
    private var urlSession: URLSession = .shared
    private var emotes: [String: [TwitchCheermoteTier]] = [:]
    private var tryFetchAgainTimer = SimpleTimer(queue: .main)

    func start(channelId: String, accessToken: String, urlSession: URLSession) {
        self.channelId = channelId
        self.accessToken = accessToken
        self.urlSession = urlSession
        guard !accessToken.isEmpty else {
            return
        }
        tryFetch()
    }

    func stop() {
        stopTryFetchAgainTimer()
    }

    func tryFetch() {
        startTryFetchAgainTimer()
        TwitchApi(accessToken, urlSession).getCheermotes(broadcasterId: channelId) { datas in
            guard let datas else {
                return
            }
            DispatchQueue.main.async {
                for data in datas {
                    self.emotes[data.prefix.lowercased()] = data.tiers.map { tier in
                        TwitchCheermoteTier(
                            minBits: tier.min_bits,
                            imageUrl: tier.images.dark.static_.two
                        )
                    }
                }
                self.stopTryFetchAgainTimer()
            }
        }
    }

    private func startTryFetchAgainTimer() {
        tryFetchAgainTimer.startSingleShot(timeout: 30) { [weak self] in
            self?.tryFetch()
        }
    }

    private func stopTryFetchAgainTimer() {
        tryFetchAgainTimer.stop()
    }

    func getUrlAndBits(word: String) -> (URL, Int)? {
        let word = word.lowercased().trim()
        for (prefix, tiers) in emotes {
            guard let regex = try? Regex("\(prefix)(\\d+)", as: (Substring, Substring).self) else {
                continue
            }
            guard let match = try? regex.wholeMatch(in: word) else {
                continue
            }
            guard let bits = Int(match.output.1) else {
                continue
            }
            guard let tier = tiers.reversed().first(where: { bits >= $0.minBits }) else {
                continue
            }
            guard let url = URL(string: tier.imageUrl) else {
                continue
            }
            return (url, bits)
        }
        return nil
    }
}

// MARK: - IRC Message Parser

private struct IRCMessage {
    let tags: [String: String]
    let prefix: String?
    let command: String
    let parameters: [String]
    
    init?(raw: String) {
        logger.info("twitch: chat: Raw IRC message: '\(raw)'")
        var message = raw
        var tags: [String: String] = [:]
        var prefix: String?
        
        // Parse tags if present
        if message.hasPrefix("@") {
            let tagEnd = message.firstIndex(of: " ")!
            let tagString = String(message[..<tagEnd])
            message = String(message[message.index(after: tagEnd)...])
            
            logger.info("twitch: chat: Raw tags string: '\(tagString)'")
            for tag in tagString.dropFirst().split(separator: ";") {
                let parts = tag.split(separator: "=", maxSplits: 1)
                if parts.count == 2 {
                    tags[String(parts[0])] = String(parts[1])
                } else {
                    tags[String(parts[0])] = ""
                }
            }
            logger.info("twitch: chat: Parsed tags: \(tags)")
        }
        
        // Parse prefix if present
        if message.hasPrefix(":") {
            let prefixEnd = message.firstIndex(of: " ")!
            prefix = String(message[..<prefixEnd].dropFirst()) // Convert dropFirst() result to String
            message = String(message[message.index(after: prefixEnd)...])
            logger.info("twitch: chat: Prefix: '\(prefix ?? "")'")
        }
        
        // Parse command and parameters
        let parts = message.split(separator: " ", maxSplits: 1)
        let command = String(parts[0])
        var parameters: [String] = []
        
        if parts.count > 1 {
            let paramString = String(parts[1])
            if paramString.hasPrefix(":") {
                // If the parameter starts with a colon, it's the entire message
                parameters = [String(paramString.dropFirst())]
            } else {
                // Otherwise, split by spaces
                parameters = paramString.split(separator: " ").map(String.init)
            }
        }
        
        logger.info("""
            twitch: chat: Parsed message:
            - Command: '\(command)'
            - Parameters: \(parameters)
            """)
        
        self.tags = tags
        self.prefix = prefix
        self.command = command
        self.parameters = parameters
    }
}

// MARK: - Chat Message Parser

private struct ChatMessage {
    let sender: String?
    let userId: String?
    let senderColor: String?
    let badges: [String]
    let emotes: [ChatMessageEmote]
    let text: String
    let bits: String?
    let subscriber: Bool
    let moderator: Bool
    let announcement: Bool
    let firstMessage: Bool
    
    init?(ircMessage: IRCMessage) {
        guard ircMessage.command == "PRIVMSG" else {
            return nil
        }
        
        self.sender = ircMessage.prefix?.split(separator: "!").first.map(String.init)
        self.userId = ircMessage.tags["user-id"]
        self.senderColor = ircMessage.tags["color"]
        self.badges = ircMessage.tags["badges"]?.split(separator: ",").map(String.init) ?? []
        self.bits = ircMessage.tags["bits"]
        self.subscriber = ircMessage.tags["subscriber"] == "1"
        self.moderator = ircMessage.tags["mod"] == "1"
        self.announcement = ircMessage.tags["msg-id"] == "announcement"
        self.firstMessage = ircMessage.tags["first-msg"] == "1"
        
        // Parse emotes
        var emotes: [ChatMessageEmote] = []
        if let emotesString = ircMessage.tags["emotes"] {
            logger.info("twitch: chat: Raw emotes string: '\(emotesString)'")
            for emote in emotesString.split(separator: "/") {
                let parts = emote.split(separator: ":")
                guard parts.count >= 2,
                      let emoteId = parts.first,
                      let ranges = parts[1].split(separator: ",").first?.split(separator: "-"),
                      let start = Int(ranges[0]),
                      let end = Int(ranges[1]) else {
                    logger.warning("""
                        twitch: chat: Failed to parse emote:
                        - Emote string: '\(emote)'
                        - Parts: \(parts)
                        - Ranges: \(parts[1].split(separator: ",").first?.split(separator: "-") ?? [])
                        """)
                    continue
                }
                let url = URL(string: "https://static-cdn.jtvnw.net/emoticons/v2/\(emoteId)/default/dark/2.0")!
                logger.info("""
                    twitch: chat: Parsed emote:
                    - ID: \(emoteId)
                    - Range: \(start)...\(end)
                    - URL: \(url)
                    """)
                emotes.append(ChatMessageEmote(url: url, range: start...end))
            }
        } else {
            logger.info("twitch: chat: No emotes tag found in message")
        }
        self.emotes = emotes
        
        // Parse text - handle the parameters properly
        let params = ircMessage.parameters.dropFirst() // Drop the channel name
        var text: String
        if let firstParam = params.first {
            if firstParam.hasPrefix(":") {
                // If the first parameter starts with a colon, it's the entire message
                text = String(firstParam.dropFirst()) // Remove the leading colon
                // Join any remaining parameters with spaces
                if params.count > 1 {
                    text += " " + params.dropFirst().joined(separator: " ")
                }
            } else {
                // Otherwise, join all parameters with spaces
                text = params.joined(separator: " ")
            }
        } else {
            text = ""
        }
        
        self.text = text
        logger.info("twitch: chat: Message text: '\(text)'")
    }
    
    func isAction() -> Bool {
        return text.starts(with: "\u{01}ACTION")
    }
}

// MARK: - TwitchChatMoblin

protocol TwitchChatMoblinDelegate: AnyObject {
    func twitchChatMoblinMakeErrorToast(title: String, subTitle: String?)
    func twitchChatMoblinAppendMessage(
        user: String?,
        userId: String?,
        userColor: RgbColor?,
        userBadges: [URL],
        segments: [ChatPostSegment],
        isAction: Bool,
        isSubscriber: Bool,
        isModerator: Bool,
        bits: String?,
        highlight: ChatHighlight?
    )
}

final class TwitchChatMoblin {
    private var webSocket: WebSocketClient
    private var emotes: Emotes
    private var badges: Badges
    private var cheermotes: Cheermotes
    private var channelName: String
    private weak var delegate: (any TwitchChatMoblinDelegate)?

    init(delegate: TwitchChatMoblinDelegate) {
        self.delegate = delegate
        channelName = ""
        emotes = Emotes()
        badges = Badges()
        cheermotes = Cheermotes()
        webSocket = .init(url: URL(string: "wss://irc-ws.chat.twitch.tv")!)
    }

    func start(
        channelName: String,
        channelId: String,
        settings: SettingsStreamChat,
        accessToken: String,
        httpProxy: HttpProxy?,
        urlSession: URLSession
    ) {
        self.channelName = channelName
        logger.debug("twitch: chat: Start")
        stopInternal()
        emotes.start(
            platform: .twitch,
            channelId: channelId,
            onError: handleError,
            onOk: handleOk,
            settings: settings
        )
        badges.start(channelId: channelId, accessToken: accessToken, urlSession: urlSession)
        cheermotes.start(channelId: channelId, accessToken: accessToken, urlSession: urlSession)
        webSocket = .init(url: URL(string: "wss://irc-ws.chat.twitch.tv")!, httpProxy: httpProxy)
        webSocket.delegate = self
        webSocket.start()
    }

    func stop() {
        logger.debug("twitch: chat: Stop")
        stopInternal()
    }

    func stopInternal() {
        emotes.stop()
        badges.stop()
        cheermotes.stop()
        webSocket.stop()
    }

    private func handleMessage(message: String) throws {
        guard let ircMessage = IRCMessage(raw: message) else {
            return
        }
        
        if ircMessage.command == "PING" {
            webSocket.send(string: "PONG \(ircMessage.parameters.joined(separator: " "))")
        } else if let chatMessage = ChatMessage(ircMessage: ircMessage) {
            try handleChatMessage(message: chatMessage)
        }
    }

    private func handleChatMessage(message: ChatMessage) throws {
        var badgeUrls: [URL] = []
        for badge in message.badges {
            if let badgeUrl = badges.getUrl(badgeId: badge), let badgeUrl = URL(string: badgeUrl) {
                badgeUrls.append(badgeUrl)
            }
        }
        
        let text: String
        let isAction = message.isAction()
        if isAction {
            text = String(message.text.dropFirst(7))
        } else {
            text = message.text
        }
        
        let segments = createSegments(
            text: text,
            emotes: message.emotes,
            emotesManager: self.emotes,
            bits: message.bits
        )
        
        delegate?.twitchChatMoblinAppendMessage(
            user: message.sender,
            userId: message.userId,
            userColor: RgbColor.fromHex(string: message.senderColor ?? ""),
            userBadges: badgeUrls,
            segments: segments,
            isAction: isAction,
            isSubscriber: message.subscriber,
            isModerator: message.moderator,
            bits: message.bits,
            highlight: createHighlight(message: message)
        )
    }

    func createSegmentsNoTwitchEmotes(text: String, bits: String?) -> [ChatPostSegment] {
        return createSegments(text: text, emotes: [], emotesManager: emotes, bits: bits)
    }

    private func createHighlight(message: ChatMessage) -> ChatHighlight? {
        if message.announcement {
            return .init(
                kind: .other,
                color: .green,
                image: "horn.blast",
                title: String(localized: "Announcement")
            )
        } else if message.firstMessage {
            return .init(
                kind: .firstMessage,
                color: .yellow,
                image: "bubble.left",
                title: String(localized: "First time chatter")
            )
        } else {
            return nil
        }
    }

    func isConnected() -> Bool {
        return webSocket.isConnected()
    }

    func hasEmotes() -> Bool {
        return emotes.isReady()
    }

    private func handleError(title: String, subTitle: String) {
        DispatchQueue.main.async {
            self.delegate?.twitchChatMoblinMakeErrorToast(title: title, subTitle: subTitle)
        }
    }

    private func handleOk(title: String) {
        DispatchQueue.main.async {
            self.delegate?.twitchChatMoblinMakeErrorToast(title: title, subTitle: nil)
        }
    }

    private func createSegments(text: String,
                              emotes: [ChatMessageEmote],
                              emotesManager: Emotes,
                              bits: String?) -> [ChatPostSegment]
    {
        var segments: [ChatPostSegment] = []
        var id = 0
        
        // Process Twitch emotes first
        let twitchSegments = createTwitchSegments(text: text, emotes: emotes, id: &id)
        
        // If no Twitch emotes were found, try 7TV emotes
        if emotes.isEmpty {
            logger.info("twitch: chat: No Twitch emotes found, checking for 7TV emotes")
            segments = emotesManager.createSegments(text: text, id: &id)
        } else {
            // Process Twitch emotes
            for var segment in twitchSegments {
                if let text = segment.text {
                    segments += makeChatPostTextSegments(text: text, id: &id)
                    segment.text = nil
                }
                if segment.text != nil || segment.url != nil {
                    segments.append(segment)
                }
            }
        }
        
        if bits != nil {
            segments = replaceCheermotes(segments: segments)
        }
        
        return segments
    }

    private func createTwitchSegments(text: String,
                                    emotes: [ChatMessageEmote],
                                    id: inout Int) -> [ChatPostSegment]
    {
        var segments: [ChatPostSegment] = []
        let unicodeText = text.unicodeScalars
        var startIndex = unicodeText.startIndex
        
        logger.info("twitch: chat: Processing text: '\(text)'")
        logger.info("twitch: chat: Number of emotes: \(emotes.count)")
        
        // Sort emotes by start position to process them in order
        let sortedEmotes = emotes.sorted { $0.range.lowerBound < $1.range.lowerBound }
        
        for (index, emote) in sortedEmotes.enumerated() {
            // Find the complete emote text by looking for the next space or end of string
            let emoteStart = unicodeText.index(unicodeText.startIndex, offsetBy: emote.range.lowerBound)
            let emoteEnd = unicodeText.index(unicodeText.startIndex, offsetBy: emote.range.upperBound)
            
            // Look for the next space or end of string
            let nextSpace = unicodeText[emoteEnd...].firstIndex(of: " ") ?? unicodeText.endIndex
            let completeEmoteRange = emoteStart..<nextSpace
            
            let emoteText = String(unicodeText[completeEmoteRange])
            logger.info("""
                twitch: chat: Processing emote \(index + 1)/\(emotes.count):
                - Original Range: \(emote.range)
                - Complete Range: \(completeEmoteRange)
                - URL: \(emote.url)
                - Text at range: '\(emoteText)'
                """)
            
            // Skip invalid ranges
            if emote.range.lowerBound >= unicodeText.count {
                logger.warning(
                    """
                    twitch: chat: Emote lower bound \(emote.range.lowerBound) after \
                    message end \(unicodeText.count) '\(unicodeText)'
                    """
                )
                continue
            }
            
            // Add text before the emote
            if emote.range.lowerBound > 0 {
                let endIndex = unicodeText.index(
                    unicodeText.startIndex,
                    offsetBy: emote.range.lowerBound
                )
                if startIndex < endIndex {
                    let textBefore = String(unicodeText[startIndex..<endIndex])
                    logger.debug("twitch: chat: Adding text before emote: '\(textBefore)'")
                    segments += makeChatPostTextSegments(text: textBefore, id: &id)
                }
            }
            
            // Add the emote
            logger.debug("twitch: chat: Adding emote segment")
            segments.append(ChatPostSegment(id: id, url: emote.url))
            id += 1
            
            // Add a space after the emote
            logger.debug("twitch: chat: Adding space after emote")
            segments.append(ChatPostSegment(id: id, text: " "))
            id += 1
            
            // Update start index to after the complete emote
            startIndex = nextSpace
            logger.debug("twitch: chat: Updated start index to: \(startIndex)")
        }
        
        // Add remaining text after the last emote
        if startIndex < unicodeText.endIndex {
            let remainingText = String(unicodeText[startIndex...])
            logger.debug("twitch: chat: Adding remaining text: '\(remainingText)'")
            segments += makeChatPostTextSegments(text: remainingText, id: &id)
        }
        
        // Log final segments
        logger.debug("twitch: chat: Final segments:")
        for (index, segment) in segments.enumerated() {
            logger.debug("""
                twitch: chat: Segment \(index + 1):
                - ID: \(segment.id)
                - Text: '\(segment.text ?? "")'
                - URL: \(segment.url?.absoluteString ?? "nil")
                """)
        }
        
        return segments
    }

    private func replaceCheermotes(segments: [ChatPostSegment]) -> [ChatPostSegment] {
        var newSegments: [ChatPostSegment] = []
        guard var id = segments.last?.id else {
            return newSegments
        }
        
        for segment in segments {
            guard let text = segment.text else {
                newSegments.append(segment)
                continue
            }
            guard let (url, bits) = cheermotes.getUrlAndBits(word: text) else {
                newSegments.append(segment)
                continue
            }
            id += 1
            newSegments.append(.init(id: id, url: url))
            id += 1
            newSegments.append(.init(id: id, text: "\(bits) "))
        }
        
        return newSegments
    }
}

// MARK: - WebSocket Delegate

extension TwitchChatMoblin: WebSocketClientDelegate {
    func webSocketClientConnected(_ webSocket: WebSocketClient) {
        logger.debug("twitch: chat: Connected")
        webSocket.send(string: "CAP REQ :twitch.tv/membership")
        webSocket.send(string: "CAP REQ :twitch.tv/tags")
        webSocket.send(string: "CAP REQ :twitch.tv/commands")
        webSocket.send(string: "PASS oauth:SCHMOOPIIE")
        webSocket.send(string: "NICK justinfan67420")
        webSocket.send(string: "JOIN #\(channelName)")
    }

    func webSocketClientDisconnected(_: WebSocketClient) {
        logger.debug("twitch: chat: Disconnected")
    }

    func webSocketClientReceiveMessage(_: WebSocketClient, string: String) {
        for line in string.split(whereSeparator: { $0.isNewline }) {
            try? handleMessage(message: String(line))
        }
    }
}
