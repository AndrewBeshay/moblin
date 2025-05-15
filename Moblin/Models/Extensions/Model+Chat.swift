import Foundation
import Collections
import TwitchChat
import SwiftUI

// MARK: - Constants
private let maximumNumberOfChatMessages = 50
private let maximumNumberOfInteractiveChatMessages = 100

// MARK: - Chat Types
struct ChatMessageEmote: Identifiable {
    var id = UUID()
    var url: URL
    var range: ClosedRange<Int>
}

struct ChatPostSegment: Identifiable, Codable {
    var id: Int
    var text: String?
    var url: URL?
}

enum ChatHighlightKind: Codable {
    case redemption
    case other
    case firstMessage
    case newFollower
    case reply
}

struct ChatHighlight {
    let kind: ChatHighlightKind
    let color: Color
    let image: String
    let title: String

    func toWatchProtocol() -> WatchProtocolChatHighlight {
        let watchProtocolKind: WatchProtocolChatHighlightKind
        switch kind {
        case .redemption:
            watchProtocolKind = .redemption
        case .other:
            watchProtocolKind = .other
        case .newFollower:
            watchProtocolKind = .redemption
        case .firstMessage:
            watchProtocolKind = .other
        case .reply:
            watchProtocolKind = .other
        }
        let color = color.toRgb() ?? .init(red: 0, green: 255, blue: 0)
        return WatchProtocolChatHighlight(
            kind: watchProtocolKind,
            color: .init(red: color.red, green: color.green, blue: color.blue),
            image: image,
            title: title
        )
    }
}

struct ChatPost: Identifiable, Equatable {
    static func == (lhs: ChatPost, rhs: ChatPost) -> Bool {
        return lhs.id == rhs.id
    }

    func isRedemption() -> Bool {
        return highlight?.kind == .redemption || highlight?.kind == .newFollower
    }

    var id: Int
    var user: String?
    var userColor: RgbColor
    var userBadges: [URL]
    var segments: [ChatPostSegment]
    var timestamp: String
    var timestampTime: ContinuousClock.Instant
    var isAction: Bool
    var isSubscriber: Bool
    var bits: String?
    var highlight: ChatHighlight?
    var live: Bool
}

// MARK: - Chat Helper Functions
extension Model {
    func makeChatPostTextSegments(text: String, id: inout Int) -> [ChatPostSegment] {
        var segments: [ChatPostSegment] = []
        for word in text.split(separator: " ") {
            segments.append(ChatPostSegment(
                id: id,
                text: "\(word) "
            ))
            id += 1
        }
        return segments
    }
}

// MARK: - TwitchEventSubDelegate
extension Model: TwitchEventSubDelegate {
    func twitchEventSubMakeErrorToast(title: String) {
        makeErrorToast(
            title: title,
            subTitle: String(localized: "Re-login to Twitch probably fixes this error")
        )
    }

    func twitchEventSubUnauthorized() {
        twitchApiUnauthorized()
    }

    func twitchEventSubNotification(message _: String) {}
    
    func twitchEventSubChannelFollow(event: TwitchEventSubNotificationChannelFollowEvent) {
        DispatchQueue.main.async {
            guard self.stream.twitchShowFollows! else {
                return
            }
            let text = String(localized: "just followed!")
            self.makeToast(title: "\(event.user_name) \(text)")
            self.playAlert(alert: .twitchFollow(event))
            self.appendTwitchChatAlertMessage(
                user: event.user_name,
                text: text,
                title: String(localized: "New follower"),
                color: .pink,
                kind: .newFollower
            )
        }
    }

    func twitchEventSubChannelSubscribe(event: TwitchEventSubNotificationChannelSubscribeEvent) {
        guard !event.is_gift else {
            return
        }
        DispatchQueue.main.async {
            let text = String(localized: "just subscribed tier \(event.tierAsNumber())!")
            self.makeToast(title: "\(event.user_name) \(text)")
            self.playAlert(alert: .twitchSubscribe(event))
            self.appendTwitchChatAlertMessage(
                user: event.user_name,
                text: text,
                title: String(localized: "New subscriber"),
                color: .cyan,
                image: "party.popper"
            )
        }
    }

    func twitchEventSubChannelSubscriptionGift(event: TwitchEventSubNotificationChannelSubscriptionGiftEvent) {
        DispatchQueue.main.async {
            let user = event.user_name ?? String(localized: "Anonymous")
            let text = String(localized: "just gifted \(event.total) tier \(event.tierAsNumber()) subsciptions!")
            self.makeToast(title: "\(user) \(text)")
            self.playAlert(alert: .twitchSubscrptionGift(event))
            self.appendTwitchChatAlertMessage(
                user: user,
                text: text,
                title: String(localized: "Gift subsciptions"),
                color: .cyan,
                image: "gift"
            )
        }
    }

