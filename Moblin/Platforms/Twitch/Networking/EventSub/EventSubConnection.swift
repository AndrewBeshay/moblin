//
//  EventSubConnection.swift
//  Moblin
//
//  Created by Andrew Beshay on 2/3/2025.
//

import Foundation

// MARK: - EventSubConnection

/**
 Handles the WebSocket connection for EventSub
 */
class EventSubConnection {
    // MARK: Properties
    private let url: URL
    private let httpProxy: HttpProxy?
    private var webSocket: WebSocketClient
    
    weak var delegate: EventSubConnectionDelegate?
    
    // MARK: Initialization
    
    init(url: URL, httpProxy: HttpProxy? = nil) {
        self.url = url
        self.httpProxy = httpProxy
        self.webSocket = WebSocketClient(url: url, httpProxy: httpProxy)
    }
    
    // MARK: Public Methods
    
    /// Connect to the WebSocket server
    func connect() {
        webSocket.delegate = self
        webSocket.start()
    }
    
    /// Disconnect from the WebSocket server
    func disconnect() {
        webSocket.stop()
    }
    
    /// Reconnect to a different WebSocket URL (used for session transitions)
    func reconnect(to newUrl: URL) {
        disconnect()
        webSocket = WebSocketClient(url: newUrl, httpProxy: httpProxy)
        connect()
    }
    
    /// Check if the connection is active
    func isConnected() -> Bool {
        return webSocket.isConnected()
    }
}

// MARK: - WebSocketClientDelegate Implementation

extension EventSubConnection: WebSocketClientDelegate {
    func webSocketClientConnected(_ webSocket: WebSocketClient) {
        delegate?.websocketConnected()
    }
    
    func webSocketClientDisconnected(_ webSocket: WebSocketClient) {
        delegate?.websocketDisconnected()
    }
    
    func webSocketClientReceiveMessage(_ webSocket: WebSocketClient, string: String) {
        delegate?.websocketReceived(message: string)
    }
}

// MARK: - EventSubConnectionDelegate Protocol

protocol EventSubConnectionDelegate: AnyObject {
    func websocketConnected()
    func websocketDisconnected()
    func websocketReceived(message: String)
    func websocketError(_ error: Error)
}
