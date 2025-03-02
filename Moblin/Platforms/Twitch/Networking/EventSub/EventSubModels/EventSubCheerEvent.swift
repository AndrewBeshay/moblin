//
//  EventSubCheerEvent.swift
//  Moblin
//
//  Created by Andrew Beshay on 2/3/2025.
//

import Foundation

struct EventSubCheerEvent: Codable {
    let isAnonymous: Bool
    let userId: String?
    let userLogin: String?
    let userName: String?
    let broadcasterUserId: String
    let broadcasterUserLogin: String
    let broadcasterUserName: String
    let message: String
    let bits: Int
    
    enum CodingKeys: String, CodingKey {
        case isAnonymous = "is_anonymous"
        case userId = "user_id"
        case userLogin = "user_login"
        case userName = "user_name"
        case broadcasterUserId = "broadcaster_user_id"
        case broadcasterUserLogin = "broadcaster_user_login"
        case broadcasterUserName = "broadcaster_user_name"
        case message
        case bits
    }
}

struct EventSubCheerPayload: Codable {
    let subscription: EventSubSubscriptionInfo
    let event: EventSubCheerEvent
}

struct EventSubCheerMessage: Codable {
    let metadata: EventSubMetadata
    let payload: EventSubCheerPayload
}
