import Foundation

/// Constants related to Twitch EventSub
enum TwitchEventSubConstants {
    /// WebSocket URL for EventSub connections
    static let websocketURL = URL(string: "wss://eventsub.wss.twitch.tv/ws")!
    
    /// Message types received from EventSub
    enum MessageType {
        static let welcome = "session_welcome"
        static let keepalive = "session_keepalive"
        static let notification = "notification"
        static let reconnect = "session_reconnect"
    }
    
    /// Subscription types for different events
    enum SubscriptionType {
        static let channelFollow = "channel.follow"
        static let channelSubscribe = "channel.subscribe"
        static let channelSubscriptionGift = "channel.subscription.gift"
        static let channelSubscriptionMessage = "channel.subscription.message"
        static let channelPointsCustomRewardRedemptionAdd = "channel.channel_points_custom_reward_redemption.add"
        static let channelRaid = "channel.raid"
        static let channelCheer = "channel.cheer"
        static let channelHypeTrainBegin = "channel.hype_train.begin"
        static let channelHypeTrainProgress = "channel.hype_train.progress"
        static let channelHypeTrainEnd = "channel.hype_train.end"
        static let channelAdBreakBegin = "channel.ad_break.begin"
        static let channelMessageDelete = "channel.chat.message_delete"
        static let channelModerate = "channel.moderate"
    }
} 