//
//  TwitchAPIUsers.swift
//  Moblin
//

import Foundation

final class TwitchAPIUsers {
    private let api: TwitchAPI

    init(api: TwitchAPI) {
        self.api = api
    }

    // MARK: - Get Users
    func getUsers(userIds: [String] = [], logins: [String] = [], onComplete: @escaping ([TwitchApiUser]?) -> Void) {
        var queryItems: [String] = []

        if !userIds.isEmpty {
            queryItems.append(contentsOf: userIds.map { "id=\($0)" })
        }

        if !logins.isEmpty {
            queryItems.append(contentsOf: logins.map { "login=\($0)" })
        }

        let query = "users?" + queryItems.joined(separator: "&")
        logger.debug("🔍 Fetching users with query: \(query)")
        
        api.sendRequest(
            method: "GET",
            subPath: query,
            onComplete: decode(TwitchApiGetUsersResponse.self) { response in
                if let users = response?.data {
                    logger.info("✅ Successfully fetched \(users.count) users.")
                } else {
                    logger.error("❌ Failed to fetch users.")
                }
                onComplete(response?.data)
            }
        )
    }

    // MARK: - Get Own User Info
    func getUserInfo(onComplete: @escaping (TwitchApiUser?) -> Void) {
        getUsers(onComplete: { users in
            onComplete(users?.first)
        })
    }

    // MARK: - Update User
    func updateUser(description: String, onComplete: @escaping (TwitchApiUser?) -> Void) {
        let requestBody = TwitchApiUpdateUserRequest(description: description)

        guard let jsonData = try? JSONEncoder().encode(requestBody) else {
            print("❌ Failed to encode JSON payload for updating user")
            onComplete(nil)
            return
        }

        api.sendRequest(
            method: "PUT",
            subPath: "users",
            body: jsonData,
            onComplete: decode(TwitchApiUpdateUserResponse.self) {
                onComplete($0?.data.first)
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

// MARK: - Get Users Response
struct TwitchApiGetUsersResponse: Decodable {
    let data: [TwitchApiUser]
}

// MARK: - User Data Model
struct TwitchApiUser: Decodable {
    let id: String
    let login: String
    let display_name: String
    let type: String
    let broadcaster_type: String
    let description: String
    let profile_image_url: String
    let offline_image_url: String
    let view_count: Int
    let created_at: String

    private enum CodingKeys: String, CodingKey {
        case id, login, display_name, type, broadcaster_type, description
        case profile_image_url, offline_image_url, view_count, created_at
    }
}

// MARK: - Update User Request
struct TwitchApiUpdateUserRequest: Encodable {
    let description: String
}

// MARK: - Update User Response
struct TwitchApiUpdateUserResponse: Decodable {
    let data: [TwitchApiUser]
}
