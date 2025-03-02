//
//  EventSubManager.swift
//  Moblin
//
//  Created by Andrew Beshay on 2/3/2025.
//

import Foundation

// MARK: - EventSubManager

/**
 Main class responsible for managing Twitch EventSub WebSocket connections.
 Handles connection lifecycle, subscription management, and event parsing.
 */
class EventSubManager {
    // MARK: Properties
    private let userId: String
    private let accessToken: String
    private let httpProxy: HttpProxy?
    private var connection: EventSubConnection
    private var subscriptionManager: EventSubSubscriptionManager
    private weak var delegate: EventSubDelegate?
    
    private var sessionId: String = ""
    private var connectionActive = false
    
    // MARK: Initialization
    
    /**
     Initializes the EventSub manager
     
     - Parameters:
        - userId: The Twitch user ID to subscribe events for
        - accessToken: The Twitch API OAuth token
        - httpProxy: Optional HTTP proxy configuration
        - delegate: The delegate to receive events
     */
    init(userId: String, accessToken: String, httpProxy: HttpProxy? = nil, delegate: EventSubDelegate?) {
        self.userId = userId
        self.accessToken = accessToken
        self.httpProxy = httpProxy
        self.delegate = delegate
        
        // Initialize subscription manager
        self.subscriptionManager = EventSubSubscriptionManager(
            userId: userId,
            accessToken: accessToken
        )
        
        // Initialize WebSocket connection
        let url = URL(string: "wss://eventsub.wss.twitch.tv/ws")!
        self.connection = EventSubConnection(url: url, httpProxy: httpProxy)
        self.connection.delegate = self
    }
    
    // MARK: Public Methods
    
    /// Starts the EventSub connection
    func start() {
        logger.info("EventSub: Starting WebSocket connection")
        connection.connect()
    }
    
    /// Stops the EventSub connection
    func stop() {
        logger.info("EventSub: Stopping WebSocket connection")
        connection.disconnect()
        connectionActive = false
    }
    
    /// Returns whether the connection is established
    func isConnected() -> Bool {
        return connectionActive
    }
    
    /// Process a message received from a remote source (e.g., from remote control)
    func handleExternalMessage(messageText: String) {
        handleMessage(messageText: messageText)
    }
    
    // MARK: Private Methods
    
    /// Handles an incoming WebSocket message
    private func handleMessage(messageText: String) {
        let messageData = messageText.data(using: .utf8) ?? Data()
        
        do {
            // Decode the base message to determine its type
            let baseMessage = try JSONDecoder().decode(EventSubMessage.self, from: messageData)
            
            switch baseMessage.metadata.messageType {
            case .sessionWelcome:
                handleSessionWelcome(messageData: messageData)
                
            case .notification:
                handleNotification(baseMessage: baseMessage, messageData: messageData)
                
            case .sessionKeepAlive:
                // Just a keepalive - no action needed
                break
                
            case .reconnect:
                // Handle reconnect message
                handleReconnect(messageData: messageData)
                
            case .revocation:
                // Handle subscription revocation
                handleRevocation(messageData: messageData)
                
            case .unknown:
                logger.warning("EventSub: Unknown message type received")
            }
            
            // Forward the raw message to the delegate
            delegate?.eventSubNotification(message: messageText)
            
        } catch {
            logger.error("EventSub: Failed to decode message: \(error.localizedDescription)")
        }
    }
    
    /// Handles the welcome message and initiates subscriptions
    private func handleSessionWelcome(messageData: Data) {
        do {
            let welcomeMessage = try JSONDecoder().decode(EventSubWelcomeMessage.self, from: messageData)
            sessionId = welcomeMessage.payload.session.id
            connectionActive = true
            
            logger.info("EventSub: Connected with session ID: \(sessionId)")
            
            // Create subscriptions
            createSubscriptions()
            
        } catch {
            logger.error("EventSub: Failed to decode welcome message: \(error.localizedDescription)")
        }
    }
    
    /// Creates all event subscriptions
    private func createSubscriptions() {
        // First check existing subscriptions to avoid duplicates
        subscriptionManager.getExistingSubscriptions { [weak self] existingTypes in
            guard let self = self else { return }
            
            // Create a queue to handle subscription requests sequentially
            let subscriptionQueue = DispatchQueue(label: "com.moblin.eventsub.subscriptions")
            
            // Define the subscription types we want to have
            let desiredTypes: [EventSubSubscriptionType] = [
                .channelFollow,
                .channelSubscribe,
                .channelSubscriptionGift,
                .channelSubscriptionMessage,
                .channelCheer,
                .channelRaid,
                .channelModerate,
                .channelSharedChatBegin,
                .channelSharedChatUpdate,
                .channelSharedChatEnd
            ]
            
            // Subscribe to each type that isn't already active
            for type in desiredTypes {
                if !existingTypes.contains(type.rawValue) {
                    subscriptionQueue.async {
                        self.subscribeToEvent(type: type)
                    }
                }
            }
        }
    }
    
