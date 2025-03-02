//
//  EventSubPayloads.swift
//  Moblin
//
//  Created by Andrew Beshay on 2/3/2025.
//

import Foundation

// Session and connection related payloads
struct EventSubSessionData: Codable {
    let id: String
    let status: String
    let connectedAt: String?
    let keepaliveTimeoutSeconds: Int?
    let reconnectUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case status
        case connectedAt = "connected_at"
        case keepaliveTimeoutSeconds = "keepalive_timeout_seconds"
        case reconnectUrl = "reconnect_url"
    }
}

struct EventSubWelcomePayload: Codable {
    let session: EventSubSessionData
}

struct EventSubWelcomeMessage: Codable {
    let metadata: EventSubMetadata
    let payload: EventSubWelcomePayload
}

struct EventSubReconnectPayload: Codable {
    let session: EventSubSessionData
}

struct EventSubReconnectMessage: Codable {
    let metadata: EventSubMetadata
    let payload: EventSubReconnectPayload
}

struct EventSubSubscriptionInfo: Codable {
    let id: String
    let status: String
    let type: String
    let version: String
    let condition: [String: String]
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case status
        case type
        case version
        case condition
        case createdAt = "created_at"
    }
}

struct EventSubRevocationPayload: Codable {
    let subscription: EventSubSubscriptionInfo
}

struct EventSubRevocationMessage: Codable {
    let metadata: EventSubMetadata
    let payload: EventSubRevocationPayload
}

// Common message structure
struct EventSubMessageText: Codable {
    let text: String
}
