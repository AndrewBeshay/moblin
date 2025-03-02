//
//  EventSubFollowEvent.swift
//  Moblin
//
//  Created by Andrew Beshay on 2/3/2025.
//

import Foundation

struct EventSubFollowEvent: Codable {
    let userId: String
    let userLogin: String
    let userName: String
    let broadcasterUserId: String
    let broadcasterUserLogin: String
    let broadcasterUserName: String
    let followedAt: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case userLogin = "user_login"
        case userName = "user_name"
        case broadcasterUserId = "broadcaster_user_id"
        case broadcasterUserLogin = "broadcaster_user_login"
        case broadcasterUserName = "broadcaster_user_name"
        case followedAt = "followed_at"
    }
}

struct EventSubFollowPayload: Codable {
    let subscription: EventSubSubscriptionInfo
    let event: EventSubFollowEvent
}

struct EventSubFollowMessage: Codable {
    let metadata: EventSubMetadata
    let payload: EventSubFollowPayload
}
