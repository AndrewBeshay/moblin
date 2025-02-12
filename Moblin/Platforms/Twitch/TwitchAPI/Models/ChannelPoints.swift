//
//  TwitchAPIChannelPoints.swift
//  Moblin
//

import Foundation

final class TwitchAPIChannelPoints {
    private let api: TwitchAPI

    init(api: TwitchAPI) {
        self.api = api
    }

    // MARK: - Get Custom Rewards
    func getCustomRewards(broadcasterId: String, onlyManageable: Bool = false, onComplete: @escaping ([TwitchApiCustomReward]?) -> Void) {
        let query = "channel_points/custom_rewards?broadcaster_id=\(broadcasterId)&only_manageable=\(onlyManageable)"
        api.sendRequest(
            method: "GET",
            subPath: query,
            onComplete: decode(TwitchApiGetCustomRewardsResponse.self) {
                onComplete($0?.data)
            }
        )
    }

    // MARK: - Get Custom Reward Redemptions
    func getCustomRewardRedemptions(broadcasterId: String, rewardId: String, status: String = "UNFULFILLED", sort: String = "NEWEST", onComplete: @escaping ([TwitchApiCustomRewardRedemption]?) -> Void) {
        let query = "channel_points/custom_rewards/redemptions?broadcaster_id=\(broadcasterId)&reward_id=\(rewardId)&status=\(status)&sort=\(sort)"
        api.sendRequest(
            method: "GET",
            subPath: query,
            onComplete: decode(TwitchApiGetCustomRewardRedemptionsResponse.self) {
                onComplete($0?.data)
            }
        )
    }

    // MARK: - Create Custom Reward
    func createCustomReward(broadcasterId: String, reward: TwitchApiCreateCustomRewardRequest, onComplete: @escaping (TwitchApiCustomReward?) -> Void) {
        guard let jsonData = try? JSONEncoder().encode(reward) else {
            print("❌ Failed to encode JSON payload for creating custom reward")
            onComplete(nil)
            return
        }

        api.sendRequest(
            method: "POST",
            subPath: "channel_points/custom_rewards?broadcaster_id=\(broadcasterId)",
            body: jsonData,
            onComplete: decode(TwitchApiCreateCustomRewardResponse.self) {
                onComplete($0?.data.first)
            }
        )
    }

    // MARK: - Delete Custom Reward
    func deleteCustomReward(broadcasterId: String, rewardId: String, onComplete: @escaping (Bool) -> Void) {
        api.sendRequest(
            method: "DELETE",
            subPath: "channel_points/custom_rewards?broadcaster_id=\(broadcasterId)&id=\(rewardId)",
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

// MARK: - Get Custom Rewards Response
struct TwitchApiGetCustomRewardsResponse: Decodable {
    let data: [TwitchApiCustomReward]
}

// MARK: - Custom Reward Data Model
struct TwitchApiCustomReward: Decodable {
    let id: String
    let broadcaster_id: String
    let broadcaster_name: String
    let title: String
    let cost: Int
    let prompt: String?
    let is_enabled: Bool
    let is_paused: Bool
    let is_in_stock: Bool
    let background_color: String
    let max_per_stream: RewardMaxLimit?
    let max_per_user_per_stream: RewardMaxLimit?
    let global_cooldown: RewardGlobalCooldown?
    let is_user_input_required: Bool
    let is_sub_only: Bool
    let is_mod_only: Bool
    let redemption_count: Int?
    let cooldown_expires_at: String?
}

// MARK: - Reward Max Limit Data Model
struct RewardMaxLimit: Codable {
    let is_enabled: Bool
    let value: Int
}

// MARK: - Reward Global Cooldown Data Model
struct RewardGlobalCooldown: Codable {
    let is_enabled: Bool
    let seconds: Int
}

// MARK: - Get Custom Reward Redemptions Response
struct TwitchApiGetCustomRewardRedemptionsResponse: Decodable {
    let data: [TwitchApiCustomRewardRedemption]
}

// MARK: - Custom Reward Redemption Data Model
struct TwitchApiCustomRewardRedemption: Decodable {
    let id: String
    let broadcaster_id: String
    let broadcaster_name: String
    let user_id: String
    let user_name: String
    let user_input: String?
    let status: String // "UNFULFILLED", "FULFILLED", or "CANCELED"
    let redeemed_at: String
}

// MARK: - Create Custom Reward Request
struct TwitchApiCreateCustomRewardRequest: Encodable {
    let title: String
    let cost: Int
    let prompt: String?
    let is_enabled: Bool?
    let background_color: String?
    let max_per_stream: RewardMaxLimit?
    let max_per_user_per_stream: RewardMaxLimit?
    let global_cooldown: RewardGlobalCooldown?
    let is_user_input_required: Bool?
    let is_sub_only: Bool?
    let is_mod_only: Bool?
}

// MARK: - Create Custom Reward Response
struct TwitchApiCreateCustomRewardResponse: Decodable {
    let data: [TwitchApiCustomReward]
}

// MARK: - Delete Custom Reward Response
struct TwitchApiDeleteCustomRewardResponse: Decodable {
    let success: Bool
}
