//
//  TwitchAPIBits.swift
//  Moblin
//

import Foundation

final class TwitchAPIBits {
    private let api: TwitchAPI

    init(api: TwitchAPI) {
        self.api = api
    }
    
    // MARK: - Get Bits Leaderboard
    func getBitsLeaderboard(count: Int = 10, period: String = "all", startedAt: String? = nil, userId: String? = nil, onComplete: @escaping (TwitchApiBitsLeaderboardResponse?) -> Void) {
        var query = "bits/leaderboard?count=\(count)&period=\(period)"
        if let startedAt { query += "&started_at=\(startedAt)" }
        if let userId { query += "&user_id=\(userId)" }

        api.sendRequest(
            method: "GET",
            subPath: query,
            onComplete: decode(TwitchApiBitsLeaderboardResponse.self, onComplete)
        )
    }

    // MARK: - Get Cheermotes
    func getCheermotes(broadcasterId: String, onComplete: @escaping ([TwitchApiCheermoteData]?, String?) -> Void) {
        api.sendRequest(
            method: "GET",
            subPath: "bits/cheermotes?broadcaster_id=\(broadcasterId)",
            onComplete: { data, response in
                let httpStatusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                
                switch httpStatusCode {
                case 200:
                    // ✅ Successfully retrieved Cheermotes
                    if let data = data {
                        // 📝 Convert Data to String for Logging
                        if let jsonString = String(data: data, encoding: .utf8) {
                            logger.info("📜 Raw JSON Response: \(jsonString)")
                        } else {
                            logger.warning("⚠️ Unable to convert Data to String.")
                        }

                        let decodedData = try? JSONDecoder().decode(TwitchApiGetCheermotesResponse.self, from: data)
                        onComplete(decodedData?.data, nil)
                    } else {
                        onComplete(nil, "Received 200 OK but response body is empty.")
                    }

                case 401:
                    // ❌ Unauthorized request
                    logger.error("❌ 401 Unauthorized: Missing or invalid authentication token.")
                    onComplete(nil, "401 Unauthorized: Invalid OAuth token or Client ID mismatch.")

                default:
                    // ❌ Handle unexpected errors
                    logger.error("❌ Unexpected HTTP Status: \(httpStatusCode)")
                    onComplete(nil, "Unexpected error: HTTP \(httpStatusCode)")
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

// MARK: - Get Bits Leaderboard Response
struct TwitchApiBitsLeaderboardResponse: Decodable {
    let data: [TwitchApiBitsLeaderboardEntry]
    let total: Int
    let started_at: String
    let ended_at: String
}

// MARK: - Bits Leaderboard Entry Model
struct TwitchApiBitsLeaderboardEntry: Decodable {
    let user_id: String
    let user_name: String
    let rank: Int
    let score: Int
}

// MARK: - Get Cheermotes Response
struct TwitchApiGetCheermotesResponse: Decodable {
    let data: [TwitchApiCheermoteData]
}

// MARK: - Cheermote Data Model
struct TwitchApiCheermoteData: Decodable {
    let prefix: String
    let tiers: [TwitchApiCheermoteTier]
    let type: String // "global_first_party", "global_third_party", "channel_custom", etc.
    let order: Int
    let last_updated: String
    let is_charitable: Bool
}

// MARK: - Cheermote Tier Data Model
struct TwitchApiCheermoteTier: Decodable {
    let min_bits: Int
    let id: String
    let color: String
    let images: TwitchApiCheermoteImages
    let can_cheer: Bool
    let show_in_bits_card: Bool
}

// MARK: - Cheermote Images Data Model
struct TwitchApiCheermoteImages: Decodable {
    let dark: TwitchApiCheermoteImageSet
    let light: TwitchApiCheermoteImageSet
}

// MARK: - Cheermote Image Set (Different Sizes)
struct TwitchApiCheermoteImageSet: Decodable {
    let animated: TwitchApiCheermoteImageSizes?
    let staticImages: TwitchApiCheermoteImageSizes?

    private enum CodingKeys: String, CodingKey {
        case animated
        case staticImages = "static"
    }
}

// MARK: - Cheermote Image Sizes
struct TwitchApiCheermoteImageSizes: Decodable {
    let url_1x: String
    let url_2x: String
    let url_4x: String
}
