import Foundation

// MARK: - TwitchEventSub Model Definitions
// This file contains all event models used by the TwitchEventSub system.
// IMPORTANT: These models must be public to be available across the codebase

// MARK: - Base Message Types

/// Base metadata for all Twitch EventSub messages
public struct TwitchEventSubMetadata: Decodable {
    public var message_type: String
    public var subscription_type: String?
}

/// Generic payload container for all Twitch EventSub events
public struct TwitchEventSubPayload<T: Decodable>: Decodable {
    public var event: T
}

/// Generic message structure for all Twitch EventSub notifications
public struct TwitchEventSubMessage<T: Decodable>: Decodable {
    public var metadata: TwitchEventSubMetadata
    public var payload: TwitchEventSubPayload<T>
}

/// Welcome message for establishing a session
public struct TwitchEventSubWelcomeSession: Decodable {
    public var id: String
}

public struct TwitchEventSubWelcomePayload: Decodable {
    public var session: TwitchEventSubWelcomeSession
}

public struct TwitchEventSubWelcomeMessage: Decodable {
    public var metadata: TwitchEventSubMetadata
    public var payload: TwitchEventSubWelcomePayload
}

// MARK: - Common Types

public struct TwitchEventSubTextMessage: Decodable {
    public var text: String
}

// MARK: - Event Types

// Channel Subscribe Event
public struct TwitchEventSubChannelSubscribeEvent: Decodable {
    public var user_name: String
    public var tier: String
    public var is_gift: Bool

    public func tierAsNumber() -> Int {
        return twitchTierAsNumber(tier: tier)
    }
}

// Channel Subscription Gift Event
public struct TwitchEventSubChannelSubscriptionGiftEvent: Decodable {
    public var user_name: String?
    public var total: Int
    public var tier: String

    public func tierAsNumber() -> Int {
        return twitchTierAsNumber(tier: tier)
    }
}

// Channel Subscription Message Event
public struct TwitchEventSubChannelSubscriptionMessageEvent: Decodable {
    public var user_name: String
    public var cumulative_months: Int
    public var tier: String
    public var message: TwitchEventSubTextMessage

    public func tierAsNumber() -> Int {
        return twitchTierAsNumber(tier: tier)
    }
}

// Channel Follow Event
public struct TwitchEventSubChannelFollowEvent: Decodable {
    public var user_name: String
}

// Channel Points Custom Reward Redemption Add Event
public struct TwitchEventSubChannelPointsCustomRewardEvent: Decodable {
    public var id: String
    public var title: String
    public var cost: Int
    public var prompt: String
}

public struct TwitchEventSubChannelPointsRedemptionEvent: Decodable {
    public var id: String
    public var user_id: String
    public var user_login: String
    public var user_name: String
    public var broadcaster_user_id: String
    public var broadcaster_user_login: String
    public var broadcaster_user_name: String
    public var status: String
    public var reward: TwitchEventSubChannelPointsCustomRewardEvent
    public var redeemed_at: String
}

// Channel Raid Event
public struct TwitchEventSubChannelRaidEvent: Decodable {
    public var from_broadcaster_user_name: String
    public var viewers: Int
}

// Channel Cheer Event
public struct TwitchEventSubChannelCheerEvent: Decodable {
    public var user_name: String?
    public var message: String
    public var bits: Int
}

// Hype Train Events
public struct TwitchEventSubChannelHypeTrainBeginEvent: Decodable {
    public var progress: Int
    public var goal: Int
    public var level: Int
    public var started_at: String
    public var expires_at: String
}

public struct TwitchEventSubChannelHypeTrainProgressEvent: Decodable {
    public var progress: Int
    public var goal: Int
    public var level: Int
    public var started_at: String
    public var expires_at: String
}

public struct TwitchEventSubChannelHypeTrainEndEvent: Decodable {
    public var level: Int
    public var started_at: String
    public var ended_at: String
}

// Ad Break Begin Event
public struct TwitchEventSubChannelAdBreakBeginEvent: Decodable {
    public var duration_seconds: Int
    public var is_automatic: Bool
}

// Message Delete Event
public struct TwitchEventSubChannelMessageDeleteEvent: Decodable {
    public var broadcaster_user_id: String
    public var broadcaster_user_login: String
    public var broadcaster_user_name: String
    public var target_user_id: String
    public var target_user_login: String
    public var target_user_name: String
    public var message_id: String
}

// MARK: - Type Aliases for Complete Messages

public typealias TwitchEventSubChannelSubscribeMessage = 
    TwitchEventSubMessage<TwitchEventSubChannelSubscribeEvent>

public typealias TwitchEventSubChannelSubscriptionGiftMessage = 
    TwitchEventSubMessage<TwitchEventSubChannelSubscriptionGiftEvent>

public typealias TwitchEventSubChannelSubscriptionMessageMessage = 
    TwitchEventSubMessage<TwitchEventSubChannelSubscriptionMessageEvent>

public typealias TwitchEventSubChannelFollowMessage = 
    TwitchEventSubMessage<TwitchEventSubChannelFollowEvent>

public typealias TwitchEventSubChannelPointsRedemptionMessage = 
    TwitchEventSubMessage<TwitchEventSubChannelPointsRedemptionEvent>

public typealias TwitchEventSubChannelRaidMessage = 
    TwitchEventSubMessage<TwitchEventSubChannelRaidEvent>

public typealias TwitchEventSubChannelCheerMessage = 
    TwitchEventSubMessage<TwitchEventSubChannelCheerEvent>

public typealias TwitchEventSubChannelHypeTrainBeginMessage = 
    TwitchEventSubMessage<TwitchEventSubChannelHypeTrainBeginEvent>

public typealias TwitchEventSubChannelHypeTrainProgressMessage = 
    TwitchEventSubMessage<TwitchEventSubChannelHypeTrainProgressEvent>

public typealias TwitchEventSubChannelHypeTrainEndMessage = 
    TwitchEventSubMessage<TwitchEventSubChannelHypeTrainEndEvent>

public typealias TwitchEventSubChannelAdBreakBeginMessage = 
    TwitchEventSubMessage<TwitchEventSubChannelAdBreakBeginEvent>

public typealias TwitchEventSubChannelMessageDeleteMessage = 
    TwitchEventSubMessage<TwitchEventSubChannelMessageDeleteEvent> 