import Foundation
import SwiftUI

// MARK: - TwitchEventSub

final class TwitchEventSub: NSObject {
    // MARK: - Enum to track connection states
    private enum ConnectionState {
        case disconnected
        case connecting
        case connected
        case subscribing
        case ready
    }
    
    // MARK: - Properties
    private var webSocket: WebSocketClient
    private let userId: String
    private let httpProxy: HttpProxy?
    private var sessionId: String = ""
    private let twitchApi: TwitchApi
    private let delegate: TwitchEventSubDelegate
    private var subscriptionService: TwitchEventSubSubscriptionServiceProtocol
    private var eventHandler: TwitchEventSubHandlerProtocol
    
    // Settings
    private let maxReconnectAttempts = 5
    private let reconnectBackoffSeconds: [TimeInterval] = [1, 2, 5, 10, 15]
    
    // State tracking
    private var connectionState: ConnectionState = .disconnected {
        didSet {
            if oldValue != connectionState {
                logger.debug("twitch: event-sub: State changed from \(oldValue) to \(connectionState)")
            }
        }
    }
    private var isEnabled = false
    private var reconnectAttempts = 0
    private var reconnectTimer: DispatchSourceTimer?
    private var lastConnectTime: Date?
    private var stateOperationQueue = DispatchQueue(label: "com.moblin.twitch.eventsub", qos: .utility)
    
    // Used for debouncing
    private var operationLock = DispatchSemaphore(value: 1)
    private var pendingStartTask: DispatchWorkItem?
    private var pendingStopTask: DispatchWorkItem?
    
    // MARK: - Initialization
    init(
        userId: String,
        accessToken: String,
        httpProxy: HttpProxy?,
        urlSession: URLSession,
        delegate: TwitchEventSubDelegate
    ) {
        self.userId = userId
        self.httpProxy = httpProxy
        self.delegate = delegate
        
        // Initialize components
        twitchApi = TwitchApi(accessToken, urlSession)
        webSocket = WebSocketClient(
            url: TwitchEventSubConstants.websocketURL, 
            httpProxy: httpProxy,
            loopback: false,
            cellular: true
        )
        subscriptionService = TwitchEventSubSubscriptionService(twitchApi: twitchApi, delegate: delegate)
        eventHandler = TwitchEventSubHandler(delegate: delegate)
        
        super.init()
        twitchApi.delegate = self
    }
    
    deinit {
        pendingStartTask?.cancel()
        pendingStopTask?.cancel()
        cancelReconnectTimer()
        webSocket.delegate = nil
        webSocket.stop()
    }
    
    // MARK: - Public Methods
    
    /// Start the EventSub connection. This method is debounced.
    func start() {
        stateOperationQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Cancel any pending tasks
            self.pendingStopTask?.cancel()
            self.pendingStopTask = nil
            
            // If already starting, don't start again
            if self.pendingStartTask != nil {
                logger.debug("twitch: event-sub: Start already in progress, ignoring")
                return
            }
            
            // If already enabled, don't start again
            if self.isEnabled {
                logger.debug("twitch: event-sub: Already started, ignoring start request")
                return
            }
            
            // Create a debounced task
            let task = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                logger.debug("twitch: event-sub: Starting EventSub connection")
                
                self.operationLock.wait()
                self.isEnabled = true
                self.reconnectAttempts = 0
                self.connectionState = .disconnected
                self.pendingStartTask = nil
                self.operationLock.signal()
                
                self.connectWebSocket()
            }
            
