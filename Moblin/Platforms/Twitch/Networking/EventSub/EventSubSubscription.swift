//
//  EventSubSubscription.swift
//  Moblin
//
//  Created by Andrew Beshay on 2/3/2025.
//

import Foundation

// MARK: - EventSubSubscriptionManager

/**
 Manages EventSub subscriptions through the Twitch API
 */
class EventSubSubscriptionManager {
    // MARK: Properties
    private let userId: String
    private let accessToken: String
    private let api: TwitchAPI
    
    // MARK: Initialization
    
    init(userId: String, accessToken: String) {
        self.userId = userId
        self.accessToken = accessToken
        self.api = TwitchAPI.shared
    }
    
    // MARK: Public Methods
    
    /// Get current active EventSub subscriptions
    /// - Parameter completion: Callback with array of subscription types
    func getExistingSubscriptions(completion: @escaping ([String]) -> Void) {
        api.eventSub.getEventSubSubscriptions { subscriptions, _, _, _ in
            guard let subscriptions = subscriptions else {
                logger.error("Failed to fetch existing EventSub subscriptions")
                completion([])
                return
            }
            
            // Extract all active subscription types
            let activeSubscriptionTypes = subscriptions
                .filter { $0.status == "enabled" }
                .map { $0.type }
            
            logger.info("Found \(activeSubscriptionTypes.count) active EventSub subscriptions")
            completion(activeSubscriptionTypes)
        }
    }
    
    /// Create a new subscription
    /// - Parameters:
    ///   - type: The subscription event type
    ///   - version: API version to use
    ///   - condition: Filtering conditions
    ///   - sessionId: WebSocket session ID
    ///   - completion: Result callback
    func subscribe(
        type: String,
        version: String,
        condition: [String: String],
        sessionId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        logger.info("Creating EventSub subscription for \(type)")
        
        // Create transport object for WebSocket
        let transport = TwitchApiEventSubTransport(
            method: "websocket",
            callback: nil,
            secret: nil,
            session_id: sessionId
        )
        
        // Create the subscription
        api.eventSub.createEventSubSubscription(
            type: type,
            version: version,
            condition: condition,
            transport: transport
        ) { subscriptions in
            if let subscriptions = subscriptions, !subscriptions.isEmpty {
                completion(.success(()))
            } else {
                let error = NSError(
                    domain: "EventSubSubscriptionManager",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to create subscription"]
                )
                completion(.failure(error))
            }
        }
    }
}
