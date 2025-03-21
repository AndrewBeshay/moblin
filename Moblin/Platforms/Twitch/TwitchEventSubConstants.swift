import Foundation

// MARK: - EventSub Message Types
enum TwitchEventSubMessageType {
    static let sessionWelcome = "session_welcome"
    static let sessionKeepAlive = "session_keepalive"
    static let notification = "notification"
}

// MARK: - EventSub Subscription Types
enum TwitchEventSubSubscriptionType {
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
}

// MARK: - EventSub WebSocket URL
enum TwitchEventSubConfig {
    static let websocketURL = URL(string: "wss://eventsub.wss.twitch.tv/ws")!
} 