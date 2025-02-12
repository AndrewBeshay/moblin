//
//  TwitchAPIAds.swift
//  Moblin
//

import Foundation

final class TwitchAPIAds {
    private let api: TwitchAPI

    init(api: TwitchAPI) {
        self.api = api
    }

    // MARK: - Start Commercial
    func startCommercial(broadcasterId: String, length: Int, onComplete: @escaping (TwitchApiCommercial?) -> Void) {
        let requestBody = TwitchApiStartCommercialRequest(broadcaster_id: broadcasterId, length: length)

        guard let jsonData = try? JSONEncoder().encode(requestBody) else {
            print("❌ Failed to encode JSON payload for starting a commercial")
            onComplete(nil)
            return
        }

        api.sendRequest(
            method: "POST",
            subPath: "channels/commercial",
            body: jsonData,
            onComplete: decode(TwitchApiStartCommercialResponse.self) {
                onComplete($0?.data.first)
            }
        )
    }

    // MARK: - Get Ad Schedule
    func getAdSchedule(broadcasterId: String, onComplete: @escaping (TwitchApiAdSchedule?) -> Void) {
        api.sendRequest(
            method: "GET",
            subPath: "channels/ad_schedule?broadcaster_id=\(broadcasterId)",
            onComplete: decode(TwitchApiGetAdScheduleResponse.self) {
                onComplete($0?.data.first)
            }
        )
    }

    // MARK: - Snooze Next Ad
    func snoozeNextAd(broadcasterId: String, onComplete: @escaping (TwitchApiAdSchedule?) -> Void) {
        let requestBody = TwitchApiSnoozeNextAdRequest(broadcaster_id: broadcasterId)

        guard let jsonData = try? JSONEncoder().encode(requestBody) else {
            print("❌ Failed to encode JSON payload for snoozing next ad")
            onComplete(nil)
            return
        }

        api.sendRequest(
            method: "POST",
            subPath: "channels/ad_schedule/snooze",
            body: jsonData,
            onComplete: decode(TwitchApiSnoozeNextAdResponse.self) {
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

// MARK: - Start Commercial Request
struct TwitchApiStartCommercialRequest: Encodable {
    let broadcaster_id: String
    let length: Int
}

// MARK: - Start Commercial Response
struct TwitchApiStartCommercialResponse: Decodable {
    let data: [TwitchApiCommercial]
}

// MARK: - Commercial Data Model
struct TwitchApiCommercial: Decodable {
    let length: Int
    let message: String
    let retry_after: Int
}

// MARK: - Get Ad Schedule Response
struct TwitchApiGetAdScheduleResponse: Decodable {
    let data: [TwitchApiAdSchedule]
}

// MARK: - Ad Schedule Data Model
struct TwitchApiAdSchedule: Decodable {
    let broadcaster_id: String
    let last_ad_at: String?
    let next_ad_at: String?
    let duration_seconds: Int
    let snooze_count: Int
}

// MARK: - Snooze Next Ad Request
struct TwitchApiSnoozeNextAdRequest: Encodable {
    let broadcaster_id: String
}

// MARK: - Snooze Next Ad Response
struct TwitchApiSnoozeNextAdResponse: Decodable {
    let data: [TwitchApiAdSchedule]
}
