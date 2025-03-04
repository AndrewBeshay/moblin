import Foundation

private struct BasicMetadata: Decodable {
    var message_type: String
    var subscription_type: String?
}

private struct BasicMessage: Decodable {
    var metadata: BasicMetadata
}

private struct WelcomePayloadSession: Decodable {
    var id: String
}

private struct WelcomePayload: Decodable {
    var session: WelcomePayloadSession
}

private struct WelcomeMessage: Decodable {
    var payload: WelcomePayload
}

struct TwitchEventSubMessage: Decodable {
    var text: String
}

struct TwitchEventSubNotificationChannelSubscribeEvent: Decodable {
    var user_name: String
    var tier: String
    var is_gift: Bool

    func tierAsNumber() -> Int {
        return twitchTierAsNumber(tier: tier)
    }
}

private struct NotificationChannelSubscribePayload: Decodable {
    var event: TwitchEventSubNotificationChannelSubscribeEvent
}

private struct NotificationChannelSubscribeMessage: Decodable {
    var payload: NotificationChannelSubscribePayload
}

struct TwitchEventSubNotificationChannelSubscriptionGiftEvent: Decodable {
    var user_name: String?
    var total: Int
    var tier: String

    func tierAsNumber() -> Int {
        return twitchTierAsNumber(tier: tier)
    }
}

private struct NotificationChannelSubscriptionGiftPayload: Decodable {
    var event: TwitchEventSubNotificationChannelSubscriptionGiftEvent
}

private struct NotificationChannelSubscriptionGiftMessage: Decodable {
    var payload: NotificationChannelSubscriptionGiftPayload
}

struct TwitchEventSubNotificationChannelSubscriptionMessageEvent: Decodable {
    var user_name: String
    var cumulative_months: Int
    var tier: String
    var message: TwitchEventSubMessage

    func tierAsNumber() -> Int {
        return twitchTierAsNumber(tier: tier)
    }
}

private struct NotificationChannelSubscriptionMessagePayload: Decodable {
    var event: TwitchEventSubNotificationChannelSubscriptionMessageEvent
}

private struct NotificationChannelSubscriptionMessageMessage: Decodable {
    var payload: NotificationChannelSubscriptionMessagePayload
}

struct TwitchEventSubNotificationChannelFollowEvent: Decodable {
    var user_name: String
}

private struct NotificationChannelFollowPayload: Decodable {
    var event: TwitchEventSubNotificationChannelFollowEvent
}

private struct NotificationChannelFollowMessage: Decodable {
    var payload: NotificationChannelFollowPayload
}

// periphery:ignore
struct TwitchEventSubNotificationChannelPointsCustomRewardRedemptionAddEventReward: Decodable {
    var id: String
    var title: String
    var cost: Int
    var prompt: String
}

// periphery:ignore
struct TwitchEventSubNotificationChannelPointsCustomRewardRedemptionAddEvent: Decodable {
    var id: String
    var user_id: String
    var user_login: String
    var user_name: String
    var broadcaster_user_id: String
    var broadcaster_user_login: String
    var broadcaster_user_name: String
    var status: String
    var reward: TwitchEventSubNotificationChannelPointsCustomRewardRedemptionAddEventReward
    var redeemed_at: String
}

private struct NotificationChannelPointsCustomRewardRedemptionAddPayload: Decodable {
    // periphery:ignore
    var event: TwitchEventSubNotificationChannelPointsCustomRewardRedemptionAddEvent
}

private struct NotificationChannelPointsCustomRewardRedemptionAddMessage: Decodable {
    // periphery:ignore
    var payload: NotificationChannelPointsCustomRewardRedemptionAddPayload
}

struct TwitchEventSubChannelRaidEvent: Decodable {
    var from_broadcaster_user_name: String
    var viewers: Int
}

private struct NotificationChannelRaidPayload: Decodable {
    var event: TwitchEventSubChannelRaidEvent
}

private struct NotificationChannelRaidMessage: Decodable {
    var payload: NotificationChannelRaidPayload
}

