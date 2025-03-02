//
//  EventSubRaidEvent.swift
//  Moblin
//
//  Created by Andrew Beshay on 2/3/2025.
//

import Foundation

struct EventSubRaidEvent: Codable {
    let fromBroadcasterUserId: String
    let fromBroadcasterUserLogin: String
    let fromBroadcasterUserName: String
    let toBroadcasterUserId: String
    let toBroadcasterUserLogin: String
    let toBroadcasterUserName: String
    let viewers: Int
    
    enum CodingKeys: String, CodingKey {
        case fromBroadcasterUserId = "from_broadcaster_user_id"
        case fromBroadcasterUserLogin = "from_broadcaster_user_login"
        case fromBroadcasterUserName = "from_broadcaster_user_name"
        case toBroadcasterUserId = "to_broadcaster_user_id"
        case toBroadcasterUserLogin = "to_broadcaster_user_login"
        case toBroadcasterUserName = "to_broadcaster_user_name"
        case viewers
    }
}

struct EventSubRaidPayload: Codable {
    let subscription: EventSubSubscriptionInfo
    let event: EventSubRaidEvent
}

struct EventSubRaidMessage: Codable {
    let metadata: EventSubMetadata
    let payload: EventSubRaidPayload
}
