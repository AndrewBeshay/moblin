import Foundation

// MARK: - EventSub Handler Protocol
protocol TwitchEventSubHandlerProtocol {
    var delegate: TwitchEventSubDelegate? { get }
    func handleMessage(messageText: String) -> Bool
    func handleSessionWelcome(messageData: Data) -> String?
}

/// Handler for processing Twitch EventSub messages and dispatching them to the appropriate delegates
final class TwitchEventSubHandler: TwitchEventSubHandlerProtocol {
    // MARK: - Properties
    private(set) weak var delegate: TwitchEventSubDelegate?
    private let decoder = JSONDecoder()
    private let registry: TwitchEventSubRegistry
    
    // MARK: - Initialization
    init(delegate: TwitchEventSubDelegate, registry: TwitchEventSubRegistry = TwitchEventSubRegistry.shared) {
        self.delegate = delegate
        self.registry = registry
    }
    
    // MARK: - Public Methods
    
    /// Handle an incoming message from the WebSocket
    /// - Parameter messageText: The message text to process
    /// - Returns: true if the message was processed, false if it requires further handling
    func handleMessage(messageText: String) -> Bool {
        // First, try to decode the basic message structure to determine message type
        guard let messageData = messageText.data(using: .utf8) else {
            logger.error("twitch: event-sub: Could not convert message to data")
            return false
        }
        
        do {
            let message = try decoder.decode(TwitchEventSubMessage<EmptyEvent>.self, from: messageData)
            
            switch message.metadata.message_type {
            case TwitchEventSubConstants.MessageType.welcome:
                // Welcome messages are handled separately
                return false
                
            case TwitchEventSubConstants.MessageType.keepalive:
                // Keepalive messages don't need further processing
                return true
                
            case TwitchEventSubConstants.MessageType.notification:
                guard let subscriptionType = message.metadata.subscription_type else {
                    logger.error("twitch: event-sub: Missing subscription type in notification")
                    return false
                }
                
                // Use the registry to handle this event type
                return handleNotification(subscriptionType: subscriptionType, messageData: messageData)
                
            default:
                logger.debug("twitch: event-sub: Unknown message type: \(message.metadata.message_type)")
                return false
            }
        } catch {
            logger.error("twitch: event-sub: Failed to decode message: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Extract session ID from a welcome message
    /// - Parameter messageData: The raw message data
    /// - Returns: The session ID if found, nil otherwise
    func handleSessionWelcome(messageData: Data) -> String? {
        do {
            let message = try decoder.decode(TwitchEventSubWelcomeMessage.self, from: messageData)
            return message.payload.session.id
        } catch {
            logger.error("twitch: event-sub: Failed to decode welcome message: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    /// Handle an event notification
    /// - Parameters:
    ///   - subscriptionType: The type of notification
    ///   - messageData: The raw message data
    /// - Returns: true if successfully handled, false otherwise
    private func handleNotification(subscriptionType: String, messageData: Data) -> Bool {
        guard let delegate = delegate else {
            logger.error("twitch: event-sub: No delegate available to handle notification")
            return false
        }
        
        do {
            // Use the registry to process this event type
            try registry.handleMessage(subscriptionType: subscriptionType, messageData: messageData, delegate: delegate)
            return true
        } catch {
            logger.error("twitch: event-sub: Failed to handle notification: \(error.localizedDescription)")
            return false
        }
    }
}

// Empty struct used for parsing messages without needing the full event data
private struct EmptyEvent: Decodable {} 