struct TwitchEventSubChannelCheerEvent: Decodable {
    var user_name: String?
    var message: String
    var bits: Int
}

private struct NotificationChannelCheerPayload: Decodable {
    var event: TwitchEventSubChannelCheerEvent
}

private struct NotificationChannelCheerMessage: Decodable {
    var payload: NotificationChannelCheerPayload
}

struct TwitchEventSubChannelHypeTrainBeginEvent: Decodable {
    var progress: Int
    var goal: Int
    var level: Int
    // periphery:ignore
    var started_at: String
    // periphery:ignore
    var expires_at: String
}

private struct NotificationChannelHypeTrainBeginPayload: Decodable {
    var event: TwitchEventSubChannelHypeTrainBeginEvent
}

private struct NotificationChannelHypeTrainBeginMessage: Decodable {
    var payload: NotificationChannelHypeTrainBeginPayload
}

struct TwitchEventSubChannelHypeTrainProgressEvent: Decodable {
    var progress: Int
    var goal: Int
    var level: Int
    // periphery:ignore
    var started_at: String
    // periphery:ignore
    var expires_at: String
}

private struct NotificationChannelHypeTrainProgressPayload: Decodable {
    var event: TwitchEventSubChannelHypeTrainProgressEvent
}

private struct NotificationChannelHypeTrainProgressMessage: Decodable {
    var payload: NotificationChannelHypeTrainProgressPayload
}

struct TwitchEventSubChannelHypeTrainEndEvent: Decodable {
    var level: Int
    // periphery:ignore
    var started_at: String
    // periphery:ignore
    var ended_at: String
}

private struct NotificationChannelHypeTrainEndPayload: Decodable {
    var event: TwitchEventSubChannelHypeTrainEndEvent
}

private struct NotificationChannelHypeTrainEndMessage: Decodable {
    var payload: NotificationChannelHypeTrainEndPayload
}

struct TwitchEventSubChannelAdBreakBeginEvent: Decodable {
    var duration_seconds: Int
    var is_automatic: Bool
}

private struct NotificationChannelAdBreakBeginPayload: Decodable {
    var event: TwitchEventSubChannelAdBreakBeginEvent
}

private struct NotificationChannelAdBreakBeginMessage: Decodable {
    var payload: NotificationChannelAdBreakBeginPayload
}

// MARK: - New: Channel Moderate Data Models (v2)
// This event is triggered when a moderator performs a moderation action (for example, a timeout or ban) via the moderator interface.

// This struct represents the target of the moderation action.
// When the action is "delete", the payload provides the target details under the "delete" key.
// In that case, "message_body" is used as the reason and a "message_id" is provided.
struct TargetUser: Decodable, CustomStringConvertible {
    var user_id: String
    var user_login: String
    var user_name: String
    /// For some events (for example, timeouts), Twitch provides a "reason" key.
    var reason: String?
    /// For other events (for example, delete events), Twitch provides a "message_body" key.
    var messageBody: String?
    var expires_at: String?
    var message_id: String?
    
    var description: String {
        var output = "TargetUser:\n"
        output += "  ID: \(user_id)\n"
        output += "  Login: \(user_login)\n"
        output += "  Name: \(user_name)"
        if let message_id = message_id {
            output += "\n  Message ID: \(message_id)"
        }
        if let reason = reason {
            output += "\n  Reason: \(reason)"
        }
        if let messageBody = messageBody {
            output += "\n  Message Body: \(messageBody)"
        }
        if let expires_at = expires_at {
            output += "\n  Expires At: \(expires_at)"
        }
        return output
    }
    
    enum CodingKeys: String, CodingKey {
        case user_id
        case user_login
        case user_name
        case reason
        case messageBody = "message_body"
        case expires_at
        case message_id
    }
}

// This struct represents the moderation event.
// It decodes the target user data from the "delete" key if the action is "delete",
// or from a "target_user" key if present for other actions.
struct TwitchEventSubChannelModerateEvent: Decodable, CustomStringConvertible {
    var broadcaster_user_id: String
    var broadcaster_user_login: String
    var broadcaster_user_name: String
    var moderator_user_id: String
    var moderator_user_login: String
    var moderator_user_name: String
    var action: String
    var moderated_at: String?
    var target_user: TargetUser?
    
