//
//  TwitchAPIGuestStar.swift
//  Moblin
//

import Foundation

// Add typealiases so that the API methods can refer to these types directly.
typealias GuestStarSession = TwitchApiGuestStarSessionResponse.GuestStarSession
typealias GuestStarInvite = TwitchApiGuestStarGetInvitesResponse.GuestStarInvite

final class TwitchAPIGuestStar {
    private let api: TwitchAPI

    init(api: TwitchAPI) {
        self.api = api
    }

    // MARK: - Get Guest Star Session
    func getGuestStarSession(broadcasterId: String, onComplete: @escaping (GuestStarSession?) -> Void) {
        api.sendRequest(
            method: "GET",
            subPath: "guest_star/session?broadcaster_id=\(broadcasterId)",
            onComplete: decode(TwitchApiGuestStarSessionResponse.self) {
                onComplete($0?.data.first)
            }
        )
    }

    // MARK: - Create Guest Star Session
    func createGuestStarSession(broadcasterId: String, moderatorId: String, onComplete: @escaping (GuestStarSession?) -> Void) {
        let requestBody = TwitchApiGuestStarCreateSessionRequest(moderator_id: moderatorId)

        guard let jsonData = try? JSONEncoder().encode(requestBody) else {
            print("❌ Failed to encode JSON payload for creating Guest Star session")
            onComplete(nil)
            return
        }

        api.sendRequest(
            method: "POST",
            subPath: "guest_star/session?broadcaster_id=\(broadcasterId)",
            body: jsonData,
            onComplete: decode(TwitchApiGuestStarSessionResponse.self) {
                onComplete($0?.data.first)
            }
        )
    }

    // MARK: - End Guest Star Session
    func endGuestStarSession(broadcasterId: String, moderatorId: String, onComplete: @escaping (Bool) -> Void) {
        let requestBody = TwitchApiGuestStarEndSessionRequest(moderator_id: moderatorId)

        guard let jsonData = try? JSONEncoder().encode(requestBody) else {
            print("❌ Failed to encode JSON payload for ending Guest Star session")
            onComplete(false)
            return
        }

        api.sendRequest(
            method: "DELETE",
            subPath: "guest_star/session?broadcaster_id=\(broadcasterId)",
            body: jsonData,
            onComplete: { data, _ in onComplete(data != nil) }
        )
    }

    // MARK: - Get Guest Star Invites
    func getGuestStarInvites(broadcasterId: String, onComplete: @escaping ([GuestStarInvite]?) -> Void) {
        api.sendRequest(
            method: "GET",
            subPath: "guest_star/invites?broadcaster_id=\(broadcasterId)",
            onComplete: decode(TwitchApiGuestStarGetInvitesResponse.self) {
                onComplete($0?.data)
            }
        )
    }

    // MARK: - Send Guest Star Invite
    func sendGuestStarInvite(broadcasterId: String, moderatorId: String, invitedUserId: String, onComplete: @escaping (Bool) -> Void) {
        let requestBody = TwitchApiGuestStarSendInviteRequest(moderator_id: moderatorId, invited_user_id: invitedUserId)

        guard let jsonData = try? JSONEncoder().encode(requestBody) else {
            print("❌ Failed to encode JSON payload for sending Guest Star invite")
            onComplete(false)
            return
        }

        api.sendRequest(
            method: "POST",
            subPath: "guest_star/invites?broadcaster_id=\(broadcasterId)",
            body: jsonData,
            onComplete: { data, _ in onComplete(data != nil) }
        )
    }

    // MARK: - Delete Guest Star Invite
    func deleteGuestStarInvite(broadcasterId: String, moderatorId: String, invitedUserId: String, onComplete: @escaping (Bool) -> Void) {
        let requestBody = TwitchApiGuestStarDeleteInviteRequest(moderator_id: moderatorId, invited_user_id: invitedUserId)

        guard let jsonData = try? JSONEncoder().encode(requestBody) else {
            print("❌ Failed to encode JSON payload for deleting Guest Star invite")
            onComplete(false)
            return
        }

        api.sendRequest(
            method: "DELETE",
            subPath: "guest_star/invites?broadcaster_id=\(broadcasterId)",
            body: jsonData,
            onComplete: { data, _ in onComplete(data != nil) }
        )
    }

    // MARK: - Assign Guest Star Slot
    func assignGuestStarSlot(broadcasterId: String, moderatorId: String, userId: String, slotId: String, onComplete: @escaping (Bool) -> Void) {
        let requestBody = TwitchApiGuestStarAssignSlotRequest(moderator_id: moderatorId, user_id: userId, slot_id: slotId)

        guard let jsonData = try? JSONEncoder().encode(requestBody) else {
            print("❌ Failed to encode JSON payload for assigning Guest Star slot")
            onComplete(false)
            return
        }

        api.sendRequest(
            method: "POST",
            subPath: "guest_star/slots?broadcaster_id=\(broadcasterId)",
            body: jsonData,
            onComplete: { data, _ in onComplete(data != nil) }
        )
    }

