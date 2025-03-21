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
protocol WebSocketClientProtocol {
    var delegate: WebSocketClientDelegate? { get set }
    init(url: URL, httpProxy: HttpProxy?)
    func start()
    func stop()
}

// MARK: - WebSocketClient Delegate
protocol WebSocketClientDelegate: AnyObject {
    func webSocketClientConnected(_ client: WebSocketClient)
    func webSocketClientDisconnected(_ client: WebSocketClient)
    func webSocketClientReceiveMessage(_ client: WebSocketClient, string: String)
}

// MARK: - TwitchEventSub Service Protocol
protocol TwitchEventSubServiceProtocol {
    var delegate: TwitchEventSubDelegate? { get set }
    func start()
    func stop()
    func isConnected() -> Bool
} 