    var description: String {
        var output = "ChannelModerateEvent:\n"
        output += "  Action: \(action)\n"
        if let moderated_at = moderated_at {
            output += "  Moderated At: \(moderated_at)\n"
        } else {
            output += "  Moderated At: n/a\n"
        }
        output += "  Broadcaster: \(broadcaster_user_name) (\(broadcaster_user_login), \(broadcaster_user_id))\n"
        output += "  Moderator: \(moderator_user_name) (\(moderator_user_login), \(moderator_user_id))\n"
        if let target = target_user {
            output += "\n" + target.description
        }
        return output
    }
    
    enum CodingKeys: String, CodingKey {
        case broadcaster_user_id
        case broadcaster_user_login
        case broadcaster_user_name
        case moderator_user_id
        case moderator_user_login
        case moderator_user_name
        case action
        case moderated_at
        // The keys that may contain target info.
        case target_user
        
        case ban
        case timeout
        case unban
        case untimeout
        case clear
        case emoteonly
        case emoteonlyoff
        case followers
        case followersoff
        case uniquechat
        case uniquechatoff
        case slow
        case slowoff
        case subscribers
        case subscribersoff
        case unraid
        case delete
        case unvip
        case vip
        case raid
        case addBlockedTerm
        case addPermittedTerm
        case removeBlockedTerm
        case removePermittedTerm
        case mod
        case unmod
        case approveUnbanRequest
        case denyUnbanRequest
        case warn
        case sharedChatBan
        case sharedChatTimeout
        case sharedChatUnban
        case sharedChatUntimeout
        case sharedChatDelete
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        broadcaster_user_id = try container.decode(String.self, forKey: .broadcaster_user_id)
        broadcaster_user_login = try container.decode(String.self, forKey: .broadcaster_user_login)
        broadcaster_user_name = try container.decode(String.self, forKey: .broadcaster_user_name)
        moderator_user_id = try container.decode(String.self, forKey: .moderator_user_id)
        moderator_user_login = try container.decode(String.self, forKey: .moderator_user_login)
        moderator_user_name = try container.decode(String.self, forKey: .moderator_user_name)
        action = try container.decode(String.self, forKey: .action)
        // Use decodeIfPresent for keys that might be missing.
        moderated_at = try container.decodeIfPresent(String.self, forKey: .moderated_at)
        
        // Use the raw action string to try to create a dynamic key.
        if let key = CodingKeys(rawValue: action) {
            target_user = try? container.decode(TargetUser.self, forKey: key)
        } else {
            target_user = try? container.decode(TargetUser.self, forKey: .target_user)
        }
    }
}

// Wrap the event in a payload struct.
struct NotificationChannelModeratePayload: Decodable, CustomStringConvertible {
    var event: TwitchEventSubChannelModerateEvent
    
    var description: String {
        return event.description
    }
}

//private func parseRFC3339NanoTimestamp(_ timestamp: String) -> Date? {
//    let dateFormatter = DateFormatter()
//    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSSSX"
//    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
//    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
//
//    return dateFormatter.date(from: timestamp)
//}

// Wrap the payload in a message struct.
struct NotificationChannelModerateMessage: Decodable, CustomStringConvertible {
    var metadata: BasicMetadataTimestamp
    var payload: NotificationChannelModeratePayload
    
    var timeoutDuration: String? {
        guard let expiresAt = payload.event.target_user?.expires_at,
              let rawExpiresDate = parseRFC3339NanoTimestamp(expiresAt),
              let messageTimestamp = parseRFC3339NanoTimestamp(metadata.message_timestamp) else {
            return nil
        }

        // Round the expiration date to whole seconds
        let roundedExpiresDate = Date(timeIntervalSinceReferenceDate: ceil(rawExpiresDate.timeIntervalSinceReferenceDate))
        // Compute duration and convert to an integer (removes decimals)
        let duration = Int(roundedExpiresDate.timeIntervalSince(messageTimestamp))

        return "\(duration)s"
    }
    
    
    var description: String {
        return payload.description
    }
}

