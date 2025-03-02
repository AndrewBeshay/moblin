//
//  WebSocketManager.swift
//  Moblin
//
//  Created by Andrew Beshay on 2/3/2025.
//

import Foundation
import Combine

class NativeEventSubWebSocketManager: NSObject {
    // WebSocket and session objects
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession?
    private var isConnected = false
    private var reconnectTimer: Timer?
    private let apiToken: String
    
    // Cancellable storage for Combine subscriptions if needed
    private var cancellables = Set<AnyCancellable>()
    
    // Callback handlers for different event types
    var onFollowHandler: ((String) -> Void)?
    var onSubscriptionHandler: ((String) -> Void)?
    var onStreamStatusChangeHandler: ((Bool) -> Void)?
    
    init(apiToken: String) {
        self.apiToken = apiToken
        super.init()
        
        // Create URL session with the delegate set to self
        session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
    }
    
    func connect() {
        // Create the WebSocket URL
        guard let url = URL(string: "wss://eventsub.example.com/ws") else {
            print("Invalid URL")
            return
        }
        
        // Create the WebSocket task
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        
        webSocketTask = session?.webSocketTask(with: request)
        
        // Set up ping handler to keep connection alive
        setupPingHandler()
        
        // Start receiving messages
        receiveMessage()
        
        // Connect
        webSocketTask?.resume()
    }
    
    // Set up a periodic ping to keep the connection alive
    private func setupPingHandler() {
        // Send a ping every 30 seconds
        DispatchQueue.global().asyncAfter(deadline: .now() + 30) { [weak self] in
            guard let self = self, self.isConnected else { return }
            
            self.webSocketTask?.sendPing { error in
                if let error = error {
                    print("Error sending ping: \(error)")
                    self.handleDisconnection()
                } else {
                    // Ping successful, schedule next ping
                    self.setupPingHandler()
                }
            }
        }
    }
    
    // Handle receiving messages recursively
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                // Process the received message
                switch message {
                case .string(let text):
                    self.handleEventMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.handleEventMessage(text)
                    }
                @unknown default:
                    break
                }
                
                // Continue receiving messages (recursive call)
                self.receiveMessage()
                
            case .failure(let error):
                print("Error receiving message: \(error)")
                self.handleDisconnection()
            }
        }
    }
    
    // Handle incoming event messages
    private func handleEventMessage(_ message: String) {
        // Parse the JSON message
        guard let data = message.data(using: .utf8) else { return }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            
            // Check message type
            guard let metadata = json?["metadata"] as? [String: Any],
                  let messageType = metadata["message_type"] as? String else {
                return
            }
            
            // Route to appropriate handler based on event type
            switch messageType {
            case "notification":
                handleNotification(json)
            case "session_welcome":
                isConnected = true
                handleSessionWelcome(json)
                // Subscribe to events after connection is established
                subscribeToEvents()
            case "keepalive":
                // Just acknowledge keepalive
                print("Received keepalive")
            default:
                print("Unknown message type: \(messageType)")
            }
        } catch {
            print("Error parsing message: \(error.localizedDescription)")
        }
    }
    
    // Handle different notification types
    private func handleNotification(_ json: [String: Any]?) {
        guard let payload = json?["payload"] as? [String: Any],
              let event = payload["event"] as? [String: Any],
              let subscription = payload["subscription"] as? [String: Any],
              let type = subscription["type"] as? String else {
            return
        }
        
        // Route to the appropriate event handler
        switch type {
        case "channel.follow":
            if let username = event["user_name"] as? String {
                onFollowHandler?(username)
            }
        case "channel.subscribe":
            if let username = event["user_name"] as? String {
                onSubscriptionHandler?(username)
            }
        case "stream.online", "stream.offline":
            let isOnline = type == "stream.online"
            onStreamStatusChangeHandler?(isOnline)
        default:
            print("Unhandled event type: \(type)")
        }
    }
    
    // Process session welcome message (contains session ID)
    private func handleSessionWelcome(_ json: [String: Any]?) {
        guard let payload = json?["payload"] as? [String: Any],
              let session = payload["session"] as? [String: Any],
              let sessionId = session["id"] as? String else {
            return
        }
        
        print("Connected with session ID: \(sessionId)")
        // Store the session ID if needed for reconnection
    }
    
    // Subscribe to the events we're interested in
    private func subscribeToEvents() {
        // These would be actual API calls to the streaming platform
        // to register your interest in specific events
        let subscriptions = [
            ["type": "channel.follow", "version": "1"],
            ["type": "channel.subscribe", "version": "1"],
            ["type": "stream.online", "version": "1"],
            ["type": "stream.offline", "version": "1"]
        ]
        
        // Send subscription requests
        for subscription in subscriptions {
            sendSubscriptionRequest(subscription)
        }
    }
    
    // Send a subscription request for a specific event type
    private func sendSubscriptionRequest(_ subscription: [String: String]) {
        guard let type = subscription["type"], let version = subscription["version"] else {
            return
        }
        
        // Create subscription request payload
        let subscriptionRequest: [String: Any] = [
            "type": "subscription",
            "version": "1",
            "condition": [
                "broadcaster_user_id": "YOUR_CHANNEL_ID"
            ],
            "transport": [
                "method": "websocket"
            ]
        ]
        
        // In a real implementation, you'd make an HTTP request to register this subscription
        // using the session ID from the welcome message
    }
    
    // Send a message through the WebSocket
    func sendMessage(_ message: String) {
        webSocketTask?.send(.string(message)) { error in
            if let error = error {
                print("Error sending message: \(error)")
                self.handleDisconnection()
            }
        }
    }
    
    // Handle disconnection and reconnection
    private func handleDisconnection() {
        isConnected = false
        scheduleReconnect()
    }
    
    private func scheduleReconnect() {
        reconnectTimer?.invalidate()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            self?.connect()
        }
    }
    
    func disconnect() {
        reconnectTimer?.invalidate()
        
        // Send a close frame to gracefully close the connection
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
    }
}

// MARK: - URLSessionWebSocketDelegate
extension NativeEventSubWebSocketManager: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("WebSocket connection established")
        isConnected = true
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        isConnected = false
        
        if let reason = reason, let reasonString = String(data: reason, encoding: .utf8) {
            print("WebSocket closed with reason: \(reasonString)")
        } else {
            print("WebSocket closed with code: \(closeCode)")
        }
        
        scheduleReconnect()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("URLSession task completed with error: \(error)")
            isConnected = false
            scheduleReconnect()
        }
    }
}
