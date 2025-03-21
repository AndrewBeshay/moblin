import Foundation

// MARK: - EventSub Handler Protocol
protocol TwitchEventSubHandlerProtocol {
    var delegate: TwitchEventSubDelegate? { get }
    func handleMessage(messageText: String) -> Bool
    func handleSessionWelcome(messageData: Data) -> String?
}

final class TwitchEventSubHandler: TwitchEventSubHandlerProtocol {
    // MARK: - Properties
    private(set) weak var delegate: TwitchEventSubDelegate?
    
    // MARK: - Initialization
    init(delegate: TwitchEventSubDelegate) {
        self.delegate = delegate
    }
    
    // MARK: - Public Methods
    func handleMessage(messageText: String) -> Bool {
        let messageData = messageText.utf8Data
        guard let message = try? JSONDecoder().decode(TwitchEventSubBasicMessage.self, from: messageData) else {
            return false
        }
        
        switch message.metadata.message_type {
        case TwitchEventSubMessageType.sessionWelcome:
            _ = handleSessionWelcome(messageData: messageData)
            return true
        case TwitchEventSubMessageType.sessionKeepAlive:
            return true
        case TwitchEventSubMessageType.notification:
            handleNotification(message: message, messageText: messageText, messageData: messageData)
            return true
        default:
            logger.info("twitch: event-sub: Unknown message type \(message.metadata.message_type)")
            return false
        }
    }
    
    func handleSessionWelcome(messageData: Data) -> String? {
        guard let message = try? JSONDecoder().decode(TwitchEventSubWelcomeMessage.self, from: messageData) else {
            logger.info("twitch: event-sub: Failed to decode welcome message")
            return nil
        }
        return message.payload.session.id
    }
    
    // MARK: - Private Methods
    private func handleNotification(message: TwitchEventSubBasicMessage, messageText: String, messageData: Data) {
        do {
            switch message.metadata.subscription_type {
            case TwitchEventSubSubscriptionType.channelFollow:
                try handleNotificationChannelFollow(messageData: messageData)
            case TwitchEventSubSubscriptionType.channelSubscribe:
                try handleNotificationChannelSubscribe(messageData: messageData)
            case TwitchEventSubSubscriptionType.channelSubscriptionGift:
                try handleNotificationChannelSubscriptionGift(messageData: messageData)
            case TwitchEventSubSubscriptionType.channelSubscriptionMessage:
                try handleNotificationChannelSubscriptionMessage(messageData: messageData)
            case TwitchEventSubSubscriptionType.channelPointsCustomRewardRedemptionAdd:
                try handleChannelPointsCustomRewardRedemptionAdd(messageData: messageData)
            case TwitchEventSubSubscriptionType.channelRaid:
                try handleChannelRaid(messageData: messageData)
            case TwitchEventSubSubscriptionType.channelCheer:
                try handleChannelCheer(messageData: messageData)
            case TwitchEventSubSubscriptionType.channelHypeTrainBegin:
                try handleChannelHypeTrainBegin(messageData: messageData)
            case TwitchEventSubSubscriptionType.channelHypeTrainProgress:
                try handleChannelHypeTrainProgress(messageData: messageData)
            case TwitchEventSubSubscriptionType.channelHypeTrainEnd:
                try handleChannelHypeTrainEnd(messageData: messageData)
            case TwitchEventSubSubscriptionType.channelAdBreakBegin:
                try handleChannelAdBreakBegin(messageData: messageData)
            default:
                if let type = message.metadata.subscription_type {
                    logger.info("twitch: event-sub: Unknown notification type \(type)")
                } else {
                    logger.info("twitch: event-sub: Missing notification type")
                }
            }
            delegate?.twitchEventSubNotification(message: messageText)
        } catch {
            let subscription_type = message.metadata.subscription_type ?? "unknown"
            logger.info("twitch: event-sub: Failed to handle notification \(subscription_type).")
        }
    }
    
    // MARK: - Event Handlers
    private func handleNotificationChannelFollow(messageData: Data) throws {
        let message = try JSONDecoder().decode(
            TwitchEventSubNotificationChannelFollowMessage.self,
            from: messageData
        )
        delegate?.twitchEventSubChannelFollow(event: message.payload.event)
    }
    
    private func handleNotificationChannelSubscribe(messageData: Data) throws {
        let message = try JSONDecoder().decode(
            TwitchEventSubNotificationChannelSubscribeMessage.self,
            from: messageData
        )
        delegate?.twitchEventSubChannelSubscribe(event: message.payload.event)
    }
    
    private func handleNotificationChannelSubscriptionGift(messageData: Data) throws {
        let message = try JSONDecoder().decode(
            TwitchEventSubNotificationChannelSubscriptionGiftMessage.self,
            from: messageData
        )
        delegate?.twitchEventSubChannelSubscriptionGift(event: message.payload.event)
    }
    
    private func handleNotificationChannelSubscriptionMessage(messageData: Data) throws {
        let message = try JSONDecoder().decode(
            TwitchEventSubNotificationChannelSubscriptionMessageMessage.self,
            from: messageData
        )
        delegate?.twitchEventSubChannelSubscriptionMessage(event: message.payload.event)
    }
    
    private func handleChannelPointsCustomRewardRedemptionAdd(messageData: Data) throws {
        let message = try JSONDecoder().decode(
            TwitchEventSubNotificationChannelPointsCustomRewardRedemptionAddMessage.self,
            from: messageData
        )
        delegate?.twitchEventSubChannelPointsCustomRewardRedemptionAdd(event: message.payload.event)
    }
    
    private func handleChannelRaid(messageData: Data) throws {
        let message = try JSONDecoder().decode(
            TwitchEventSubNotificationChannelRaidMessage.self,
            from: messageData
        )
        delegate?.twitchEventSubChannelRaid(event: message.payload.event)
    }
    
    private func handleChannelCheer(messageData: Data) throws {
        let message = try JSONDecoder().decode(
            TwitchEventSubNotificationChannelCheerMessage.self,
            from: messageData
        )
        delegate?.twitchEventSubChannelCheer(event: message.payload.event)
    }
    
    private func handleChannelHypeTrainBegin(messageData: Data) throws {
        let message = try JSONDecoder().decode(
            TwitchEventSubNotificationChannelHypeTrainBeginMessage.self,
            from: messageData
        )
        delegate?.twitchEventSubChannelHypeTrainBegin(event: message.payload.event)
    }
    
    private func handleChannelHypeTrainProgress(messageData: Data) throws {
        let message = try JSONDecoder().decode(
            TwitchEventSubNotificationChannelHypeTrainProgressMessage.self,
            from: messageData
        )
        delegate?.twitchEventSubChannelHypeTrainProgress(event: message.payload.event)
    }
    
    private func handleChannelHypeTrainEnd(messageData: Data) throws {
        let message = try JSONDecoder().decode(
            TwitchEventSubNotificationChannelHypeTrainEndMessage.self,
            from: messageData
        )
        delegate?.twitchEventSubChannelHypeTrainEnd(event: message.payload.event)
    }
    
    private func handleChannelAdBreakBegin(messageData: Data) throws {
        let message = try JSONDecoder().decode(
            TwitchEventSubNotificationChannelAdBreakBeginMessage.self,
            from: messageData
        )
        delegate?.twitchEventSubChannelAdBreakBegin(event: message.payload.event)
    }
} 