struct BasicMetadataTimestamp: Decodable {
    var message_timestamp: String
}

/// MARK - Shared Chat Payload
/// ok

/// Represents a participant in the shared chat
struct TwitchEventSubSharedChatParticipant: Decodable {
    var broadcaster_user_id: String
    var broadcaster_user_login: String
    var broadcaster_user_name: String
}

/// Represents the shared chat begin event
struct TwitchEventSubSharedChatEvent: Decodable {
    var session_id: String
    var broadcaster_user_id: String
    var broadcaster_user_login: String
    var broadcaster_user_name: String
    var host_broadcaster_user_id: String
    var host_broadcaster_user_login: String
    var host_broadcaster_user_name: String
    var participants: [TwitchEventSubSharedChatParticipant]?
}

/// Wrapper for decoding the payload
private struct NotificationSharedChatBeginPayload: Decodable {
    var event: TwitchEventSubSharedChatEvent
}

/// Wrapper for the full WebSocket message
private struct NotificationSharedChatBeginMessage: Decodable {
    var payload: NotificationSharedChatBeginPayload
}

/// Wrapper for decoding `channel.shared_chat.update` payload
private struct NotificationSharedChatUpdatePayload: Decodable {
    var event: TwitchEventSubSharedChatEvent
}

/// Wrapper for the full WebSocket message
private struct NotificationSharedChatUpdateMessage: Decodable {
    var payload: NotificationSharedChatUpdatePayload
}

/// Represents the shared chat end event
struct TwitchEventSubSharedChatEndEvent: Decodable {
    var session_id: String
    var broadcaster_user_id: String
    var broadcaster_user_login: String
    var broadcaster_user_name: String
    var host_broadcaster_user_id: String
    var host_broadcaster_user_login: String
    var host_broadcaster_user_name: String
}

/// Wrapper for decoding `channel.shared_chat.end` payload
private struct NotificationSharedChatEndPayload: Decodable {
    var event: TwitchEventSubSharedChatEndEvent
}

/// Wrapper for the full WebSocket message
private struct NotificationSharedChatEndMessage: Decodable {
    var payload: NotificationSharedChatEndPayload
}

private var url = URL(string: "wss://eventsub.wss.twitch.tv/ws")!

protocol TwitchEventSubDelegate: AnyObject {
    func twitchEventSubMakeErrorToast(title: String)
    func twitchEventSubChannelFollow(event: TwitchEventSubNotificationChannelFollowEvent)
    func twitchEventSubChannelSubscribe(event: TwitchEventSubNotificationChannelSubscribeEvent)
    func twitchEventSubChannelSubscriptionGift(event: TwitchEventSubNotificationChannelSubscriptionGiftEvent)
    func twitchEventSubChannelSubscriptionMessage(
        event: TwitchEventSubNotificationChannelSubscriptionMessageEvent
    )
    func twitchEventSubChannelPointsCustomRewardRedemptionAdd(
        event: TwitchEventSubNotificationChannelPointsCustomRewardRedemptionAddEvent
    )
    func twitchEventSubChannelRaid(event: TwitchEventSubChannelRaidEvent)
    func twitchEventSubChannelCheer(event: TwitchEventSubChannelCheerEvent)
    func twitchEventSubChannelHypeTrainBegin(event: TwitchEventSubChannelHypeTrainBeginEvent)
    func twitchEventSubChannelHypeTrainProgress(event: TwitchEventSubChannelHypeTrainProgressEvent)
    func twitchEventSubChannelHypeTrainEnd(event: TwitchEventSubChannelHypeTrainEndEvent)
    func twitchEventSubChannelAdBreakBegin(event: TwitchEventSubChannelAdBreakBeginEvent)
    func twitchEventSubUnauthorized()
    func twitchEventSubNotification(message: String)
    func twitchEventSubChannelModerate(event: NotificationChannelModerateMessage) // New delegate method
    func twitchEventSubSharedChatBegin(event: TwitchEventSubSharedChatEvent)
    func twitchEventSubSharedChatUpdate(event: TwitchEventSubSharedChatEvent)
    func twitchEventSubSharedChatEnd(event: TwitchEventSubSharedChatEndEvent)
}