    // MARK: - Update Guest Star Slot
    func updateGuestStarSlot(broadcasterId: String, moderatorId: String, slotId: String, settings: GuestStarSlotSettings, onComplete: @escaping (Bool) -> Void) {
        let requestBody = TwitchApiGuestStarUpdateSlotRequest(moderator_id: moderatorId, slot_id: slotId, settings: settings)

        guard let jsonData = try? JSONEncoder().encode(requestBody) else {
            print("❌ Failed to encode JSON payload for updating Guest Star slot")
            onComplete(false)
            return
        }

        api.sendRequest(
            method: "PATCH",
            subPath: "guest_star/slots?broadcaster_id=\(broadcasterId)",
            body: jsonData,
            onComplete: { data, _ in onComplete(data != nil) }
        )
    }

    // MARK: - Delete Guest Star Slot
    func deleteGuestStarSlot(broadcasterId: String, moderatorId: String, slotId: String, onComplete: @escaping (Bool) -> Void) {
        let requestBody = TwitchApiGuestStarDeleteSlotRequest(moderator_id: moderatorId, slot_id: slotId)

        guard let jsonData = try? JSONEncoder().encode(requestBody) else {
            print("❌ Failed to encode JSON payload for deleting Guest Star slot")
            onComplete(false)
            return
        }

        api.sendRequest(
            method: "DELETE",
            subPath: "guest_star/slots?broadcaster_id=\(broadcasterId)",
            body: jsonData,
            onComplete: { data, _ in onComplete(data != nil) }
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

// MARK: - Guest Star: Get Session Response
struct TwitchApiGuestStarSessionResponse: Decodable {
    let data: [GuestStarSession]

    struct GuestStarSession: Decodable {
        let id: String
        let broadcaster_id: String
        let moderator_id: String
        let created_at: String
        let settings: GuestStarSessionSettings
        let slots: [GuestStarSlot]
    }
}

// MARK: - Guest Star: Create Session Request
struct TwitchApiGuestStarCreateSessionRequest: Encodable {
    let moderator_id: String
}

// MARK: - Guest Star: End Session Request
struct TwitchApiGuestStarEndSessionRequest: Encodable {
    let moderator_id: String
}

// MARK: - Guest Star: Get Invites Response
struct TwitchApiGuestStarGetInvitesResponse: Decodable {
    let data: [GuestStarInvite]

    struct GuestStarInvite: Decodable {
        let id: String
        let broadcaster_id: String
        let moderator_id: String
        let invited_user_id: String
        let created_at: String
        let status: String // "PENDING", "ACCEPTED", "DECLINED"
    }
}

// MARK: - Guest Star: Send Invite Request
struct TwitchApiGuestStarSendInviteRequest: Encodable {
    let moderator_id: String
    let invited_user_id: String
}

// MARK: - Guest Star: Delete Invite Request
struct TwitchApiGuestStarDeleteInviteRequest: Encodable {
    let moderator_id: String
    let invited_user_id: String
}

// MARK: - Guest Star: Assign Slot Request
struct TwitchApiGuestStarAssignSlotRequest: Encodable {
    let moderator_id: String
    let user_id: String
    let slot_id: String
}

// MARK: - Guest Star: Update Slot Request
struct TwitchApiGuestStarUpdateSlotRequest: Encodable {
    let moderator_id: String
    let slot_id: String
    let settings: GuestStarSlotSettings
}

// MARK: - Guest Star: Delete Slot Request
struct TwitchApiGuestStarDeleteSlotRequest: Encodable {
    let moderator_id: String
    let slot_id: String
}

// MARK: - Guest Star: Update Slot Settings Request
struct TwitchApiGuestStarUpdateSlotSettingsRequest: Encodable {
    let moderator_id: String
    let slot_settings: GuestStarSlotSettings
}

// MARK: - Guest Star: Common Data Models
struct GuestStarSessionSettings: Codable {
    let is_audio_enabled: Bool
    let is_video_enabled: Bool
    let is_chat_enabled: Bool
    let allow_requests: Bool
}

struct GuestStarSlot: Decodable {
    let id: String
    let assigned_user_id: String?
    let settings: GuestStarSlotSettings
}

struct GuestStarSlotSettings: Codable {
    let is_muted: Bool
    let is_video_enabled: Bool
    let volume_level: Int
}
