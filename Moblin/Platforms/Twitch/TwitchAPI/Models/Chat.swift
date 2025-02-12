//
//  TwitchAPIChat.swift
//  Moblin
//

import Foundation

final class TwitchAPIChat {
    private let api: TwitchAPI

    init(api: TwitchAPI) {
        self.api = api
    }

    // MARK: - Get Channel Emotes
    func getChannelEmotes(broadcasterId: String, onComplete: @escaping ([TwitchApiEmote]?) -> Void) {
        api.sendRequest(
            method: "GET",
            subPath: "chat/emotes?broadcaster_id=\(broadcasterId)",
            onComplete: decode(TwitchApiChannelEmotesResponse.self) {
                onComplete($0?.data)
            }
        )
    }

    // MARK: - Get Global Emotes
    func getGlobalEmotes(onComplete: @escaping ([TwitchApiEmote]?) -> Void) {
        api.sendRequest(
            method: "GET",
            subPath: "chat/emotes/global",
            onComplete: decode(TwitchApiGlobalEmotesResponse.self) {
                onComplete($0?.data)
            }
        )
    }

    // MARK: - Get Emote Sets
    func getEmoteSets(emoteSetIds: [String], onComplete: @escaping ([TwitchApiEmote]?) -> Void) {
        let query = "chat/emotes/set?" + emoteSetIds.map { "emote_set_id=\($0)" }.joined(separator: "&")
        api.sendRequest(
            method: "GET",
            subPath: query,
            onComplete: decode(TwitchApiEmoteSetsResponse.self) {
                onComplete($0?.data)
            }
        )
    }

    // MARK: - Get Channel Chat Badges
    func getChannelChatBadges(broadcasterId: String, onComplete: @escaping ([TwitchApiChatBadgeSet]?) -> Void) {
        api.sendRequest(
            method: "GET",
            subPath: "chat/badges?broadcaster_id=\(broadcasterId)",
            onComplete: decode(TwitchApiChannelChatBadgesResponse.self) {
                onComplete($0?.data)
            }
        )
    }

    // MARK: - Get Global Chat Badges
    func getGlobalChatBadges(onComplete: @escaping ([TwitchApiChatBadgeSet]?) -> Void) {
        api.sendRequest(
            method: "GET",
            subPath: "chat/badges/global",
            onComplete: decode(TwitchApiGlobalChatBadgesResponse.self) {
                onComplete($0?.data)
            }
        )
    }

    // MARK: - Get Chat Settings
    func getChatSettings(broadcasterId: String, moderatorId: String?, onComplete: @escaping (TwitchApiChatSettings?) -> Void) {
        let query = "chat/settings?broadcaster_id=\(broadcasterId)" + (moderatorId != nil ? "&moderator_id=\(moderatorId!)" : "")
        api.sendRequest(
            method: "GET",
            subPath: query,
            onComplete: decode(TwitchApiChatSettingsResponse.self) {
                onComplete($0?.data.first)
            }
        )
    }

    // MARK: - Update Chat Settings
    func updateChatSettings(broadcasterId: String, settings: TwitchApiUpdateChatSettingsRequest, onComplete: @escaping (Bool) -> Void) {
        guard let jsonData = try? JSONEncoder().encode(settings) else {
            print("❌ Failed to encode JSON payload for updating chat settings")
            onComplete(false)
            return
        }

        api.sendRequest(
            method: "PATCH",
            subPath: "chat/settings?broadcaster_id=\(broadcasterId)",
            body: jsonData,
            onComplete: { data, response in  // ✅ Accept both parameters
                let httpStatusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

                if (200...299).contains(httpStatusCode) {
                    print("✅ Chat settings updated successfully.")
                    onComplete(true)
                } else {
                    print("❌ Failed to update chat settings. HTTP Status: \(httpStatusCode)")
                    onComplete(false)
                }
            }
        )
    }

    // MARK: - Get Shared Chat Session
    func getSharedChatSession(broadcasterId: String, onComplete: @escaping (TwitchApiSharedChatSession?) -> Void) {
        api.sendRequest(
            method: "GET",
            subPath: "chat/shared?broadcaster_id=\(broadcasterId)",
            onComplete: decode(TwitchApiSharedChatSessionResponse.self) {
                onComplete($0?.data.first)
            }
        )
    }