    /// Subscribes to a specific event type
    private func subscribeToEvent(type: EventSubSubscriptionType) {
        let condition: [String: String]
        
        // Build the appropriate condition based on event type
        switch type {
        case .channelRaid:
            condition = ["to_broadcaster_user_id": userId]
        default:
            condition = ["broadcaster_user_id": userId]
        }
        
        // For moderation events, we might need additional conditions
        var finalCondition = condition
        if type == .channelModerate {
            finalCondition["moderator_user_id"] = userId
        }
        
        // Create the subscription
        subscriptionManager.subscribe(
            type: type.rawValue,
            version: "1",
            condition: finalCondition,
            sessionId: sessionId
        ) { result in
            switch result {
            case .success:
                logger.info("EventSub: Successfully subscribed to \(type.rawValue)")
            case .failure(let error):
                logger.error("EventSub: Failed to subscribe to \(type.rawValue): \(error.localizedDescription)")
            }
        }
    }
    
    /// Handles notification messages by routing to appropriate handlers
    private func handleNotification(baseMessage: EventSubMessage, messageData: Data) {
        guard let subscriptionType = baseMessage.metadata.subscriptionType else {
            logger.warning("EventSub: Notification missing subscription type")
            return
        }
        
        // Route to the appropriate handler based on subscription type
        do {
            switch EventSubSubscriptionType(rawValue: subscriptionType) {
            case .channelFollow:
                let message = try JSONDecoder().decode(EventSubFollowMessage.self, from: messageData)
                delegate?.eventSubChannelFollow(event: message.payload.event)
                
            case .channelSubscribe:
                let message = try JSONDecoder().decode(EventSubSubscribeMessage.self, from: messageData)
                delegate?.eventSubChannelSubscribe(event: message.payload.event)
                
            case .channelSubscriptionGift:
                let message = try JSONDecoder().decode(EventSubSubscriptionGiftMessage.self, from: messageData)
                delegate?.eventSubChannelSubscriptionGift(event: message.payload.event)
                
            case .channelSubscriptionMessage:
                let message = try JSONDecoder().decode(EventSubSubscriptionMessageMessage.self, from: messageData)
                delegate?.eventSubChannelSubscriptionMessage(event: message.payload.event)
                
            case .channelRaid:
                let message = try JSONDecoder().decode(EventSubRaidMessage.self, from: messageData)
                delegate?.eventSubChannelRaid(event: message.payload.event)
                
            case .channelCheer:
                let message = try JSONDecoder().decode(EventSubCheerMessage.self, from: messageData)
                delegate?.eventSubChannelCheer(event: message.payload.event)
                
            case .channelModerate:
                let message = try JSONDecoder().decode(EventSubModerateMessage.self, from: messageData)
                delegate?.eventSubChannelModerate(event: message)
                
            case .channelSharedChatBegin:
                let message = try JSONDecoder().decode(EventSubSharedChatBeginMessage.self, from: messageData)
                delegate?.eventSubSharedChatBegin(event: message.payload.event)
                
            case .channelSharedChatUpdate:
                let message = try JSONDecoder().decode(EventSubSharedChatUpdateMessage.self, from: messageData)
                delegate?.eventSubSharedChatUpdate(event: message.payload.event)
                
            case .channelSharedChatEnd:
                let message = try JSONDecoder().decode(EventSubSharedChatEndMessage.self, from: messageData)
                delegate?.eventSubSharedChatEnd(event: message.payload.event)
                
            default:
                logger.warning("EventSub: Unhandled subscription type: \(subscriptionType)")
            }
        } catch {
            logger.error("EventSub: Failed to decode notification of type \(subscriptionType): \(error.localizedDescription)")
        }
    }
    
    /// Handles reconnect messages
    private func handleReconnect(messageData: Data) {
        // Parse the reconnect message
        do {
            let reconnectMessage = try JSONDecoder().decode(EventSubReconnectMessage.self, from: messageData)
            let reconnectUrl = reconnectMessage.payload.session.reconnectUrl
            
            logger.info("EventSub: Received reconnect request to URL: \(reconnectUrl)")
            
            // Reconnect using the provided URL
            if let url = URL(string: reconnectUrl ?? "") {
                connection.reconnect(to: url)
            }
        } catch {
            logger.error("EventSub: Failed to decode reconnect message: \(error.localizedDescription)")
        }
    }
    
    /// Handles subscription revocation messages
    private func handleRevocation(messageData: Data) {
        do {
            let revocationMessage = try JSONDecoder().decode(EventSubRevocationMessage.self, from: messageData)
            let subscriptionType = revocationMessage.payload.subscription.type
            let reason = revocationMessage.payload.subscription.status
            
            logger.warning("EventSub: Subscription \(subscriptionType) was revoked: \(reason)")
            
            // Re-subscribe if appropriate
            let type = EventSubSubscriptionType(rawValue: subscriptionType)
            if let validType = type {
                subscribeToEvent(type: validType)
            }
        } catch {
            logger.error("EventSub: Failed to decode revocation message: \(error.localizedDescription)")
        }
    }
}

// MARK: - EventSubConnectionDelegate

extension EventSubManager: EventSubConnectionDelegate {
    func websocketConnected() {
        logger.info("EventSub: WebSocket connected")
        connectionActive = true
    }
    
    func websocketDisconnected() {
        logger.info("EventSub: WebSocket disconnected")
        connectionActive = false
        
        // Attempt to reconnect after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            self?.start()
        }
    }
    
    func websocketReceived(message: String) {
        handleMessage(messageText: message)
    }
    
    func websocketError(_ error: Error) {
        logger.error("EventSub: WebSocket error: \(error.localizedDescription)")
        delegate?.eventSubMakeErrorToast(title: "WebSocket error: \(error.localizedDescription)")
    }
}