private let subTypeChannelFollow = "channel.follow"
private let subTypeChannelSubscribe = "channel.subscribe"
private let subTypeChannelSubscriptionGift = "channel.subscription.gift"
private let subTypeChannelSubscriptionMessage = "channel.subscription.message"
private let subTypeChannelChannelPointsCustomRewardRedemptionAdd =
    "channel.channel_points_custom_reward_redemption.add"
private let subTypeChannelRaid = "channel.raid"
private let subTypeChannelCheer = "channel.cheer"
private let subTypeChannelHypeTrainBegin = "channel.hype_train.begin"
private let subTypeChannelHypeTrainProgress = "channel.hype_train.progress"
private let subTypeChannelHypeTrainEnd = "channel.hype_train.end"
private let subTypeChannelAdBreakBegin = "channel.ad_break.begin"
private let CHANNEL_MODERATE = "channel.moderate"
private let channelSharedChatBegin = "channel.shared_chat.begin"
private let channelSharedChatUpdate = "channel.shared_chat.update"
private let channelSharedChatEnd = "channel.shared_chat.end"

final class TwitchEventSub: NSObject {
    private var webSocket: WebSocketClient
    private var remoteControl: Bool
    private let userId: String
    private let httpProxy: HttpProxy?
    private var sessionId: String = ""
    private var twitchApi: TwitchAPI
    private let delegate: any TwitchEventSubDelegate
    private var connected = false
    private var started = false

    /// Computed property to ensure correct transport data
    private var transport: TwitchApiEventSubTransport {
        return TwitchApiEventSubTransport(method: "websocket", callback: nil, secret: nil, session_id: sessionId)
    }
    
    init(
        remoteControl: Bool,
        userId: String,
        accessToken: String,
        httpProxy: HttpProxy?,
        urlSession: URLSession,
        delegate: TwitchEventSubDelegate
    ) {
        self.remoteControl = remoteControl
        self.userId = userId
        self.httpProxy = httpProxy
        self.delegate = delegate
        twitchApi = TwitchAPI.shared
        webSocket = .init(url: URL(string: "wss://eventsub.wss.twitch.tv/ws")!, httpProxy: httpProxy)
        super.init()
    }
    
    /// **Starts WebSocket Connection & Subscription Process**
    func start() {
        logger.info("🔄 Twitch EventSub: Starting WebSocket connection")
        stopInternal()
        connect()
        started = true
    }

    /// **Stops WebSocket & Clears State**
    func stop() {
        logger.info("🛑 Twitch EventSub: Stopping WebSocket")
        webSocket.delegate = nil
        started = false
        stopInternal()
    }

    private func stopInternal() {
        connected = false
        webSocket.stop()
    }

    func isConnected() -> Bool {
        return connected
    }
    
    private func connect() {
        connected = false
        webSocket = .init(url: URL(string: "wss://eventsub.wss.twitch.tv/ws")!, httpProxy: httpProxy)
        webSocket.delegate = self
        if !remoteControl {
            webSocket.start()
        }
    }
    
    /// **Handles incoming WebSocket messages**
    func handleMessage(messageText: String) {
        let messageData = messageText.utf8Data
        guard let message = try? JSONDecoder().decode(BasicMessage.self, from: messageData) else {
            return
        }
        switch message.metadata.message_type {
        case "session_welcome":
            handleSessionWelcome(messageData: messageData)
        case "session_keepalive":
            break
        case "notification":
            handleNotification(message: message, messageText: messageText, messageData: messageData)
        default:
            logger.info("twitch: event-sub: Unknown message type \(message.metadata.message_type)")
        }
    }

