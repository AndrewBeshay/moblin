import Network
import SwiftUI

private var sharedChatActive: Bool = false
private var userProfileImages: [String: String] = [:] // Cache profile images

private func getEmotes(from message: ChatMessage) -> [ChatMessageEmote] {
    var emotes: [ChatMessageEmote] = []
    for emote in message.emotes {
        do {
            try emotes.append(ChatMessageEmote(url: emote.imageURL(), range: emote.range))
        } catch {
            logger.warning("⚠️ Failed to get emote URL for \(emote.range)")
        }
    }
    return emotes
}

private class Badges {
    private var channelId: String = ""
    private var accessToken: String = ""
    private var urlSession = URLSession.shared
    private var badges: [String: TwitchApiChatBadge] = [:]
    private var tryFetchAgainTimer = SimpleTimer(queue: .main)

    func start(channelId: String, accessToken: String, urlSession: URLSession) {
        self.channelId = channelId
        self.accessToken = accessToken
        self.urlSession = urlSession
        guard !accessToken.isEmpty else {
            logger.error("❌ Access token is empty, cannot fetch badges")
            return
        }
        logger.info("📡 Fetching Twitch badges for channel \(channelId)...")
        tryFetch()
    }

    func stop() {
        stopTryFetchAgainTimer()
    }

    func getUrl(badgeId: String) -> String? {
        return badges[badgeId]?.image_url_2x
    }

