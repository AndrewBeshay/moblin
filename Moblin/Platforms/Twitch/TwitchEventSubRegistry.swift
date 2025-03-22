import Foundation

/// Errors that can occur during EventSub processing
enum TwitchEventSubError: Error {
    case unknownSubscriptionType(String)
    case decodingFailed(String)
    case noDelegate
}

/// Registry for Twitch EventSub message types
final class TwitchEventSubRegistry {
    // MARK: - Type Definitions
    
    /// Handler function type for processing events
    typealias EventHandler = (Any, TwitchEventSubDelegate) -> Void
    
    /// Structure to represent a registered event type
    private struct RegisteredType {
        let decoder: (Data) throws -> Any
        let handler: EventHandler
    }
    
    // MARK: - Properties
    
    /// Shared singleton instance
    static let shared = TwitchEventSubRegistry()
    
    /// Registry of event types and their processors
    private var registry: [String: RegisteredType] = [:]
    private let decoder = JSONDecoder()
    
    // MARK: - Initialization
    
    /// Private initializer for singleton pattern
    private init() {
        registerAllEventTypes()
    }
    
    // MARK: - Public Methods
    
    /// Process a message of a specific subscription type
    /// - Parameters:
    ///   - subscriptionType: The type of subscription event
    ///   - messageData: The raw message data
    ///   - delegate: The delegate to receive the processed event
    func handleMessage(subscriptionType: String, messageData: Data, delegate: TwitchEventSubDelegate) throws {
        // Look up the handler for this subscription type
        guard let registeredType = registry[subscriptionType] else {
            throw TwitchEventSubError.unknownSubscriptionType(subscriptionType)
        }
        
        do {
            // Decode and handle the event
            let event = try registeredType.decoder(messageData)
            registeredType.handler(event, delegate)
            
            // Additional notification to delegate that a message was processed
            delegate.twitchEventSubNotification(message: subscriptionType)
        } catch {
            throw TwitchEventSubError.decodingFailed("Failed to decode \(subscriptionType): \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private Methods
    
    /// Register a handler for a specific event type
    private func register<T: Decodable, E>(
        type: String,
        messageType: T.Type,
        eventExtractor: @escaping (T) -> E,
        handler: @escaping (E, TwitchEventSubDelegate) -> Void
    ) {
        registry[type] = RegisteredType(
            decoder: { [weak self] data in
                guard let self = self else { throw TwitchEventSubError.noDelegate }
                let message = try self.decoder.decode(messageType, from: data)
                return eventExtractor(message)
            },
            handler: { event, delegate in
                if let typedEvent = event as? E {
                    handler(typedEvent, delegate)
                }
            }
        )
    }
    
    /// Register all supported event types
    private func registerAllEventTypes() {
        // Channel Follow
        register(
            type: TwitchEventSubConstants.SubscriptionType.channelFollow,
            messageType: TwitchEventSubChannelFollowMessage.self,
            eventExtractor: { $0.payload.event }
        ) { event, delegate in
            delegate.twitchEventSubChannelFollow(event: event)
        }
        
        // Channel Subscribe
        register(
            type: TwitchEventSubConstants.SubscriptionType.channelSubscribe,
            messageType: TwitchEventSubChannelSubscribeMessage.self,
            eventExtractor: { $0.payload.event }
        ) { event, delegate in
            delegate.twitchEventSubChannelSubscribe(event: event)
        }
        
        // Channel Subscription Gift
        register(
            type: TwitchEventSubConstants.SubscriptionType.channelSubscriptionGift,
            messageType: TwitchEventSubChannelSubscriptionGiftMessage.self,
            eventExtractor: { $0.payload.event }
        ) { event, delegate in
            delegate.twitchEventSubChannelSubscriptionGift(event: event)
        }
        
        // Channel Subscription Message
        register(
            type: TwitchEventSubConstants.SubscriptionType.channelSubscriptionMessage,
            messageType: TwitchEventSubChannelSubscriptionMessageMessage.self,
            eventExtractor: { $0.payload.event }
        ) { event, delegate in
            delegate.twitchEventSubChannelSubscriptionMessage(event: event)
        }
        
        // Channel Points Custom Reward Redemption Add
        register(
            type: TwitchEventSubConstants.SubscriptionType.channelPointsCustomRewardRedemptionAdd,
            messageType: TwitchEventSubChannelPointsRedemptionMessage.self,
            eventExtractor: { $0.payload.event }
        ) { event, delegate in
            delegate.twitchEventSubChannelPointsCustomRewardRedemptionAdd(event: event)
        }
        
        // Channel Raid
        register(
            type: TwitchEventSubConstants.SubscriptionType.channelRaid,
            messageType: TwitchEventSubChannelRaidMessage.self,
            eventExtractor: { $0.payload.event }
        ) { event, delegate in
            delegate.twitchEventSubChannelRaid(event: event)
        }
        
        // Channel Cheer
        register(
            type: TwitchEventSubConstants.SubscriptionType.channelCheer,
            messageType: TwitchEventSubChannelCheerMessage.self,
            eventExtractor: { $0.payload.event }
        ) { event, delegate in
            delegate.twitchEventSubChannelCheer(event: event)
        }
        
        // Channel Hype Train Events
        register(
            type: TwitchEventSubConstants.SubscriptionType.channelHypeTrainBegin,
            messageType: TwitchEventSubChannelHypeTrainBeginMessage.self,
            eventExtractor: { $0.payload.event }
        ) { event, delegate in
            delegate.twitchEventSubChannelHypeTrainBegin(event: event)
        }
        
        register(
            type: TwitchEventSubConstants.SubscriptionType.channelHypeTrainProgress,
            messageType: TwitchEventSubChannelHypeTrainProgressMessage.self,
            eventExtractor: { $0.payload.event }
        ) { event, delegate in
            delegate.twitchEventSubChannelHypeTrainProgress(event: event)
        }
        
        register(
            type: TwitchEventSubConstants.SubscriptionType.channelHypeTrainEnd,
            messageType: TwitchEventSubChannelHypeTrainEndMessage.self,
            eventExtractor: { $0.payload.event }
        ) { event, delegate in
            delegate.twitchEventSubChannelHypeTrainEnd(event: event)
        }
        
        // Channel Ad Break Begin
        register(
            type: TwitchEventSubConstants.SubscriptionType.channelAdBreakBegin,
            messageType: TwitchEventSubChannelAdBreakBeginMessage.self,
            eventExtractor: { $0.payload.event }
        ) { event, delegate in
            delegate.twitchEventSubChannelAdBreakBegin(event: event)
        }
    }
} 