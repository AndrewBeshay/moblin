import Foundation

// MARK: - Subscription Service Protocol
protocol TwitchEventSubSubscriptionServiceProtocol {
    func subscribe(sessionId: String, userId: String, completion: @escaping (Bool) -> Void)
}

/// Service to manage EventSub subscriptions with Twitch API
final class TwitchEventSubSubscriptionService: TwitchEventSubSubscriptionServiceProtocol {
    // MARK: - Properties
    private let twitchApi: TwitchApi
    private weak var delegate: TwitchEventSubDelegate?
    private let subscriptionTypes: [(type: String, version: Int, customCondition: ((String) -> String)?)]
    
    // MARK: - Initialization
    init(twitchApi: TwitchApi, delegate: TwitchEventSubDelegate?) {
        self.twitchApi = twitchApi
        self.delegate = delegate
        
        // Define all subscription types with their versions and any custom conditions
        subscriptionTypes = [
            // Follow events (version 2 needs moderator_user_id)
            (TwitchEventSubConstants.SubscriptionType.channelFollow, 2, { userId in
                "{\"broadcaster_user_id\":\"\(userId)\",\"moderator_user_id\":\"\(userId)\"}"
            }),
            
            // Standard broadcaster-only events (version 1)
            (TwitchEventSubConstants.SubscriptionType.channelSubscribe, 1, nil),
            (TwitchEventSubConstants.SubscriptionType.channelSubscriptionGift, 1, nil),
            (TwitchEventSubConstants.SubscriptionType.channelSubscriptionMessage, 1, nil),
            (TwitchEventSubConstants.SubscriptionType.channelPointsCustomRewardRedemptionAdd, 1, nil),
            (TwitchEventSubConstants.SubscriptionType.channelCheer, 1, nil),
            (TwitchEventSubConstants.SubscriptionType.channelHypeTrainBegin, 1, nil),
            (TwitchEventSubConstants.SubscriptionType.channelHypeTrainProgress, 1, nil),
            (TwitchEventSubConstants.SubscriptionType.channelHypeTrainEnd, 1, nil),
            (TwitchEventSubConstants.SubscriptionType.channelAdBreakBegin, 1, nil),
            
            // Message delete event (version 2 gets message content)
            (TwitchEventSubConstants.SubscriptionType.channelMessageDelete, 1, { userId in
                "{\"broadcaster_user_id\":\"\(userId)\",\"user_id\":\"\(userId)\"}"
            }),
            
            // Raid events need a different condition (to_broadcaster_user_id)
            (TwitchEventSubConstants.SubscriptionType.channelRaid, 1, { userId in
                "{\"to_broadcaster_user_id\":\"\(userId)\"}"
            })
        ]
    }
    
    // MARK: - Public Methods
    
    /// Subscribe to all EventSub events
    /// - Parameters:
    ///   - sessionId: The active WebSocket session ID
    ///   - userId: The broadcaster's user ID
    ///   - completion: Called with true if all subscriptions were successful, false otherwise
    func subscribe(sessionId: String, userId: String, completion: @escaping (Bool) -> Void) {
        Task {
            do {
                var success = true
                
                // Subscribe to each event type
                for subscription in subscriptionTypes {
                    let condition: String
                    
                    // Use custom condition if provided, otherwise use standard broadcaster_user_id
                    if let customCondition = subscription.customCondition {
                        condition = customCondition(userId)
                    } else {
                        condition = "{\"broadcaster_user_id\":\"\(userId)\"}"
                    }
                    
                    // Create the subscription payload
                    let subscriptionBody = createSubscriptionBody(
                        type: subscription.type,
                        version: subscription.version,
                        condition: condition,
                        sessionId: sessionId
                    )
                    
                    // Create the subscription
                    let subscribeResult = try await createSubscription(body: subscriptionBody)
                    
                    // Report error if subscription failed
                    if !subscribeResult {
                        logger.error("twitch: event-sub: Failed to subscribe to \(subscription.type)")
                        notifyErrorIfNeeded(eventType: getReadableName(for: subscription.type))
                        success = false
                    }
                }
                
                // Call completion on main thread
                DispatchQueue.main.async {
                    completion(success)
                }
            } catch {
                logger.error("twitch: event-sub: Error during subscription process: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Create a subscription using the Twitch API
    /// - Parameter body: The subscription request body
    /// - Returns: True if successful, false otherwise
    private func createSubscription(body: String) async throws -> Bool {
        return await withCheckedContinuation { continuation in
            twitchApi.createEventSubSubscription(body: body) { success in
                continuation.resume(returning: success)
            }
        }
    }
    
    /// Create the JSON body for a subscription request
    private func createSubscriptionBody(type: String, version: Int, condition: String, sessionId: String) -> String {
        return """
        {
            "type": "\(type)",
            "version": "\(version)",
            "condition": \(condition),
            "transport": {
                "method": "websocket",
                "session_id": "\(sessionId)"
            }
        }
        """
    }
    
    /// Notify the user of subscription errors
    private func notifyErrorIfNeeded(eventType: String) {
        delegate?.twitchEventSubMakeErrorToast(
            title: String(localized: "Failed to subscribe to Twitch \(eventType) event")
        )
    }
    
    /// Convert subscription type to human-readable name
    private func getReadableName(for subscriptionType: String) -> String {
        switch subscriptionType {
        case TwitchEventSubConstants.SubscriptionType.channelFollow:
            return "follow"
        case TwitchEventSubConstants.SubscriptionType.channelSubscribe:
            return "subscription"
        case TwitchEventSubConstants.SubscriptionType.channelSubscriptionGift:
            return "subscription gift"
        case TwitchEventSubConstants.SubscriptionType.channelSubscriptionMessage:
            return "subscription message"
        case TwitchEventSubConstants.SubscriptionType.channelPointsCustomRewardRedemptionAdd:
            return "reward redemption"
        case TwitchEventSubConstants.SubscriptionType.channelRaid:
            return "raid"
        case TwitchEventSubConstants.SubscriptionType.channelCheer:
            return "cheer"
        case TwitchEventSubConstants.SubscriptionType.channelHypeTrainBegin:
            return "hype train begin"
        case TwitchEventSubConstants.SubscriptionType.channelHypeTrainProgress:
            return "hype train progress"
        case TwitchEventSubConstants.SubscriptionType.channelHypeTrainEnd:
            return "hype train end"
        case TwitchEventSubConstants.SubscriptionType.channelAdBreakBegin:
            return "ad break"
        case TwitchEventSubConstants.SubscriptionType.channelMessageDelete:
            return "message delete"
        default:
            return subscriptionType
        }
    }
} 
