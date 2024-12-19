import Network
import SwiftUI

private func getEmotes(from message: ChatMessage) -> [ChatMessageEmote] {
    var emotes: [ChatMessageEmote] = []
    for emote in message.emotes {
        do {
            try emotes.append(ChatMessageEmote(url: emote.imageURL, range: emote.range))
        } catch {
            logger.warning("twitch: chat: Failed to get emote URL")
        }
    }
    return emotes
}

private class Badges {
    private var channelId: String = ""
    private var accessToken: String = ""
    private var urlSession = URLSession.shared
    private var badges: [String: TwitchApiChatBadgesVersion] = [:]
    private var tryFetchAgainTimer: DispatchSourceTimer?

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
        return badges[badgeId]?.image_url_2x
    }

    func tryFetch() {
        startTryFetchAgainTimer()
        let twitchApi = TwitchApi(self.accessToken, self.urlSession) // Include URLSession.shared
        twitchApi.getGlobalChatBadges { data in
            guard let data else {
                return
            }
            DispatchQueue.main.async {
                self.addBadges(badges: data)
                twitchApi
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
        tryFetchAgainTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        tryFetchAgainTimer!.schedule(deadline: .now() + 30)
        tryFetchAgainTimer!.setEventHandler { [weak self] in
            self?.tryFetch()
        }
        tryFetchAgainTimer!.activate()
    }

    private func stopTryFetchAgainTimer() {
        tryFetchAgainTimer?.cancel()
        tryFetchAgainTimer = nil
    }

    private func addBadges(badges: [TwitchApiChatBadgesData]) {
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
    private var emotes: [String: [TwitchApiGetCheermotesDataTier]] = [:]
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
                    self.emotes[data.prefix.lowercased()] = data.tiers
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
            guard let tier = tiers.reversed().first(where: { bits >= $0.min_bits }) else {
                continue
            }
            guard let url = URL(string: tier.images.dark.static_.two) else {
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
        platformId: String?,
        userColor: RgbColor?,
        userBadges: [URL],
        segments: [ChatPostSegment],
        isAction: Bool,
        isSubscriber: Bool,
        isModerator: Bool,
        bits: String?,
        highlight: ChatHighlight?,
        isDeleted: Bool
    )
    
    func twitchChatMoblinUpdateMessage(with username: String)
    func twitchChatMoblinRemoveMessage(at index: Int)
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
        // Extract the messageId
        let messageId = extractMessageId(from: message)
        
        guard let message = try ChatMessage(TwitchMessage(string: message)) else {
            return
        }
        
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
        let segments = createSegments(
            text: text,
            emotes: emotes,
            emotesManager: self.emotes,
            bits: message.bits
        )
        delegate?.twitchChatMoblinAppendMessage(
            user: message.loginName,
            userId: message.displayName,
            platformId: messageId,
            userColor: RgbColor.fromHex(string: message.senderColor ?? ""),
            userBadges: badgeUrls,
            segments: segments,
            isAction: isAction,
            isSubscriber: message.subscriber,
            isModerator: message.moderator,
            bits: message.bits,
            highlight: createHighlight(message: message),
            isDeleted: false
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

    private func handleClearMessage(message: String) {
        // Parse the CLEARMSG command
        let components = message.split(separator: ";")
        var messageId: String? = nil
        var deletionReason: String? = nil

        for component in components {
            if component.starts(with: "target-msg-id=") {
                messageId = component.replacingOccurrences(of: "target-msg-id=", with: "")
            }
            if component.starts(with: "ban-reason=") {
                deletionReason = component.replacingOccurrences(of: "ban-reason=", with: "")
            }
        }

        guard let messageId else {
            logger.warning("twitch: chat: Missing message ID in CLEARMSG")
            return
        }

        // Remove or mark the deleted message in the model
        DispatchQueue.main.async {
            self.delegate?.twitchChatMoblinRemoveMessage(at: Int(messageId) ?? 0)
//            if let index = self.delegate?.firstIndex(where: { $0.platformId == messageId }) {
//                // self.model.chatPosts.remove(at: index)
//                // Alternatively, you could mark the message as deleted:
//                //                self.model.chatPosts[index].message = "[Deleted by Moderator]"
//                self.model.chatPosts[index].isDeleted = true
//            }
        }

        // Optionally, log the deletion reason
        if let reason = deletionReason {
            logger.info("twitch: chat: Message \(messageId) deleted for reason: \(reason)")
        }
    }

    private func handleClearChat(message: String) {
        // Parse message to get the username or user-id of the banned/timed-out user
        logger.debug("Handling clear chat")
        let components = message.split(separator: ";")
        guard let username = components.first(where: { $0.hasPrefix("target-user-id=") })?.replacingOccurrences(of: "target-user-id=", with: "") else {
            return
        }
//        let banReason = tags["ban-reason"]?.removingPercentEncoding ?? "No reason provided"
//        let duration = tags["ban-duration"] // Present if it's a timeout

        logger.debug(username)
        
        // Remove or mark the deleted message in the model
        DispatchQueue.main.async {
            
            self.delegate?.twitchChatMoblinUpdateMessage(with: username)
            
//            for index in self.model.chatPosts.indices {
//                if self.model.chatPosts[index].userId == username {
//                    self.model.chatPosts[index].isDeleted = true
//                }
//            }
        }
        
//        // Extract the metadata (tags) from the message
//       let tagsSection = message.split(separator: " ").first(where: { $0.hasPrefix("@") })
//       guard let tags = tagsSection else {
//           logger.warning("No tags found in CLEARCHAT message")
//           return
//       }
//
//       // Parse the tags into a dictionary
//       let tagsDictionary = tags.dropFirst().split(separator: ";").reduce(into: [String: String]()) { dict, tag in
//           let parts = tag.split(separator: "=", maxSplits: 1).map(String.init)
//           if parts.count == 2 {
//               dict[parts[0]] = parts[1]
//           }
//       }
//
//       // Extract relevant fields
//       guard let userId = tagsDictionary["target-user-id"] else {
//           logger.warning("CLEARCHAT message missing target-user-id")
//           return
//       }
//
//       let banReason = tagsDictionary["ban-reason"]?.removingPercentEncoding ?? "No reason provided"
//       let duration = tagsDictionary["ban-duration"] // Present if it's a timeout
//
//       // Log the extracted information
//       if let duration = duration {
//           logger.info("User \(userId) was timed out for \(duration) seconds. Reason: \(banReason)")
//       } else {
//           logger.info("User \(userId) was permanently banned. Reason: \(banReason)")
//       }
//
//       // Remove or mark the user's messages as deleted in the chat model
//       DispatchQueue.main.async {
//           for index in self.model.chatPosts.indices {
//               if self.model.chatPosts[index].userId == userId {
//                   self.model.chatPosts[index].isDeleted = true
//               }
//           }
//       }
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

private func extractMessageId(from message: String) -> String? {
    let tagsSection = message.split(separator: " ").first(where: { $0.hasPrefix("@") })
    guard let tags = tagsSection else { return nil }

    // Parse tags into a dictionary
    let tagsDictionary = tags.dropFirst().split(separator: ";").reduce(into: [String: String]()) { dict, pair in
        let parts = pair.split(separator: "=", maxSplits: 1).map(String.init)
        if parts.count == 2 {
            dict[parts[0]] = parts[1]
        }
    }

    return tagsDictionary["id"] // Extract the message ID
}

extension ChatMessage {
    func isAction() -> Bool {
        return text.starts(with: "\u{01}ACTION")
    }
}

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

    func webSocketClientDisconnected(_ webSocket: WebSocketClient) {
        logger.debug("twitch: chat: Disconnected")
    }

    func webSocketClientReceiveMessage(_ webSocket: WebSocketClient, string: String) {
        for line in string.split(whereSeparator: { $0.isNewline }) {
            let message = String(line)
            
            logger.debug("twitch: chat: \(message)")
            // Check if the message is a CLEARMSG or CLEARCHAT command
            if message.contains("CLEARMSG") {
                handleClearMessage(message: message)
            } else if message.contains("CLEARCHAT") {
                handleClearChat(message: message)
            } else {
                try? handleMessage(message: message)
            }
        }
    }
}