    /// **Handles WebSocket Session Welcome & Ensures Subscription Process**
    private func handleSessionWelcome(messageData: Data) {
        guard let message = try? JSONDecoder().decode(WelcomeMessage.self, from: messageData) else {
            logger.error("❌ Failed to decode welcome message")
            return
        }

        sessionId = message.payload.session.id
        logger.info("✅ WebSocket Connected - Session ID: \(sessionId)")
        verifyAndSubscribe()
    }

    /// **Fetches Active Subscriptions & Prevents Duplicates**
    private func verifyAndSubscribe() {
        twitchApi.eventSub.getEventSubSubscriptions { subs, total, _, _ in
            guard let existingSubs = subs else {
                logger.error("❌ Failed to fetch existing EventSub subscriptions, proceeding with new subscriptions.")
                self.subscribeAllEvents()
                return
            }

            let activeEventTypes = Set(existingSubs.map { $0.type })
            logger.info("🔍 Existing Active Subscriptions: \(activeEventTypes)")

            DispatchQueue.global(qos: .background).async {
                if !activeEventTypes.contains(subTypeChannelFollow) { self.subscribeToChannelFollow() }
                if !activeEventTypes.contains(subTypeChannelSubscribe) { self.subscribeToChannelSubscribe() }
                if !activeEventTypes.contains(subTypeChannelSubscriptionGift) { self.subscribeToChannelSubscriptionGift() }
                if !activeEventTypes.contains(subTypeChannelSubscriptionMessage) { self.subscribeToChannelSubscriptionMessage() }
                if !activeEventTypes.contains(subTypeChannelRaid) { self.subscribeToChannelRaid() }
                if !activeEventTypes.contains(subTypeChannelCheer) { self.subscribeToChannelCheer() }
                if !activeEventTypes.contains(CHANNEL_MODERATE) { self.subscribeToChannelModerate() }
            }
        }
    }


    /// **Subscribes All Events in Parallel**
    private func subscribeAllEvents() {
        logger.info("🔄 Subscribing to all EventSub events in parallel")

        DispatchQueue.global(qos: .background).async {
            self.subscribeToChannelFollow()
            self.subscribeToChannelSubscribe()
            self.subscribeToChannelSubscriptionGift()
            self.subscribeToChannelSubscriptionMessage()
            self.subscribeToChannelRaid()
            self.subscribeToChannelCheer()
            self.subscribeToChannelModerate()
        }
    }

    private func subscribeToChannelFollow() {
        subscribe(type: subTypeChannelFollow, condition: ["broadcaster_user_id": userId], eventType: "Follow")
    }

    /// **Subscribes to Channel Subscription Event**
    private func subscribeToChannelSubscribe() {
        subscribe(type: subTypeChannelSubscribe, condition: ["broadcaster_user_id": userId], eventType: "Subscription")
    }

    /// **Subscribes to Channel Subscription Gift Event**
    private func subscribeToChannelSubscriptionGift() {
        subscribe(type: subTypeChannelSubscriptionGift, condition: ["broadcaster_user_id": userId], eventType: "Subscription Gift")
    }

    /// **Subscribes to Channel Subscription Message Event**
    private func subscribeToChannelSubscriptionMessage() {
        subscribe(type: subTypeChannelSubscriptionMessage, condition: ["broadcaster_user_id": userId], eventType: "Subscription Message")
    }

    /// **Subscribes to Channel Raid Event**
    private func subscribeToChannelRaid() {
        subscribe(type: subTypeChannelRaid, condition: ["to_broadcaster_user_id": userId], eventType: "Raid")
    }

    /// **Subscribes to Channel Cheer Event**
    private func subscribeToChannelCheer() {
        subscribe(type: subTypeChannelCheer, condition: ["broadcaster_user_id": userId], eventType: "Cheer")
    }

    /// **Subscribes to Channel Moderation Event**
    private func subscribeToChannelModerate() {
        let condition = ["broadcaster_user_id": userId, "moderator_user_id": userId]
        subscribe(type: CHANNEL_MODERATE, condition: condition, eventType: "Moderation")
    }