    func twitchEventSubChannelSubscriptionMessage(event: TwitchEventSubNotificationChannelSubscriptionMessageEvent) {
        DispatchQueue.main.async {
            let text = String(localized: """
            just resubscribed tier \(event.tierAsNumber()) for \(event.cumulative_months) \
            months! \(event.message.text)
            """)
            self.makeToast(title: "\(event.user_name) \(text)")
            self.playAlert(alert: .twitchResubscribe(event))
            self.appendTwitchChatAlertMessage(
                user: event.user_name,
                text: text,
                title: String(localized: "New resubscribe"),
                color: .cyan,
                image: "party.popper"
            )
        }
    }

    func twitchEventSubChannelPointsCustomRewardRedemptionAdd(
        event: TwitchEventSubNotificationChannelPointsCustomRewardRedemptionAddEvent
    ) {
        let text = String(localized: "redeemed \(event.reward.title)!")
        makeToast(title: "\(event.user_name) \(text)")
        appendTwitchChatAlertMessage(
            user: event.user_name,
            text: text,
            title: String(localized: "Reward redemption"),
            color: .blue,
            image: "medal.star"
        )
    }

    func twitchEventSubChannelRaid(event: TwitchEventSubChannelRaidEvent) {
        DispatchQueue.main.async {
            let text = String(localized: "raided with a party of \(event.viewers)!")
            self.makeToast(title: "\(event.from_broadcaster_user_name) \(text)")
            self.playAlert(alert: .twitchRaid(event))
            self.appendTwitchChatAlertMessage(
                user: event.from_broadcaster_user_name,
                text: text,
                title: String(localized: "Raid"),
                color: .pink,
                image: "person.3"
            )
        }
    }

    func twitchEventSubChannelCheer(event: TwitchEventSubChannelCheerEvent) {
        DispatchQueue.main.async {
            let user = event.user_name ?? String(localized: "Anonymous")
            let bits = countFormatter.format(event.bits)
            let text = String(localized: "cheered \(bits) bits!")
            self.makeToast(title: "\(user) \(text)", subTitle: event.message)
            self.playAlert(alert: .twitchCheer(event))
            self.appendTwitchChatAlertMessage(
                user: user,
                text: "\(text) \(event.message)",
                title: String(localized: "Cheer"),
                color: .green,
                image: "suit.diamond",
                bits: ""
            )
        }
    }

    func twitchEventSubChannelHypeTrainBegin(event: TwitchEventSubChannelHypeTrainBeginEvent) {
        hypeTrainLevel = event.level
        hypeTrainProgress = event.progress
        hypeTrainGoal = event.goal
        updateHypeTrainStatus(level: event.level, progress: event.progress, goal: event.goal)
        startHypeTrainTimer(timeout: 600)
    }

    func twitchEventSubChannelHypeTrainProgress(event: TwitchEventSubChannelHypeTrainProgressEvent) {
        hypeTrainLevel = event.level
        hypeTrainProgress = event.progress
        hypeTrainGoal = event.goal
        updateHypeTrainStatus(level: event.level, progress: event.progress, goal: event.goal)
        startHypeTrainTimer(timeout: 600)
    }

    func twitchEventSubChannelHypeTrainEnd(event: TwitchEventSubChannelHypeTrainEndEvent) {
        hypeTrainLevel = event.level
        hypeTrainProgress = 1
        hypeTrainGoal = 1
        updateHypeTrainStatus(level: event.level, progress: 1, goal: 1)
        startHypeTrainTimer(timeout: 60)
    }

    func twitchEventSubChannelAdBreakBegin(event: TwitchEventSubChannelAdBreakBeginEvent) {
        adsEndDate = Date().advanced(by: Double(event.duration_seconds))
        let duration = formatCommercialStartedDuration(seconds: event.duration_seconds)
        let kind = event.is_automatic ? String(localized: "automatic") : String(localized: "manual")
        makeToast(title: String(localized: "\(duration) \(kind) commercial starting"))
    }
}

// MARK: - TwitchApiDelegate
extension Model: TwitchApiDelegate {
    func twitchApiUnauthorized() {
        stream.twitchLoggedIn = false
        makeNotLoggedInToTwitchToast()
    }
    
    private func makeNotLoggedInToTwitchToast() {
        makeErrorToast(
            title: String(localized: "Not logged in to Twitch"),
            subTitle: String(localized: "Please login again")
        )
    }

    func getTwitchChannelInformation(
        stream: SettingsStream,
        onComplete: @escaping (TwitchApiChannelInformationData) -> Void
    ) {
        guard stream.twitchLoggedIn! else {
            makeNotLoggedInToTwitchToast()
            return
        }
        TwitchApi(stream.twitchAccessToken!, urlSession)
            .getChannelInformation(broadcasterId: stream.twitchChannelId) { channelInformation in
                guard let channelInformation else {
                    return
                }
                onComplete(channelInformation)
            }
    }

