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
    public var message: String? // Only present in version 2
    public var deleted_at: String?
}

// User Timeout Event
public struct TwitchEventSubChannelUserTimeoutEvent: Decodable {
    public var broadcaster_user_id: String
    public var broadcaster_user_login: String
    public var broadcaster_user_name: String
    public var moderator_user_id: String
    public var moderator_user_login: String
    public var moderator_user_name: String
    public var target_user_id: String
    public var target_user_login: String
    public var target_user_name: String
    public var expires_at: String
    public var reason: String?
    public var ends_at: String
    public var duration_seconds: Int
}

// Moderation Action Event
public struct TwitchEventSubModerationActionEvent: Decodable {
    // Base fields
    public var broadcaster_user_id: String
    public var broadcaster_user_login: String
    public var broadcaster_user_name: String
    public var source_broadcaster_user_id: String?
    public var source_broadcaster_user_login: String?
    public var source_broadcaster_user_name: String?
    public var moderator_user_id: String
    public var moderator_user_login: String
    public var moderator_user_name: String
    public var action: String
    
    // Optional action-specific fields
    public var followers: ModerationFollowersData?
    public var slow: ModerationSlowData?
    public var vip: ModerationUserData?
    public var unvip: ModerationUserData?
    public var mod: ModerationUserData?
    public var unmod: ModerationUserData?
    public var ban: ModerationBanData?
    public var unban: ModerationUserData?
    public var timeout: ModerationTimeoutData?
    public var untimeout: ModerationUserData?
    public var raid: ModerationRaidData?
    public var unraid: ModerationUserData?
    public var delete: ModerationDeleteData?
    public var automod_terms: ModerationAutomodData?
    public var unban_request: ModerationUnbanRequestData?
    public var warn: ModerationWarnData?
    public var shared_chat_ban: ModerationBanData?
    public var shared_chat_unban: ModerationUserData?
    public var shared_chat_timeout: ModerationTimeoutData?
    public var shared_chat_untimeout: ModerationUserData?
    public var shared_chat_delete: ModerationDeleteData?
    
    // Nested data structures for specific action types
    public struct ModerationFollowersData: Decodable {
        public var follow_duration_minutes: Int
    }
    
    public struct ModerationSlowData: Decodable {
        public var wait_time_seconds: Int
    }
    
    public struct ModerationUserData: Decodable {
        public var user_id: String
        public var user_login: String
        public var user_name: String
    }
    
    public struct ModerationBanData: Decodable {
        public var user_id: String
        public var user_login: String
        public var user_name: String
        public var reason: String?
    }
    
    public struct ModerationTimeoutData: Decodable {
        public var user_id: String
        public var user_login: String
        public var user_name: String
        public var reason: String?
        public var expires_at: String
    }
    
    public struct ModerationRaidData: Decodable {
        public var user_id: String
        public var user_login: String
        public var user_name: String
        public var viewer_count: Int
    }
    
    public struct ModerationDeleteData: Decodable {
        public var user_id: String
        public var user_login: String
        public var user_name: String
        public var message_id: String
        public var message_body: String?
    }
    
    public struct ModerationAutomodData: Decodable {
        public var action: String // "add" or "remove"
        public var list: String // "blocked" or "permitted"
        public var terms: [String]
        public var from_automod: Bool
    }
    
    public struct ModerationUnbanRequestData: Decodable {
        public var is_approved: Bool
        public var user_id: String
        public var user_login: String
        public var user_name: String
        public var moderator_message: String?
    }
    
    public struct ModerationWarnData: Decodable {
        public var user_id: String
        public var user_login: String
        public var user_name: String
        public var reason: String?
        public var chat_rules_cited: [String]?
    }
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

public typealias TwitchEventSubChannelUserTimeoutMessage = 
    TwitchEventSubMessage<TwitchEventSubChannelUserTimeoutEvent>

public typealias TwitchEventSubModerationActionMessage = 
    TwitchEventSubMessage<TwitchEventSubModerationActionEvent> 