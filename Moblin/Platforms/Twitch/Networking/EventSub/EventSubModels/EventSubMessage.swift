//
//  EventSubMessage.swift
//  Moblin
//
//  Created by Andrew Beshay on 2/3/2025.
//

import Foundation

// Base message structures
enum EventSubMessageType: String, Codable {
    case sessionWelcome = "session_welcome"
    case sessionKeepAlive = "session_keepalive"
    case notification = "notification"
    case reconnect = "session_reconnect"
    case revocation = "revocation"
    case unknown
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = EventSubMessageType(rawValue: rawValue) ?? .unknown
    }
}

enum EventSubSubscriptionType: String {
    case channelFollow = "channel.follow"
    case channelSubscribe = "channel.subscribe"
    case channelSubscriptionGift = "channel.subscription.gift"
    case channelSubscriptionMessage = "channel.subscription.message"
    case channelRaid = "channel.raid"
    case channelCheer = "channel.cheer"
    case channelModerate = "channel.moderate"
    case channelSharedChatBegin = "channel.shared_chat.begin"
    case channelSharedChatUpdate = "channel.shared_chat.update"
    case channelSharedChatEnd = "channel.shared_chat.end"
}

struct EventSubMetadata: Codable {
    let messageId: String
    let messageType: EventSubMessageType
    let messageTimestamp: String
    let subscriptionType: String?
    
    enum CodingKeys: String, CodingKey {
        case messageId = "message_id"
        case messageType = "message_type"
        case messageTimestamp = "message_timestamp"
        case subscriptionType = "subscription_type"
    }
}

struct EventSubMessage: Codable {
    let metadata: EventSubMetadata
}

// Helper function for parsing RFC3339 timestamps with nanoseconds
func parseRFC3339NanoTimestamp(_ timestamp: String) -> Date? {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSSSX"
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

    return dateFormatter.date(from: timestamp)
}