            self.pendingStartTask = task
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: task)
        }
    }
    
    /// Stop the EventSub connection. This method is debounced.
    func stop() {
        stateOperationQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Cancel any pending tasks
            self.pendingStartTask?.cancel()
            self.pendingStartTask = nil
            
            // If already stopping, don't stop again
            if self.pendingStopTask != nil {
                logger.debug("twitch: event-sub: Stop already in progress, ignoring")
                return
            }
            
            // If already disabled, don't stop again
            if !self.isEnabled {
                logger.debug("twitch: event-sub: Already stopped, ignoring stop request")
                return
            }
            
            // Create a debounced task
            let task = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                logger.debug("twitch: event-sub: Stopping EventSub connection")
                
                self.operationLock.wait()
                self.isEnabled = false
                self.connectionState = .disconnected
                self.cancelReconnectTimer()
                self.webSocket.delegate = nil
                self.pendingStopTask = nil
                self.operationLock.signal()
                
                self.webSocket.stop()
            }
            
            self.pendingStopTask = task
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: task)
        }
    }
    
    /// Check if the connection is fully established and subscribed to events
    func isConnected() -> Bool {
        return connectionState == .ready
    }
    
    // MARK: - Private Methods
    
    /// Connect to the WebSocket
    private func connectWebSocket() {
        guard isEnabled, connectionState == .disconnected else {
            return
        }
        
        connectionState = .connecting
        lastConnectTime = Date()
        webSocket.delegate = self
        webSocket.start()
    }
    
    /// Handle reconnection with exponential backoff
    private func scheduleReconnect() {
        guard isEnabled, connectionState != .connecting else {
            return
        }
        
        // Calculate backoff time
        let backoffIndex = min(reconnectAttempts, reconnectBackoffSeconds.count - 1)
        let delay = reconnectBackoffSeconds[backoffIndex]
        
        logger.debug("twitch: event-sub: Scheduling reconnect attempt \(reconnectAttempts + 1) in \(delay) seconds")
        
        // Cancel any existing timer
        cancelReconnectTimer()
        
        // Schedule a new timer
        let timer = DispatchSource.makeTimerSource(queue: stateOperationQueue)
        timer.setEventHandler { [weak self] in
            guard let self = self, self.isEnabled else { return }
            
            self.reconnectAttempts += 1
            
            // If we've exceeded max attempts, notify the user
            if self.reconnectAttempts > self.maxReconnectAttempts {
                logger.error("twitch: event-sub: Exceeded maximum reconnection attempts")
                self.delegate.twitchEventSubMakeErrorToast(
                    title: String(localized: "Unable to establish Twitch notification connection")
                )
                // Reset but don't stop trying
                self.reconnectAttempts = 0
            }
            
            // Try to connect again
            self.connectionState = .disconnected
            self.connectWebSocket()
        }
        
        timer.schedule(deadline: .now() + delay)
        timer.activate()
        reconnectTimer = timer
    }
    
    /// Cancel any pending reconnect timer
    private func cancelReconnectTimer() {
        reconnectTimer?.cancel()
        reconnectTimer = nil
    }
    
    /// Process incoming messages from the WebSocket
    private func processMessage(_ messageText: String) {
        // For debugging
        if messageText.contains("session_welcome") {
            logger.debug("twitch: event-sub: Received welcome message")
        } else if messageText.contains("session_keepalive") {
            // Just a keepalive, no need to process
            return
        }
        
        // Let the event handler process normal notifications
        if eventHandler.handleMessage(messageText: messageText) {
            return
        }
        
        // Check if it's a welcome message with session ID
        let messageData = messageText.utf8Data
        if let sessionId = eventHandler.handleSessionWelcome(messageData: messageData) {
            self.sessionId = sessionId
            logger.debug("twitch: event-sub: Session established: \(sessionId)")
            
            // Change state and start subscribing to events
            connectionState = .subscribing
            subscribeToEvents()
        }
    }
    
    /// Subscribe to all Twitch event types
    private func subscribeToEvents() {
        logger.debug("twitch: event-sub: Starting subscription process")
        
        // Make sure we have a valid session ID
        guard !sessionId.isEmpty else {
            logger.error("twitch: event-sub: Cannot subscribe without session ID")
            connectionState = .disconnected
            scheduleReconnect()
            return
        }
        
        // Subscribe to all events
        subscriptionService.subscribe(sessionId: sessionId, userId: userId) { [weak self] success in
            guard let self = self else { return }
            
            if success {
                logger.debug("twitch: event-sub: Successfully subscribed to all events")
                self.connectionState = .ready
                self.reconnectAttempts = 0  // Reset on successful connection
            } else {
                logger.error("twitch: event-sub: Failed to subscribe to events")
                self.sessionId = ""
                self.connectionState = .disconnected
                self.scheduleReconnect()
            }
        }
    }
}

// MARK: - WebSocketClientDelegate
extension TwitchEventSub: WebSocketClientDelegate {
    func webSocketClientConnected(_: WebSocketClient) {
        stateOperationQueue.async { [weak self] in
            guard let self = self, self.isEnabled else { return }
            
            logger.debug("twitch: event-sub: WebSocket connected")
            self.lastConnectTime = Date()
            
            // Connected but waiting for welcome message with session ID
            // State will change to .subscribing once we get the session ID
            self.connectionState = .connected
        }
    }
    
    func webSocketClientDisconnected(_: WebSocketClient) {
        stateOperationQueue.async { [weak self] in
            guard let self = self, self.isEnabled else { return }
            
            logger.debug("twitch: event-sub: WebSocket disconnected")
            
            // Check if disconnection happened shortly after a connection
            if let lastConnect = self.lastConnectTime, 
               Date().timeIntervalSince(lastConnect) < 5 {
                // This might be a rapid disconnect-reconnect cycle
                logger.debug("twitch: event-sub: Rapid disconnect detected")
            }
            
            // Reset state and schedule reconnect
            self.connectionState = .disconnected
            self.scheduleReconnect()
        }
    }
    
    func webSocketClientReceiveMessage(_: WebSocketClient, string: String) {
        // Process messages on a background queue to avoid blocking the socket thread
        stateOperationQueue.async { [weak self] in
            guard let self = self, self.isEnabled else { return }
            self.processMessage(string)
        }
    }
}

// MARK: - TwitchApiDelegate
extension TwitchEventSub: TwitchApiDelegate {
    func twitchApiUnauthorized() {
        delegate.twitchEventSubUnauthorized()
    }
}
