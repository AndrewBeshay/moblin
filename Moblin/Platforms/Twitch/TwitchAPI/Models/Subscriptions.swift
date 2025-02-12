//
//  TwitchAPISubscriptions.swift
//  Moblin
//

import Foundation

final class TwitchAPISubscriptions {
    private let api: TwitchAPI

    init(api: TwitchAPI) {
        self.api = api
    }

    // MARK: - Get Broadcaster Subscriptions
    func getBroadcasterSubscriptions(broadcasterId: String, userIds: [String] = [], onComplete: @escaping ([TwitchApiBroadcasterSubscription]?, Int?) -> Void) {
        var query = "subscriptions?broadcaster_id=\(broadcasterId)"
        if !userIds.isEmpty {
            query += "&" + userIds.map { "user_id=\($0)" }.joined(separator: "&")
        }

        api.sendRequest(
            method: "GET",
            subPath: query,
            onComplete: decode(TwitchApiGetBroadcasterSubscriptionsResponse.self) {
                onComplete($0?.data, $0?.total)
            }
        )
    }

    // MARK: - Check User Subscription
    func checkUserSubscription(broadcasterId: String, userId: String, onComplete: @escaping (TwitchApiUserSubscription?) -> Void) {
        let query = "subscriptions/user?broadcaster_id=\(broadcasterId)&user_id=\(userId)"

        api.sendRequest(
            method: "GET",
            subPath: query,
            onComplete: decode(TwitchApiCheckUserSubscriptionResponse.self) {
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

// MARK: - Get Broadcaster Subscriptions Response
struct TwitchApiGetBroadcasterSubscriptionsResponse: Decodable {
    let data: [TwitchApiBroadcasterSubscription]
    let total: Int?
    let pagination: TwitchApiPagination?
}

// MARK: - Broadcaster Subscription Data Model
struct TwitchApiBroadcasterSubscription: Decodable {
    let broadcaster_id: String
    let broadcaster_name: String
    let user_id: String
    let user_name: String
    let tier: String
    let is_gift: Bool
}

// MARK: - Check User Subscription Response
struct TwitchApiCheckUserSubscriptionResponse: Decodable {
    let data: [TwitchApiUserSubscription]
}

// MARK: - User Subscription Data Model
struct TwitchApiUserSubscription: Decodable {
    let broadcaster_id: String
    let broadcaster_name: String
    let tier: String
    let is_gift: Bool
}

// MARK: - Pagination Model
struct TwitchApiPagination: Decodable {
    let cursor: String?
}