    // MARK: - Get User Emotes
    func getUserEmotes(userId: String, onComplete: @escaping ([TwitchApiEmote]?) -> Void) {
        api.sendRequest(
            method: "GET",
            subPath: "chat/emotes/user?user_id=\(userId)",
            onComplete: decode(TwitchApiEmoteSetsResponse.self) {
                onComplete($0?.data)
            }
        )
    }

    // MARK: - Send Chat Message
    func sendChatMessage(broadcasterId: String, senderId: String, message: String, onComplete: @escaping (Bool) -> Void) {
        let requestBody = TwitchApiSendChatMessageRequest(broadcaster_id: broadcasterId, sender_id: senderId, message: message)

        guard let jsonData = try? JSONEncoder().encode(requestBody) else {
            print("❌ Failed to encode JSON payload for sending chat message")
            onComplete(false)
            return
        }

        api.sendRequest(
            method: "POST",
            subPath: "chat/messages",
            body: jsonData,
            onComplete: { data, response in  // ✅ Accepts both `Data?` and `URLResponse?`
                let httpStatusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

                if (200...299).contains(httpStatusCode) {
                    print("✅ Message sent successfully.")
                    onComplete(true)
                } else {
                    print("❌ Failed to send chat message. HTTP Status: \(httpStatusCode)")
                    onComplete(false)
                }
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

// MARK: - Emote Models
struct TwitchApiChannelEmotesResponse: Decodable {
    let data: [TwitchApiEmote]
}

struct TwitchApiGlobalEmotesResponse: Decodable {
    let data: [TwitchApiEmote]
}

struct TwitchApiEmoteSetsResponse: Decodable {
    let data: [TwitchApiEmote]
}

struct TwitchApiEmote: Decodable {
    let id: String
    let name: String
    let images: TwitchApiEmoteImages
    let format: [String]
    let scale: [String]
    let theme_mode: [String]
}

struct TwitchApiEmoteImages: Decodable {
    let url_1x: String
    let url_2x: String
    let url_4x: String
}

// MARK: - Chat Badge Models
struct TwitchApiChannelChatBadgesResponse: Decodable {
    let data: [TwitchApiChatBadgeSet]
}

struct TwitchApiGlobalChatBadgesResponse: Decodable {
    let data: [TwitchApiChatBadgeSet]
}

struct TwitchApiChatBadgeSet: Decodable {
    let set_id: String
    let versions: [TwitchApiChatBadge]
}

struct TwitchApiChatBadge: Decodable {
    let id: String
    let image_url_1x: String
    let image_url_2x: String
    let image_url_4x: String
    let title: String
}

// MARK: - Chat Settings Models
struct TwitchApiChatSettingsResponse: Decodable {
    let data: [TwitchApiChatSettings]
}

struct TwitchApiChatSettings: Codable {
    let broadcaster_id: String
    let moderator_id: String?
    let slow_mode: Bool
    let slow_mode_wait_time: Int?
    let follower_mode: Bool
    let follower_mode_duration: Int?
    let subscriber_mode: Bool
    let emote_mode: Bool
    let unique_chat_mode: Bool
}

struct TwitchApiUpdateChatSettingsRequest: Codable {
    let moderator_id: String?
    let slow_mode: Bool?
    let slow_mode_wait_time: Int?
    let follower_mode: Bool?
    let follower_mode_duration: Int?
    let subscriber_mode: Bool?
    let emote_mode: Bool?
    let unique_chat_mode: Bool?
}

struct TwitchApiSendChatMessageRequest: Codable {
    let broadcaster_id: String
    let sender_id: String
    let message: String
}

// MARK: - Get Shared Chat Session Response
struct TwitchApiSharedChatSessionResponse: Decodable {
    let data: [TwitchApiSharedChatSession]
}

// MARK: - Shared Chat Session Model
struct TwitchApiSharedChatSession: Decodable {
    let broadcaster_id: String
    let moderator_id: String?
    let chat_session_id: String
    let created_at: String
    let participants: [TwitchApiSharedChatParticipant] // ✅ Added Participants Section
}

// MARK: - Shared Chat Session Participant Model
struct TwitchApiSharedChatParticipant: Decodable {
    let user_id: String
    let user_name: String
    let is_moderator: Bool
    let joined_at: String
}