    func tryFetch() {
        startTryFetchAgainTimer()
        TwitchAPI.shared.chat.getGlobalChatBadges { data in
            logger.info("idk \(String(describing: data?.count))")
            guard let data else {
                logger.error("❌ Failed to fetch global chat badges")
                return
            }
            DispatchQueue.main.async {
                self.addBadges(badges: data)
                TwitchAPI.shared.chat.getChannelChatBadges(broadcasterId: self.channelId) { data in
                        guard let data else {
                            logger.error("❌ Failed to fetch channel-specific chat badges")
                            return
                        }
                        DispatchQueue.main.async {
                            self.addBadges(badges: data)
                            self.stopTryFetchAgainTimer()
                            logger.info("✅ Successfully fetched all badges")
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

    private func addBadges(badges: [TwitchApiChatBadgeSet]) {
        for badge in badges {
            for version in badge.versions {
                self.badges["\(badge.set_id)/\(version.id)"] = version
            }
        }
    }
}

private class Cheermotes {
    private var channelId: String = ""
    private var accessToken: String = ""
    private var urlSession: URLSession = .shared
    private var emotes: [String: [TwitchApiCheermoteTier]] = [:]
    private var tryFetchAgainTimer = SimpleTimer(queue: .main)

    func start(channelId: String, accessToken: String, urlSession: URLSession) {
        self.channelId = channelId
        self.accessToken = accessToken
        self.urlSession = urlSession
        guard !accessToken.isEmpty else {
            logger.error("❌ Access token is empty, cannot fetch cheermotes.")
            return
        }
        logger.info("📡 Starting to fetch Twitch cheermotes for channel: \(channelId)")
        tryFetch()
    }

    func stop() {
        logger.info("🛑 Stopping Cheermote fetch attempts.")
        stopTryFetchAgainTimer()
    }

    func tryFetch() {
        logger.info("🔄 Attempting to fetch Cheermotes... )")

        startTryFetchAgainTimer()
        logger.info("Calling get cheermotes again?")
        TwitchAPI.shared.bits.getCheermotes(broadcasterId: channelId) { datas, responses  in
            if let datas = datas {
                DispatchQueue.main.async {
                    logger.info("✅ Successfully fetched \(datas.count) Cheermotes.")
                    for data in datas {
                        self.emotes[data.prefix.lowercased()] = data.tiers
                        logger.debug("📌 Added Cheermote: \(data.prefix) with \(data.tiers.count) tiers")
                    }
                    self.stopTryFetchAgainTimer()
                }
            } else {
                logger.warning("⚠️ Failed to fetch Cheermotes. Retrying in 30 seconds...")
            }
        }
    }

    private func startTryFetchAgainTimer() {
        logger.info("⏳ Scheduling next Cheermote fetch attempt in 30 seconds...")
        tryFetchAgainTimer.startSingleShot(timeout: 30) { [weak self] in
            self?.tryFetch()
        }
    }

    private func stopTryFetchAgainTimer() {
        logger.info("🛑 Stopping Cheermote retry timer.")
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
            guard let tier = tiers.reversed().first(where: { bits >= $0.min_bits }) else {
                continue
            }
            guard let url = URL(string: tier.images.dark.staticImages?.url_2x ?? "") else {
                continue
            }
            return (url, bits)
        }
        return nil
    }
}

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
        highlight: ChatHighlight?,
        messageId: String?,
        sourceRoomId: String?
    )
    // ✅ New Delegate Method to Notify Shared Chat State
    func twitchChatMoblinUpdateSharedChatStatus(isActive: Bool)
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
        logger.info("📡 Connecting to Twitch chat: \(channelName) (ID: \(channelId))")
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
        let message = try Message(string: message)
        logger.debug("\(message)")
        if let chatMessage = ChatMessage(message) {
            try handleChatMessage(message: chatMessage)
        } else if message.command == .ping {
            webSocket.send(string: "PONG \(message.parameters.joined(separator: " "))")
        } else if message.command == .notice {
            handleSharedChatNotice(message: message)
        }
    }

    private func handleSharedChatNotice(message: Message) {
        guard let msgId = message.tags["msg-id"] else {
            logger.warning("⚠️ Received notice without msg-id")
            return
        }

        if msgId == "shared_chat_begin" {
            logger.info("🔵 Shared Chat Activated")
            sharedChatActive = true
            delegate?.twitchChatMoblinUpdateSharedChatStatus(isActive: true)
        } else if msgId == "shared_chat_end" {
            logger.info("🔴 Shared Chat Deactivated")
            sharedChatActive = false
            delegate?.twitchChatMoblinUpdateSharedChatStatus(isActive: false)
        }
    }

    private func handleChatMessage(message: ChatMessage) throws {
        logger.info(message.description)
        let emotes = getEmotes(from: message)
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

        // ✅ Check if `message.sourceRoomId` is not nil and update `sharedChatActive`
        if let sourceRoomId = message.sourceRoomId {
            if !sharedChatActive {
                logger.info("🔵 Detected Source Room ID: \(sourceRoomId). Enabling Shared Chat.")
                sharedChatActive = true
                delegate?.twitchChatMoblinUpdateSharedChatStatus(isActive: true)
            }
        } else if sharedChatActive {
            logger.info("🔴 No Source Room ID detected. Disabling Shared Chat.")
            sharedChatActive = false
            delegate?.twitchChatMoblinUpdateSharedChatStatus(isActive: false)
        }

        logger.info("🔎 Message Source Room ID: \(message.sourceRoomId ?? "None")")
        
        let segments = createSegments(
            text: text,
            emotes: emotes,
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
            highlight: createHighlight(message: message),
            messageId: message.uniqueId,
            sourceRoomId: message.sourceRoomId
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

    private func createTwitchSegments(text: String,
                                      emotes: [ChatMessageEmote],
                                      id: inout Int) -> [ChatPostSegment]
    {
        var segments: [ChatPostSegment] = []
        let unicodeText = text.unicodeScalars
        var startIndex = unicodeText.startIndex
        for emote in emotes.sorted(by: { lhs, rhs in
            lhs.range.lowerBound < rhs.range.lowerBound
        }) {
            if !(emote.range.lowerBound < unicodeText.count) {
                logger
                    .warning(
                        """
                        twitch: chat: Emote lower bound \(emote.range.lowerBound) after \
                        message end \(unicodeText.count) '\(unicodeText)'
                        """
                    )
                break
            }
            if !(emote.range.upperBound < unicodeText.count) {
                logger
                    .warning(
                        """
                        twitch: chat: Emote upper bound \(emote.range.upperBound) after \
                        message end \(unicodeText.count) '\(unicodeText)'
                        """
                    )
                break
            }
            var text: String?
            if emote.range.lowerBound > 0 {
                let endIndex = unicodeText.index(
                    unicodeText.startIndex,
                    offsetBy: emote.range.lowerBound - 1
                )
                if startIndex < endIndex {
                    text = String(unicodeText[startIndex ... endIndex])
                }
            }
            if let text {
                segments += makeChatPostTextSegments(text: text, id: &id)
            }
            segments.append(ChatPostSegment(id: id, url: emote.url))
            id += 1
            segments.append(ChatPostSegment(id: id, text: ""))
            id += 1
            startIndex = unicodeText.index(
                unicodeText.startIndex,
                offsetBy: emote.range.upperBound + 1
            )
        }
        if startIndex < unicodeText.endIndex {
            for word in String(unicodeText[startIndex...]).split(separator: " ") {
                segments.append(ChatPostSegment(id: id, text: "\(word) "))
                id += 1
            }
        }
        return segments
    }

    private func createSegments(text: String,
                                emotes: [ChatMessageEmote],
                                emotesManager: Emotes,
                                bits: String?) -> [ChatPostSegment]
    {
        var segments: [ChatPostSegment] = []
        var id = 0
        for var segment in createTwitchSegments(text: text, emotes: emotes, id: &id) {
            if let text = segment.text {
                segments += emotesManager.createSegments(text: text, id: &id)
                segment.text = nil
            }
            if segment.text != nil || segment.url != nil {
                segments.append(segment)
            }
        }
        if bits != nil {
            segments = replaceCheermotes(segments: segments)
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

extension ChatMessage {
    func isAction() -> Bool {
        return text.starts(with: "\u{01}ACTION")
    }
}

extension TwitchChatMoblin: WebSocketClientDelegate {
    func webSocketClientConnected(_ webSocket: WebSocketClient) {
        logger.info("✅ Connected to Twitch WebSocket")
        webSocket.send(string: "CAP REQ :twitch.tv/membership")
        webSocket.send(string: "CAP REQ :twitch.tv/tags")
        webSocket.send(string: "CAP REQ :twitch.tv/commands")
        webSocket.send(string: "PASS oauth:SCHMOOPIIE")
        webSocket.send(string: "NICK justinfan67420")
        webSocket.send(string: "JOIN #\(channelName)")
    }

    func webSocketClientDisconnected(_: WebSocketClient) {
        logger.warning("❌ Disconnected from Twitch WebSocket")
    }

    func webSocketClientReceiveMessage(_: WebSocketClient, string: String) {
//        logger.info("📩 WebSocket Received: \(string)")
        for line in string.split(whereSeparator: { $0.isNewline }) {
            try? handleMessage(message: String(line))
        }
    }
}
