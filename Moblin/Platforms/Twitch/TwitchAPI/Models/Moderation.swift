//
//  TwitchAPIModeration.swift
//  Moblin
//

import Foundation

final class TwitchAPIModeration {
    private let api: TwitchAPI

    init(api: TwitchAPI) {
        self.api = api
    }
    
    // MARK: - Ban User
    func banUser(broadcasterId: String, userId: String, reason: String, duration: Int?, onComplete: @escaping (TwitchApiBanUserResponse?) -> Void) {
        let banData = TwitchApiBanUserRequest.BanData(user_id: userId, reason: reason, duration: duration)
        let requestBody = TwitchApiBanUserRequest(data: banData)
        
        guard let jsonData = try? JSONEncoder().encode(requestBody) else {
            logger.error("❌ Failed to encode JSON payload for banning user")
            onComplete(nil)
            return
        }
        
        api.sendRequest(
            method: "POST",
            subPath: "moderation/bans?broadcaster_id=\(broadcasterId)",
            body: jsonData,
            onComplete: decode(TwitchApiBanUserResponse.self) { response in
                onComplete(response)
            }
        )
    }
    
    // MARK: - Unban User
    func unbanUser(broadcasterId: String, userId: String, onComplete: @escaping (TwitchApiUnbanUserResponse?) -> Void) {
        let subPath = "moderation/bans?broadcaster_id=\(broadcasterId)&user_id=\(userId)"
        api.sendRequest(
            method: "DELETE",
            subPath: subPath,
            onComplete: decode(TwitchApiUnbanUserResponse.self) { response in
                onComplete(response)
            }
        )
    }
    
    // MARK: - Get Banned Users
    func getBannedUsers(broadcasterId: String, onComplete: @escaping ([TwitchApiBannedUsers.BannedUser]?) -> Void) {
        let subPath = "moderation/banned?broadcaster_id=\(broadcasterId)"
        api.sendRequest(
            method: "GET",
            subPath: subPath,
            onComplete: decode(TwitchApiBannedUsers.self) { response in
                onComplete(response?.data)
            }
        )
    }
    
    // MARK: - Get Automod Settings
    func getAutomodSettings(broadcasterId: String, moderatorId: String, onComplete: @escaping (TwitchApiAutoModSettings.AutoModSettings?) -> Void) {
        let subPath = "moderation/automod/settings?broadcaster_id=\(broadcasterId)&moderator_id=\(moderatorId)"
        api.sendRequest(
            method: "GET",
            subPath: subPath,
            onComplete: decode(TwitchApiAutoModSettings.self) { response in
                onComplete(response?.data.first)
            }
        )
    }
    
    // MARK: - Automod Message Review
    func reviewAutomodMessage(userId: String, msgId: String, action: String, onComplete: @escaping (Bool) -> Void) {
        let requestBody = TwitchApiAutoModMessageReviewRequest(user_id: userId, msg_id: msgId, action: action)
        guard let jsonData = try? JSONEncoder().encode(requestBody) else {
            print("❌ Failed to encode JSON payload for automod message review")
            onComplete(false)
            return
        }
        api.sendRequest(
            method: "POST",
            subPath: "moderation/automod/message",
            body: jsonData,
            onComplete: { data, _ in onComplete(data != nil) }
        )
    }
    
    // MARK: - Get Blocked Terms
    func getBlockedTerms(broadcasterId: String, moderatorId: String, onComplete: @escaping ([TwitchApiBlockedTerms.BlockedTerm]?) -> Void) {
        let subPath = "moderation/blocked_terms?broadcaster_id=\(broadcasterId)&moderator_id=\(moderatorId)"
        api.sendRequest(
            method: "GET",
            subPath: subPath,
            onComplete: decode(TwitchApiBlockedTerms.self) { response in
                onComplete(response?.data)
            }
        )
    }
    
    // MARK: - Add Blocked Term
    func addBlockedTerm(broadcasterId: String, moderatorId: String, text: String, onComplete: @escaping (Bool) -> Void) {
        let requestBody = TwitchApiAddBlockedTermRequest(broadcaster_id: broadcasterId, moderator_id: moderatorId, text: text)
        guard let jsonData = try? JSONEncoder().encode(requestBody) else {
            print("❌ Failed to encode JSON payload for adding blocked term")
            onComplete(false)
            return
        }
        let subPath = "moderation/blocked_terms?broadcaster_id=\(broadcasterId)&moderator_id=\(moderatorId)"
        api.sendRequest(
            method: "POST",
            subPath: subPath,
            body: jsonData,
            onComplete: { data, _ in onComplete(data != nil) }
        )
    }
    
    // MARK: - Get Moderators
    func getModerators(broadcasterId: String, onComplete: @escaping ([TwitchApiModerators.Moderator]?) -> Void) {
        let subPath = "moderation/moderators?broadcaster_id=\(broadcasterId)"
        api.sendRequest(
            method: "GET",
            subPath: subPath,
            onComplete: decode(TwitchApiModerators.self) { response in
                onComplete(response?.data)
            }
        )
    }
    