    /// **Generic Subscription Method**
    private func subscribe(type: String, condition: [String: String], eventType: String) {
        logger.info("📡 Subscribing to \(eventType) event")

        twitchApi.eventSub.createEventSubSubscription(
            type: type, version: "1", condition: condition, transport: transport
        ) { success in
            if success != nil {
                logger.info("✅ Successfully subscribed to \(eventType) event")
            } else {
                logger.error("❌ Failed to subscribe to \(eventType) event")
            }
        }
    }
    
    
    private func createBody(type: String, version: Int, condition: String) -> String {
        return """
        {
            "type": "\(type)",
            "version": "\(version)",
            "condition": \(condition),
            "transport": {
                "method": "websocket",
                "session_id": "\(sessionId)"
            }
        }
        """
    }

    private func createBroadcasterUserIdBody(type: String, version: Int = 1) -> String {
        return createBody(type: type,
                          version: version,
                          condition: "{\"broadcaster_user_id\":\"\(userId)\"}")
    }

    private func handleNotification(message: BasicMessage, messageText: String, messageData: Data) {
        do {
            switch message.metadata.subscription_type {
            case subTypeChannelFollow:
                try handleNotificationChannelFollow(messageData: messageData)
            case subTypeChannelSubscribe:
                try handleNotificationChannelSubscribe(messageData: messageData)
            case subTypeChannelSubscriptionGift:
                try handleNotificationChannelSubscriptionGift(messageData: messageData)
            case subTypeChannelSubscriptionMessage:
                try handleNotificationChannelSubscriptionMessage(messageData: messageData)
            case subTypeChannelChannelPointsCustomRewardRedemptionAdd:
                try handleChannelPointsCustomRewardRedemptionAdd(messageData: messageData)
            case subTypeChannelRaid:
                try handleChannelRaid(messageData: messageData)
            case subTypeChannelCheer:
                try handleChannelCheer(messageData: messageData)
            case subTypeChannelHypeTrainBegin:
                try handleChannelHypeTrainBegin(messageData: messageData)
            case subTypeChannelHypeTrainProgress:
                try handleChannelHypeTrainProgress(messageData: messageData)
            case subTypeChannelHypeTrainEnd:
                try handleChannelHypeTrainEnd(messageData: messageData)
            case subTypeChannelAdBreakBegin:
                try handleChannelAdBreakBegin(messageData: messageData)
            case CHANNEL_MODERATE: // New case for moderation events
                try handleChannelModerate(messageData: messageData)
            case channelSharedChatBegin:
                try handleSharedChatBegin(messageData: messageData)
            case channelSharedChatUpdate:
                try handleSharedChatUpdate(messageData: messageData)
            case channelSharedChatEnd:
                try handleSharedChatEnd(messageData: messageData)
            default:
                if let type = message.metadata.subscription_type {
                    logger.info("twitch: event-sub: Unknown notification type \(type)")
                } else {
                    logger.info("twitch: event-sub: Missing notification type")
                }
            }
            delegate.twitchEventSubNotification(message: messageText)
        } catch {
            let subscription_type = message.metadata.subscription_type ?? "unknown"
            logger.info("twitch: event-sub: Failed to handle notification \(subscription_type).")
        }
    }

    private func handleNotificationChannelFollow(messageData: Data) throws {
        let message = try JSONDecoder().decode(
            NotificationChannelFollowMessage.self,
            from: messageData
        )
        delegate.twitchEventSubChannelFollow(event: message.payload.event)
    }

    private func handleNotificationChannelSubscribe(messageData: Data) throws {
        let message = try JSONDecoder().decode(
            NotificationChannelSubscribeMessage.self,
            from: messageData
        )
        delegate.twitchEventSubChannelSubscribe(event: message.payload.event)
    }

    private func handleNotificationChannelSubscriptionGift(messageData: Data) throws {
        let message = try JSONDecoder().decode(
            NotificationChannelSubscriptionGiftMessage.self,
            from: messageData
        )
        delegate.twitchEventSubChannelSubscriptionGift(event: message.payload.event)
    }