    func setTwitchStreamTitle(stream: SettingsStream, title: String) {
        guard stream.twitchLoggedIn! else {
            makeNotLoggedInToTwitchToast()
            return
        }
        TwitchApi(stream.twitchAccessToken!, urlSession)
            .modifyChannelInformation(broadcasterId: stream.twitchChannelId, category: nil,
                                      title: title)
        { ok in
            if !ok {
                self.makeErrorToast(title: "Failed to set stream title")
            }
        }
    }

    func sendChatMessage(message: String) {
        guard isTwitchAccessTokenConfigured() else {
            makeNotLoggedInToTwitchToast()
            return
        }
        TwitchApi(stream.twitchAccessToken!, urlSession)
            .sendChatMessage(broadcasterId: stream.twitchChannelId, message: message) { ok in
                if !ok {
                    self.makeErrorToast(title: "Failed to send chat message")
                }
            }
    }
}

// MARK: - TwitchChatMoblinDelegate
extension Model: TwitchChatMoblinDelegate {
    func twitchChatMoblinMakeErrorToast(title: String, subTitle: String?) {
        makeErrorToast(title: title, subTitle: subTitle)
    }

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
    ) {
        appendChatMessage(platform: .twitch,
                          user: user,
                          userId: userId,
                          userColor: userColor,
                          userBadges: userBadges,
                          segments: segments,
                          timestamp: digitalClock,
                          timestampTime: .now,
                          isAction: isAction,
                          isSubscriber: isSubscriber,
                          isModerator: isModerator,
                          bits: bits,
                          highlight: highlight,
                          live: true)
    }
}

// MARK: - KickOusherDelegate
extension Model: KickOusherDelegate {
    func kickPusherMakeErrorToast(title: String, subTitle: String?) {
        makeErrorToast(title: title, subTitle: subTitle)
    }

    func kickPusherAppendMessage(
        user: String,
        userColor: RgbColor?,
        segments: [ChatPostSegment],
        isSubscriber: Bool,
        isModerator: Bool,
        highlight: ChatHighlight?
    ) {
        appendChatMessage(platform: .kick,
                          user: user,
                          userId: nil,
                          userColor: userColor,
                          userBadges: [],
                          segments: segments,
                          timestamp: digitalClock,
                          timestampTime: .now,
                          isAction: false,
                          isSubscriber: isSubscriber,
                          isModerator: isModerator,
                          bits: nil,
                          highlight: highlight,
                          live: true)
    }
}

// MARK: - Private Helper Methods
extension Model {
    func updateHypeTrainStatus(level: Int, progress: Int, goal: Int) {
        let percentage = Int(100 * Float(progress) / Float(goal))
        hypeTrainStatus = "LVL \(level), \(percentage)%"
    }

    func startHypeTrainTimer(timeout: Double) {
        hypeTrainTimer.startSingleShot(timeout: timeout) { [weak self] in
            self?.removeHypeTrain()
        }
    }

    func stopHypeTrainTimer() {
        hypeTrainTimer.stop()
    }

    func removeHypeTrain() {
        hypeTrainLevel = nil
        hypeTrainProgress = nil
        hypeTrainGoal = nil
        hypeTrainStatus = noValue
        stopHypeTrainTimer()
    }

    func appendTwitchChatAlertMessage(
        user: String,
        text: String,
        title: String,
        color: Color,
        image: String? = nil,
        kind: ChatHighlightKind? = nil,
        bits: String? = nil
    ) {
        appendChatMessage(platform: .twitch,
                          user: user,
                          userId: nil,
                          userColor: nil,
                          userBadges: [],
                          segments: twitchChat.createSegmentsNoTwitchEmotes(text: text, bits: bits),
                          timestamp: digitalClock,
                          timestampTime: .now,
                          isAction: false,
                          isSubscriber: false,
                          isModerator: false,
                          bits: bits,
                          highlight: .init(
                            kind: kind ?? .other,
                            color: color,
                            image: image ?? "exclamationmark.circle",
                            title: title
                          ),
                          live: true)
    }
}

// MARK: - Chat Provider
class ChatProvider: ObservableObject {
    var newPosts: Deque<ChatPost> = []
    var pausedPosts: Deque<ChatPost> = []
    @Published var posts: Deque<ChatPost> = []
    @Published var pausedPostsCount: Int = 0
    @Published var paused = false
    private let maximumNumberOfMessages: Int
    
    init(maximumNumberOfMessages: Int) {
        self.maximumNumberOfMessages = maximumNumberOfMessages
    }
    
    func reset() {
        posts = []
        pausedPosts = []
        newPosts = []
    }
    
    func appendMessage(post: ChatPost) {
        if paused {
            if pausedPosts.count < 2 * maximumNumberOfMessages {
                pausedPosts.append(post)
            }
        } else {
            newPosts.append(post)
        }
    }
    
    func update() {
        if paused {
            pausedPostsCount = max(pausedPosts.count - 1, 0)
        } else {
            while let post = newPosts.popFirst() {
                if posts.count > maximumNumberOfMessages - 1 {
                    posts.removeLast()
                }
                posts.prepend(post)
            }
        }
    }
} 