    // MARK: - Add Channel Moderator
    func addModerator(broadcasterId: String, userId: String, onComplete: @escaping (Bool) -> Void) {
        let requestBody = TwitchApiAddModeratorRequest(user_id: userId)
        guard let jsonData = try? JSONEncoder().encode(requestBody) else {
            print("❌ Failed to encode JSON payload for adding moderator")
            onComplete(false)
            return
        }
        let subPath = "moderation/moderators?broadcaster_id=\(broadcasterId)"
        api.sendRequest(
            method: "POST",
            subPath: subPath,
            body: jsonData,
            onComplete: { data, _ in onComplete(data != nil) }
        )
    }
    
    // MARK: - Remove Channel Moderator
    func removeModerator(broadcasterId: String, userId: String, onComplete: @escaping (Bool) -> Void) {
        let requestBody = TwitchApiRemoveModeratorRequest(user_id: userId)
        guard let jsonData = try? JSONEncoder().encode(requestBody) else {
            print("❌ Failed to encode JSON payload for removing moderator")
            onComplete(false)
            return
        }
        let subPath = "moderation/moderators?broadcaster_id=\(broadcasterId)"
        api.sendRequest(
            method: "DELETE",
            subPath: subPath,
            body: jsonData,
            onComplete: { data, _ in onComplete(data != nil) }
        )
    }
    
    // MARK: - Get VIPs
    func getVIPs(broadcasterId: String, onComplete: @escaping ([TwitchApiVIPs.VIP]?) -> Void) {
        let subPath = "channels/vips?broadcaster_id=\(broadcasterId)"
        api.sendRequest(
            method: "GET",
            subPath: subPath,
            onComplete: decode(TwitchApiVIPs.self) { response in
                onComplete(response?.data)
            }
        )
    }
    
    // MARK: - Add Channel VIP
    func addVIP(broadcasterId: String, userId: String, onComplete: @escaping (Bool) -> Void) {
        let requestBody = TwitchApiAddVIPRequest(user_id: userId)
        guard let jsonData = try? JSONEncoder().encode(requestBody) else {
            print("❌ Failed to encode JSON payload for adding VIP")
            onComplete(false)
            return
        }
        let subPath = "channels/vips?broadcaster_id=\(broadcasterId)"
        api.sendRequest(
            method: "POST",
            subPath: subPath,
            body: jsonData,
            onComplete: { data, _ in onComplete(data != nil) }
        )
    }
    
    // MARK: - Remove Channel VIP
    func removeVIP(broadcasterId: String, userId: String, onComplete: @escaping (Bool) -> Void) {
        let requestBody = TwitchApiRemoveVIPRequest(user_id: userId)
        guard let jsonData = try? JSONEncoder().encode(requestBody) else {
            print("❌ Failed to encode JSON payload for removing VIP")
            onComplete(false)
            return
        }
        let subPath = "channels/vips?broadcaster_id=\(broadcasterId)"
        api.sendRequest(
            method: "DELETE",
            subPath: subPath,
            body: jsonData,
            onComplete: { data, _ in onComplete(data != nil) }
        )
    }
    
    // MARK: - Get Shield Mode
    func getShieldMode(broadcasterId: String, onComplete: @escaping (TwitchApiShieldMode.ShieldMode?) -> Void) {
        let subPath = "moderation/shield_mode?broadcaster_id=\(broadcasterId)"
        api.sendRequest(
            method: "GET",
            subPath: subPath,
            onComplete: decode(TwitchApiShieldMode.self) { response in
                onComplete(response?.data.first)
            }
        )
    }
    
    // MARK: - Send Chat Announcement
    func sendChatAnnouncement(broadcasterId: String, moderatorId: String, message: String, color: String, onComplete: @escaping (Bool) -> Void) {
        let requestBody = TwitchApiChatAnnouncementRequest(broadcaster_id: broadcasterId, moderator_id: moderatorId, message: message, color: color)
        guard let jsonData = try? JSONEncoder().encode(requestBody) else {
            print("❌ Failed to encode JSON payload for chat announcement")
            onComplete(false)
            return
        }
        let subPath = "chat/announcements?broadcaster_id=\(broadcasterId)&moderator_id=\(moderatorId)"
        api.sendRequest(
            method: "POST",
            subPath: subPath,
            body: jsonData,
            onComplete: { data, _ in onComplete(data != nil) }
        )
    }
    
    // MARK: - Delete Chat Messages
    func deleteChatMessages(broadcasterId: String, moderatorId: String, messageId: String?, onComplete: @escaping (String?) -> Void) {
        let requestBody = TwitchApiDeleteChatMessagesRequest(broadcaster_id: broadcasterId, moderator_id: moderatorId, message_id: messageId)
        guard let jsonData = try? JSONEncoder().encode(requestBody) else {
            print("❌ Failed to encode JSON payload for deleting chat messages")
            onComplete(nil)
            return
        }
        let subPath = "chat/messages?broadcaster_id=\(broadcasterId)&moderator_id=\(moderatorId)"
        api.sendRequest(
            method: "DELETE",
            subPath: subPath,
            body: jsonData,
            onComplete: decode(TwitchApiDeleteChatMessagesResponse.self) { response in
                onComplete(response?.message)
            }
        )
    }
    
