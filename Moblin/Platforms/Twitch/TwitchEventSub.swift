import Foundation

// Import the models file to ensure models are available
import SwiftUI

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

// MARK: - Private Payload Types

private struct NotificationChannelSubscribePayload: Decodable {
    var event: TwitchEventSubNotificationChannelSubscribeEvent
}

private struct NotificationChannelSubscribeMessage: Decodable {
    var payload: NotificationChannelSubscribePayload
}

private struct NotificationChannelAdBreakBeginPayload: Decodable {
    var event: TwitchEventSubChannelAdBreakBeginEvent
}

private struct NotificationChannelAdBreakBeginMessage: Decodable {
    var payload: NotificationChannelAdBreakBeginPayload
}

// MARK: - Constants

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

// MARK: - TwitchEventSub

final class TwitchEventSub: NSObject {
    // MARK: - Properties
    private var webSocket: WebSocketClient
    private var remoteControl: Bool
    private let userId: String
    private let httpProxy: HttpProxy?
    private var sessionId: String = ""
    private var twitchApi: TwitchApi
    private let delegate: TwitchEventSubDelegate
    private var connected = false
    private var started = false
    private var subscriptionService: TwitchEventSubSubscriptionServiceProtocol
    private var eventHandler: TwitchEventSubHandlerProtocol
    
    // MARK: - Initialization
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
        
        twitchApi = TwitchApi(accessToken, urlSession)
        webSocket = WebSocketClient(url: TwitchEventSubConfig.websocketURL, httpProxy: httpProxy)
        
        // Initialize services after all properties are set
        subscriptionService = TwitchEventSubSubscriptionService(twitchApi: twitchApi, delegate: delegate)
        eventHandler = TwitchEventSubHandler(delegate: delegate)
        
        super.init()
        twitchApi.delegate = self
    }
    
    // MARK: - Public Methods
    func start() {
        logger.debug("twitch: event-sub: Start")
        stopInternal()
        connect()
        started = true
    }
    
    func stop() {
        logger.debug("twitch: event-sub: Stop")
        webSocket.delegate = nil
        started = false
        stopInternal()
    }
    
    func isConnected() -> Bool {
        return connected
    }
    
    // MARK: - Private Methods
    private func connect() {
        connected = false
        webSocket = WebSocketClient(url: TwitchEventSubConfig.websocketURL, httpProxy: httpProxy)
        webSocket.delegate = self
        if !remoteControl {
            webSocket.start()
        }
    }
    
    private func stopInternal() {
        connected = false
        webSocket.stop()
    }
    
    private func handleMessage(messageText: String) {
        // Use the event handler to process the message
        if eventHandler.handleMessage(messageText: messageText) {
            return
        }
        
        // If the event handler could not process the message, extract the session ID if it's a welcome message
        let messageData = messageText.utf8Data
        if let sessionId = eventHandler.handleSessionWelcome(messageData: messageData) {
            self.sessionId = sessionId
            // Start subscription process
            subscribeToEvents()
        }
    }
    
    private func subscribeToEvents() {
        // Use the subscription service to handle all subscriptions
        subscriptionService.subscribe(sessionId: sessionId, userId: userId) { [weak self] success in
            guard let self = self, success else {
                return
            }
            self.connected = true
        }
    }
}

// MARK: - WebSocketClientDelegate
extension TwitchEventSub: WebSocketClientDelegate {
    func webSocketClientConnected(_: WebSocketClient) {}
    
    func webSocketClientDisconnected(_: WebSocketClient) {
        connected = false
    }
    
    func webSocketClientReceiveMessage(_: WebSocketClient, string: String) {
        handleMessage(messageText: string)
    }
}

// MARK: - TwitchApiDelegate
extension TwitchEventSub: TwitchApiDelegate {
    func twitchApiUnauthorized() {
        delegate.twitchEventSubUnauthorized()
    }
}
