import Foundation

// MARK: - Base Message Types

struct TwitchEventSubBasicMetadata: Decodable {
    var message_type: String
    var subscription_type: String?
}

struct TwitchEventSubBasicMessage: Decodable {
    var metadata: TwitchEventSubBasicMetadata
}

// MARK: - Welcome Message Types

struct TwitchEventSubWelcomePayloadSession: Decodable {
    var id: String
}

struct TwitchEventSubWelcomePayload: Decodable {
    var session: TwitchEventSubWelcomePayloadSession
}

struct TwitchEventSubWelcomeMessage: Decodable {
    var payload: TwitchEventSubWelcomePayload
}

// MARK: - Message Types

struct TwitchEventSubMessage: Decodable {
    var text: String
}

// MARK: - Channel Subscribe Event

struct TwitchEventSubNotificationChannelSubscribeEvent: Decodable {
    var user_name: String
    var tier: String
    var is_gift: Bool

    func tierAsNumber() -> Int {
        return twitchTierAsNumber(tier: tier)
    }
}

struct TwitchEventSubNotificationChannelSubscribePayload: Decodable {
    var event: TwitchEventSubNotificationChannelSubscribeEvent
}

struct TwitchEventSubNotificationChannelSubscribeMessage: Decodable {
    var payload: TwitchEventSubNotificationChannelSubscribePayload
}

// MARK: - Channel Subscription Gift Event

struct TwitchEventSubNotificationChannelSubscriptionGiftEvent: Decodable {
    var user_name: String?
    var total: Int
    var tier: String

    func tierAsNumber() -> Int {
        return twitchTierAsNumber(tier: tier)
    }
}

struct TwitchEventSubNotificationChannelSubscriptionGiftPayload: Decodable {
    var event: TwitchEventSubNotificationChannelSubscriptionGiftEvent
}

struct TwitchEventSubNotificationChannelSubscriptionGiftMessage: Decodable {
    var payload: TwitchEventSubNotificationChannelSubscriptionGiftPayload
}

// MARK: - Channel Subscription Message Event

struct TwitchEventSubNotificationChannelSubscriptionMessageEvent: Decodable {
    var user_name: String
    var cumulative_months: Int
    var tier: String
    var message: TwitchEventSubMessage

    func tierAsNumber() -> Int {
        return twitchTierAsNumber(tier: tier)
    }
}

struct TwitchEventSubNotificationChannelSubscriptionMessagePayload: Decodable {
    var event: TwitchEventSubNotificationChannelSubscriptionMessageEvent
}

struct TwitchEventSubNotificationChannelSubscriptionMessageMessage: Decodable {
    var payload: TwitchEventSubNotificationChannelSubscriptionMessagePayload
}

// MARK: - Channel Follow Event

struct TwitchEventSubNotificationChannelFollowEvent: Decodable {
    var user_name: String
}

struct TwitchEventSubNotificationChannelFollowPayload: Decodable {
    var event: TwitchEventSubNotificationChannelFollowEvent
}

struct TwitchEventSubNotificationChannelFollowMessage: Decodable {
    var payload: TwitchEventSubNotificationChannelFollowPayload
}

// MARK: - Channel Points Custom Reward Redemption Add Event

struct TwitchEventSubNotificationChannelPointsCustomRewardRedemptionAddEventReward: Decodable {
    var id: String
    var title: String
    var cost: Int
    var prompt: String
}

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

struct TwitchEventSubNotificationChannelPointsCustomRewardRedemptionAddPayload: Decodable {
    var event: TwitchEventSubNotificationChannelPointsCustomRewardRedemptionAddEvent
}

struct TwitchEventSubNotificationChannelPointsCustomRewardRedemptionAddMessage: Decodable {
    var payload: TwitchEventSubNotificationChannelPointsCustomRewardRedemptionAddPayload
}

// MARK: - Channel Raid Event

struct TwitchEventSubChannelRaidEvent: Decodable {
    var from_broadcaster_user_name: String
    var viewers: Int
}

struct TwitchEventSubNotificationChannelRaidPayload: Decodable {
    var event: TwitchEventSubChannelRaidEvent
}

struct TwitchEventSubNotificationChannelRaidMessage: Decodable {
    var payload: TwitchEventSubNotificationChannelRaidPayload
}

// MARK: - Channel Cheer Event

struct TwitchEventSubChannelCheerEvent: Decodable {
    var user_name: String?
    var message: String
    var bits: Int
}

struct TwitchEventSubNotificationChannelCheerPayload: Decodable {
    var event: TwitchEventSubChannelCheerEvent
}

struct TwitchEventSubNotificationChannelCheerMessage: Decodable {
    var payload: TwitchEventSubNotificationChannelCheerPayload
}

// MARK: - Hype Train Events

struct TwitchEventSubChannelHypeTrainBeginEvent: Decodable {
    var progress: Int
    var goal: Int
    var level: Int
    var started_at: String
    var expires_at: String
}

struct TwitchEventSubNotificationChannelHypeTrainBeginPayload: Decodable {
    var event: TwitchEventSubChannelHypeTrainBeginEvent
}

struct TwitchEventSubNotificationChannelHypeTrainBeginMessage: Decodable {
    var payload: TwitchEventSubNotificationChannelHypeTrainBeginPayload
}

struct TwitchEventSubChannelHypeTrainProgressEvent: Decodable {
    var progress: Int
    var goal: Int
    var level: Int
    var started_at: String
    var expires_at: String
}

struct TwitchEventSubNotificationChannelHypeTrainProgressPayload: Decodable {
    var event: TwitchEventSubChannelHypeTrainProgressEvent
}

struct TwitchEventSubNotificationChannelHypeTrainProgressMessage: Decodable {
    var payload: TwitchEventSubNotificationChannelHypeTrainProgressPayload
}

struct TwitchEventSubChannelHypeTrainEndEvent: Decodable {
    var level: Int
    var started_at: String
    var ended_at: String
}

struct TwitchEventSubNotificationChannelHypeTrainEndPayload: Decodable {
    var event: TwitchEventSubChannelHypeTrainEndEvent
}

struct TwitchEventSubNotificationChannelHypeTrainEndMessage: Decodable {
    var payload: TwitchEventSubNotificationChannelHypeTrainEndPayload
}

// MARK: - Ad Break Begin Event

struct TwitchEventSubChannelAdBreakBeginEvent: Decodable {
    var duration_seconds: Int
    var is_automatic: Bool
}

struct TwitchEventSubNotificationChannelAdBreakBeginPayload: Decodable {
    var event: TwitchEventSubChannelAdBreakBeginEvent
}

struct TwitchEventSubNotificationChannelAdBreakBeginMessage: Decodable {
    var payload: TwitchEventSubNotificationChannelAdBreakBeginPayload
} 