    // MARK: - Helper Method for JSON Decoding
    private func decode<T: Decodable>(_ type: T.Type, _ onComplete: @escaping (T?) -> Void) -> (Data?, URLResponse?) -> Void {
        return { data, response in
            guard let data = data else { onComplete(nil); return }
            onComplete(try? JSONDecoder().decode(T.self, from: data))
        }
    }
}

// MARK: - Moderation: Ban User Request
struct TwitchApiBanUserRequest: Encodable {
    let data: BanData

    struct BanData: Encodable {
        let user_id: String
        let reason: String
        let duration: Int? // Optional: If set, it's a timeout instead of a ban.
    }
}

// MARK: - Moderation: Ban User Response
struct TwitchApiBanUserResponse: Decodable {
    let data: [BanResponseData]

    struct BanResponseData: Decodable {
        let user_id: String
        let user_name: String
        let expires_at: String? // Will be `nil` if permanent ban.
    }
}

// MARK: - Moderation: Unban User Response
struct TwitchApiUnbanUserResponse: Decodable {
    let data: [UnbanResponseData]

    struct UnbanResponseData: Decodable {
        let user_id: String
        let user_name: String
    }
}

// MARK: - Moderation: Get Banned Users Response
struct TwitchApiBannedUsers: Decodable {
    let data: [BannedUser]

    struct BannedUser: Decodable {
        let user_id: String
        let user_name: String
        let expires_at: String? // If `nil`, the ban is permanent.
    }
}

// MARK: - Moderation: Automod Settings Response
struct TwitchApiAutoModSettings: Decodable {
    let data: [AutoModSettings]

    struct AutoModSettings: Decodable {
        let broadcaster_id: String
        let moderator_id: String
        let overall_level: Int?
        let disability: Int?
        let identity_hate: Int?
        let misconduct: Int?
        let aggression: Int?
        let sexuality_sex_or_gender: Int?
        let profanity: Int?
    }
}

// MARK: - Moderation: Automod Message Review Request
struct TwitchApiAutoModMessageReviewRequest: Encodable {
    let user_id: String
    let msg_id: String
    let action: String // "ALLOW" or "DENY"
}

// MARK: - Moderation: Blocked Terms Response
struct TwitchApiBlockedTerms: Decodable {
    let data: [BlockedTerm]

    struct BlockedTerm: Decodable {
        let id: String
        let broadcaster_id: String
        let moderator_id: String
        let text: String
        let created_at: String
        let updated_at: String
    }
}

// MARK: - Moderation: Add Blocked Term Request
struct TwitchApiAddBlockedTermRequest: Encodable {
    let broadcaster_id: String
    let moderator_id: String
    let text: String
}

// MARK: - Moderation: Moderator List Response
struct TwitchApiModerators: Decodable {
    let data: [Moderator]

    struct Moderator: Decodable {
        let user_id: String
        let user_name: String
    }
}

// MARK: - Moderation: Add Channel Moderator Request
struct TwitchApiAddModeratorRequest: Encodable {
    let user_id: String
}

// MARK: - Moderation: Remove Channel Moderator Request
struct TwitchApiRemoveModeratorRequest: Encodable {
    let user_id: String
}

// MARK: - Moderation: VIP List Response
struct TwitchApiVIPs: Decodable {
    let data: [VIP]

    struct VIP: Decodable {
        let user_id: String
        let user_name: String
    }
}

// MARK: - Moderation: Add Channel VIP Request
struct TwitchApiAddVIPRequest: Encodable {
    let user_id: String
}

// MARK: - Moderation: Remove Channel VIP Request
struct TwitchApiRemoveVIPRequest: Encodable {
    let user_id: String
}

// MARK: - Moderation: Shield Mode Response
struct TwitchApiShieldMode: Decodable {
    let data: [ShieldMode]

    struct ShieldMode: Decodable {
        let is_active: Bool
        let moderator_id: String
    }
}

// MARK: - Moderation: Chat Announcements Request
struct TwitchApiChatAnnouncementRequest: Encodable {
    let broadcaster_id: String
    let moderator_id: String
    let message: String
    let color: String // One of "blue", "green", "orange", "purple", "primary"
}

// MARK: - Moderation: Delete Chat Messages Request
struct TwitchApiDeleteChatMessagesRequest: Encodable {
    let broadcaster_id: String
    let moderator_id: String
    let message_id: String?
}

// MARK: - Moderation: Delete Chat Messages Response
struct TwitchApiDeleteChatMessagesResponse: Decodable {
    let message: String?
}