    private func handleNotificationChannelSubscriptionMessage(messageData: Data) throws {
        let message = try JSONDecoder().decode(
            NotificationChannelSubscriptionMessageMessage.self,
            from: messageData
        )
        delegate.twitchEventSubChannelSubscriptionMessage(event: message.payload.event)
    }

    private func handleChannelPointsCustomRewardRedemptionAdd(messageData: Data) throws {
        let message = try JSONDecoder().decode(
            NotificationChannelPointsCustomRewardRedemptionAddMessage.self,
            from: messageData
        )
        delegate.twitchEventSubChannelPointsCustomRewardRedemptionAdd(event: message.payload.event)
    }

    private func handleChannelRaid(messageData: Data) throws {
        let message = try JSONDecoder().decode(
            NotificationChannelRaidMessage.self,
            from: messageData
        )
        delegate.twitchEventSubChannelRaid(event: message.payload.event)
    }

    private func handleChannelCheer(messageData: Data) throws {
        let message = try JSONDecoder().decode(
            NotificationChannelCheerMessage.self,
            from: messageData
        )
        delegate.twitchEventSubChannelCheer(event: message.payload.event)
    }

    private func handleChannelHypeTrainBegin(messageData: Data) throws {
        let message = try JSONDecoder().decode(
            NotificationChannelHypeTrainBeginMessage.self,
            from: messageData
        )
        delegate.twitchEventSubChannelHypeTrainBegin(event: message.payload.event)
    }

    private func handleChannelHypeTrainProgress(messageData: Data) throws {
        let message = try JSONDecoder().decode(
            NotificationChannelHypeTrainProgressMessage.self,
            from: messageData
        )
        delegate.twitchEventSubChannelHypeTrainProgress(event: message.payload.event)
    }

    private func handleChannelHypeTrainEnd(messageData: Data) throws {
        let message = try JSONDecoder().decode(
            NotificationChannelHypeTrainEndMessage.self,
            from: messageData
        )
        delegate.twitchEventSubChannelHypeTrainEnd(event: message.payload.event)
    }

    private func handleChannelAdBreakBegin(messageData: Data) throws {
        let message = try JSONDecoder().decode(
            NotificationChannelAdBreakBeginMessage.self,
            from: messageData
        )
        delegate.twitchEventSubChannelAdBreakBegin(event: message.payload.event)
    }
    
    // New handler for channel moderate events
    private func handleChannelModerate(messageData: Data) throws {
        do {
            let message = try JSONDecoder().decode(NotificationChannelModerateMessage.self, from: messageData)
            delegate.twitchEventSubChannelModerate(event: message)
        } catch {
            print("Decoding failed: \(error)")
            if let rawPayload = String(data: messageData, encoding: .utf8) {
                print("Raw Payload: \(rawPayload)")
            }
        }
    }
    
    private func handleSharedChatBegin(messageData: Data) throws {
        let message = try JSONDecoder().decode(NotificationSharedChatBeginMessage.self, from: messageData)
        delegate.twitchEventSubSharedChatBegin(event: message.payload.event)
    }

    private func handleSharedChatUpdate(messageData: Data) throws {
        let message = try JSONDecoder().decode(NotificationSharedChatUpdateMessage.self, from: messageData)
        delegate.twitchEventSubSharedChatUpdate(event: message.payload.event)
    }
    
    private func handleSharedChatEnd(messageData: Data) throws {
        let message = try JSONDecoder().decode(NotificationSharedChatEndMessage.self, from: messageData)
        delegate.twitchEventSubSharedChatEnd(event: message.payload.event)
    }
}

extension TwitchEventSub: WebSocketClientDelegate {
    func webSocketClientConnected(_: WebSocketClient) {
        connected = true
    }

    func webSocketClientDisconnected(_: WebSocketClient) {
        connected = false
    }

    func webSocketClientReceiveMessage(_: WebSocketClient, string: String) {
        logger.debug(string)
        handleMessage(messageText: string)
    }
}

extension TwitchEventSub: TwitchApiDelegate {
    func twitchApiUnauthorized() {
        delegate.twitchEventSubUnauthorized()
    }
}
