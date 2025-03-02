//
//  EventSubModerateEvent.swift
//  Moblin
//
//  Created by Andrew Beshay on 2/3/2025.
//

import Foundation

struct EventSubTargetUser: Codable, CustomStringConvertible {
    let userId: String
    let userLogin: String
    let userName: String
    let reason: String?
    let messageBody: String?
    let expiresAt: String?
    let messageId: String?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case userLogin = "user_login"
        case userName = "user_name"
        case reason
        case messageBody = "message_body"
        case expiresAt = "expires_at"
        case messageId = "message_id"
    }
    
    var description: String {
        var output = "TargetUser:\n"
        output += "  ID: \(userId)\n"
        output += "  Login: \(userLogin)\n"
        output += "  Name: \(userName)"
        if let messageId = messageId {
            output += "\n  Message ID: \(messageId)"
        }
        if let reason = reason {
            output += "\n  Reason: \(reason)"
        }
        if let messageBody = messageBody {
            output += "\n  Message Body: \(messageBody)"
        }
        if let expiresAt = expiresAt {
            output += "\n  Expires At: \(expiresAt)"
        }
        return output
    }
}

struct EventSubModerateEvent: Codable, CustomStringConvertible {
    let broadcasterUserId: String
    let broadcasterUserLogin: String
    let broadcasterUserName: String
    let moderatorUserId: String
    let moderatorUserLogin: String
    let moderatorUserName: String
    let action: String
    let moderatedAt: String?
    let targetUser: EventSubTargetUser?
    
    enum CodingKeys: String, CodingKey {
        case broadcasterUserId = "broadcaster_user_id"
        case broadcasterUserLogin = "broadcaster_user_login"
        case broadcasterUserName = "broadcaster_user_name"
        case moderatorUserId = "moderator_user_id"
        case moderatorUserLogin = "moderator_user_login"
        case moderatorUserName = "moderator_user_name"
        case action
        case moderatedAt = "moderated_at"
        case targetUser = "target_user"
        
        // Action-specific keys that may contain target info
        case ban
        case timeout
        case unban
        case untimeout
        case clear
        case delete
        case sharedChatBan = "shared_chat_ban"
        case sharedChatTimeout = "shared_chat_timeout"
        case sharedChatDelete = "shared_chat_delete"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        broadcasterUserId = try container.decode(String.self, forKey: .broadcasterUserId)
        broadcasterUserLogin = try container.decode(String.self, forKey: .broadcasterUserLogin)
        broadcasterUserName = try container.decode(String.self, forKey: .broadcasterUserName)
        moderatorUserId = try container.decode(String.self, forKey: .moderatorUserId)
        moderatorUserLogin = try container.decode(String.self, forKey: .moderatorUserLogin)
        moderatorUserName = try container.decode(String.self, forKey: .moderatorUserName)
        action = try container.decode(String.self, forKey: .action)
        moderatedAt = try container.decodeIfPresent(String.self, forKey: .moderatedAt)
        
        // First try to decode target_user directly
        var targetUserTemp: EventSubTargetUser? = try? container.decodeIfPresent(EventSubTargetUser.self, forKey: .targetUser)
        
        // If not found, try to decode using the action as a key
        if targetUserTemp == nil, let actionKey = CodingKeys(rawValue: action) {
            targetUserTemp = try? container.decodeIfPresent(EventSubTargetUser.self, forKey: actionKey)
        }
        
        targetUser = targetUserTemp
    }
    
    // Add this method inside EventSubModerateEvent
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(broadcasterUserId, forKey: .broadcasterUserId)
        try container.encode(broadcasterUserLogin, forKey: .broadcasterUserLogin)
        try container.encode(broadcasterUserName, forKey: .broadcasterUserName)
        try container.encode(moderatorUserId, forKey: .moderatorUserId)
        try container.encode(moderatorUserLogin, forKey: .moderatorUserLogin)
        try container.encode(moderatorUserName, forKey: .moderatorUserName)
        try container.encode(action, forKey: .action)
        try container.encodeIfPresent(moderatedAt, forKey: .moderatedAt)
        try container.encodeIfPresent(targetUser, forKey: .targetUser)
    }
    
    var description: String {
        var output = "ChannelModerateEvent:\n"
        output += "  Action: \(action)\n"
        if let moderatedAt = moderatedAt {
            output += "  Moderated At: \(moderatedAt)\n"
        } else {
            output += "  Moderated At: n/a\n"
        }
        output += "  Broadcaster: \(broadcasterUserName) (\(broadcasterUserLogin), \(broadcasterUserId))\n"
        output += "  Moderator: \(moderatorUserName) (\(moderatorUserLogin), \(moderatorUserId))\n"
        if let target = targetUser {
            output += "\n" + target.description
        }
        return output
    }
}

struct EventSubModeratePayload: Codable, CustomStringConvertible {
    let subscription: EventSubSubscriptionInfo
    let event: EventSubModerateEvent
    
    var description: String {
        return event.description
    }
}

struct EventSubModerateMessage: Codable, CustomStringConvertible {
    let metadata: EventSubMetadata
    let payload: EventSubModeratePayload
    
    var timeoutDuration: String? {
        guard let expiresAt = payload.event.targetUser?.expiresAt,
              let rawExpiresDate = parseRFC3339NanoTimestamp(expiresAt),
              let messageTimestamp = parseRFC3339NanoTimestamp(metadata.messageTimestamp) else {
            return nil
        }

        // Round the expiration date to whole seconds
        let roundedExpiresDate = Date(timeIntervalSinceReferenceDate: ceil(rawExpiresDate.timeIntervalSinceReferenceDate))
        // Compute duration and convert to an integer (removes decimals)
        let duration = Int(roundedExpiresDate.timeIntervalSince(messageTimestamp))

        return "\(duration)s"
    }
    
    var description: String {
        return payload.description
    }
}
