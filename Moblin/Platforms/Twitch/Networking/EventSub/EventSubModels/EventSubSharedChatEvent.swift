//
//  EventSubSharedChatEvent.swift
//  Moblin
//
//  Created by Andrew Beshay on 2/3/2025.
//

import Foundation

struct EventSubSharedChatParticipant: Codable {
    let broadcasterUserId: String
    let broadcasterUserLogin: String
    let broadcasterUserName: String
    
    enum CodingKeys: String, CodingKey {
        case broadcasterUserId = "broadcaster_user_id"
        case broadcasterUserLogin = "broadcaster_user_login"
        case broadcasterUserName = "broadcaster_user_name"
    }
}

struct EventSubSharedChatEvent: Codable {
    let sessionId: String
    let broadcasterUserId: String
    let broadcasterUserLogin: String
    let broadcasterUserName: String
    let hostBroadcasterUserId: String
    let hostBroadcasterUserLogin: String
    let hostBroadcasterUserName: String
    let participants: [EventSubSharedChatParticipant]?
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case broadcasterUserId = "broadcaster_user_id"
        case broadcasterUserLogin = "broadcaster_user_login"
        case broadcasterUserName = "broadcaster_user_name"
        case hostBroadcasterUserId = "host_broadcaster_user_id"
        case hostBroadcasterUserLogin = "host_broadcaster_user_login"
        case hostBroadcasterUserName = "host_broadcaster_user_name"
        case participants
    }
}

struct EventSubSharedChatBeginPayload: Codable {
    let subscription: EventSubSubscriptionInfo
    let event: EventSubSharedChatEvent
}

struct EventSubSharedChatBeginMessage: Codable {
    let metadata: EventSubMetadata
    let payload: EventSubSharedChatBeginPayload
}

struct EventSubSharedChatUpdatePayload: Codable {
    let subscription: EventSubSubscriptionInfo
    let event: EventSubSharedChatEvent
}

struct EventSubSharedChatUpdateMessage: Codable {
    let metadata: EventSubMetadata
    let payload: EventSubSharedChatUpdatePayload
}

struct EventSubSharedChatEndEvent: Codable {
    let sessionId: String
    let broadcasterUserId: String
    let broadcasterUserLogin: String
    let broadcasterUserName: String
    let hostBroadcasterUserId: String
    let hostBroadcasterUserLogin: String
    let hostBroadcasterUserName: String
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case broadcasterUserId = "broadcaster_user_id"
        case broadcasterUserLogin = "broadcaster_user_login"
        case broadcasterUserName = "broadcaster_user_name"
        case hostBroadcasterUserId = "host_broadcaster_user_id"
        case hostBroadcasterUserLogin = "host_broadcaster_user_login"
        case hostBroadcasterUserName = "host_broadcaster_user_name"
    }
}

struct EventSubSharedChatEndPayload: Codable {
    let subscription: EventSubSubscriptionInfo
    let event: EventSubSharedChatEndEvent
}

struct EventSubSharedChatEndMessage: Codable {
    let metadata: EventSubMetadata
    let payload: EventSubSharedChatEndPayload
}
