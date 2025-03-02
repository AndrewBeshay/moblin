//
//  EventSubEvents.swift
//  Moblin
//
//  Created by Andrew Beshay on 2/3/2025.
//

import Foundation

struct EventSubSubscribeEvent: Codable {
    let userId: String
    let userLogin: String
    let userName: String
    let broadcasterUserId: String
    let broadcasterUserLogin: String
    let broadcasterUserName: String
    let tier: String
    let isGift: Bool
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case userLogin = "user_login"
        case userName = "user_name"
        case broadcasterUserId = "broadcaster_user_id"
        case broadcasterUserLogin = "broadcaster_user_login"
        case broadcasterUserName = "broadcaster_user_name"
        case tier
        case isGift = "is_gift"
    }
    
    func tierAsNumber() -> Int {
        switch tier {
        case "1000": return 1
        case "2000": return 2
        case "3000": return 3
        default: return 1
        }
    }
}

struct EventSubSubscribePayload: Codable {
    let subscription: EventSubSubscriptionInfo
    let event: EventSubSubscribeEvent
}

struct EventSubSubscribeMessage: Codable {
    let metadata: EventSubMetadata
    let payload: EventSubSubscribePayload
}

// Subscription Gift Event
struct EventSubSubscriptionGiftEvent: Codable {
    let userId: String?
    let userLogin: String?
    let userName: String?
    let broadcasterUserId: String
    let broadcasterUserLogin: String
    let broadcasterUserName: String
    let total: Int
    let tier: String
    let isAnonymous: Bool
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case userLogin = "user_login"
        case userName = "user_name"
        case broadcasterUserId = "broadcaster_user_id"
        case broadcasterUserLogin = "broadcaster_user_login"
        case broadcasterUserName = "broadcaster_user_name"
        case total
        case tier
        case isAnonymous = "is_anonymous"
    }
    
    func tierAsNumber() -> Int {
        switch tier {
        case "1000": return 1
        case "2000": return 2
        case "3000": return 3
        default: return 1
        }
    }
}

struct EventSubSubscriptionGiftPayload: Codable {
    let subscription: EventSubSubscriptionInfo
    let event: EventSubSubscriptionGiftEvent
}

struct EventSubSubscriptionGiftMessage: Codable {
    let metadata: EventSubMetadata
    let payload: EventSubSubscriptionGiftPayload
}

// Subscription Message Event
struct EventSubSubscriptionMessageEvent: Codable {
    let userId: String
    let userLogin: String
    let userName: String
    let broadcasterUserId: String
    let broadcasterUserLogin: String
    let broadcasterUserName: String
    let tier: String
    let message: EventSubMessageText
    let cumulativeMonths: Int
    let streakMonths: Int?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case userLogin = "user_login"
        case userName = "user_name"
        case broadcasterUserId = "broadcaster_user_id"
        case broadcasterUserLogin = "broadcaster_user_login"
        case broadcasterUserName = "broadcaster_user_name"
        case tier
        case message
        case cumulativeMonths = "cumulative_months"
        case streakMonths = "streak_months"
    }
    
    func tierAsNumber() -> Int {
        switch tier {
        case "1000": return 1
        case "2000": return 2
        case "3000": return 3
        default: return 1
        }
    }
}

struct EventSubSubscriptionMessagePayload: Codable {
    let subscription: EventSubSubscriptionInfo
    let event: EventSubSubscriptionMessageEvent
}

struct EventSubSubscriptionMessageMessage: Codable {
    let metadata: EventSubMetadata
    let payload: EventSubSubscriptionMessagePayload
}
