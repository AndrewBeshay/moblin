import Foundation

// MARK: - TwitchEventSub Delegate Protocol
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
}

// MARK: - WebSocketClient Protocol
protocol TwitchWebSocketClientProtocol {
    var delegate: WebSocketClientDelegate? { get set }
    init(url: URL, httpProxy: HttpProxy?)
    func start()
    func stop()
}

// MARK: - Use the existing WebSocketClientDelegate
// The protocol is already defined in Moblin/Various/WebSocketClient.swift
// No need to redefine it here to avoid ambiguity

// MARK: - TwitchEventSub Service Protocol
protocol TwitchEventSubServiceProtocol {
    var delegate: TwitchEventSubDelegate? { get set }
    func start()
    func stop()
    func isConnected() -> Bool
} 