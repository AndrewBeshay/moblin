//
//  TwitchAPIChannel.swift
//  Moblin
//

import Foundation

final class TwitchAPIChannel {
    private let api: TwitchAPI

    init(api: TwitchAPI) {
        self.api = api
    }

    // MARK: - Get Channel Information
    func getChannelInformation(
        broadcasterId: String,
        retryCount: Int = 3,
        delay: TimeInterval = 2.0,
        onComplete: @escaping (TwitchApiChannelInformationData?, String?) -> Void
    ) {
        api.sendRequest(
            method: "GET",
            subPath: "channels?broadcaster_id=\(broadcasterId)",
            onComplete: { [weak self] data, response in
                guard let self = self else { return }
                
                let httpStatusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                
                switch httpStatusCode {
                    case 200:
                        // ✅ Successfully retrieved data
                        if let data = data {
                            let decodedData = try? JSONDecoder().decode(TwitchApiChannelInformationResponse.self, from: data)
                            onComplete(decodedData?.data.first, nil)
                        } else {
                            onComplete(nil, "Received 200 OK but response body is empty.")
                        }
                    
                    case 204:
                        // ✅ No Content, but still successful
                        print("✅ 204 No Content received: Channel exists but no additional data available.")
                        onComplete(nil, nil) // No data, but not an error
                    
                    case 400:
                        print("❌ 400 Bad Request: Invalid broadcaster ID or missing parameter.")
                        onComplete(nil, "400 Bad Request: Invalid broadcaster ID or missing parameter.")
                    
                    case 401:
                        print("❌ 401 Unauthorized: Invalid or missing authentication token.")
                        onComplete(nil, "401 Unauthorized: Invalid or missing authentication token.")
                    
                    case 429:
                        if retryCount > 0 {
                            let newDelay = delay * 2 // Exponential backoff
                            print("⚠️ 429 Too Many Requests. Retrying in \(newDelay) seconds...")
                            DispatchQueue.global().asyncAfter(deadline: .now() + newDelay) {
                                self.getChannelInformation(
                                    broadcasterId: broadcasterId,
                                    retryCount: retryCount - 1,
                                    delay: newDelay,
                                    onComplete: onComplete
                                )
                            }
                        } else {
                            print("❌ 429 Too Many Requests: Exceeded retry limit.")
                            onComplete(nil, "429 Too Many Requests: Please wait before retrying.")
                        }
                    
                    case 500:
                        print("❌ 500 Internal Server Error: Twitch API issue.")
                        onComplete(nil, "500 Internal Server Error: Try again later.")
                    
                    default:
                        print("❌ Unexpected HTTP Status: \(httpStatusCode)")
                        onComplete(nil, "Unexpected error: HTTP \(httpStatusCode)")
                }
            }
        )
    }

    // MARK: - Modify Channel Information
    func modifyChannelInformation(
        broadcasterId: String,
        category: String?,
        title: String?,
        language: String?,
        delay: Int?,
        onComplete: @escaping (Bool, String?) -> Void
    ) {
        var payload: [String: Any] = [:]
        if let category { payload["game_id"] = category }
        if let title { payload["title"] = title }
        if let language { payload["broadcaster_language"] = language }
        if let delay { payload["delay"] = delay }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            print("❌ Failed to encode JSON payload for modifying channel information")
            onComplete(false, "Failed to encode JSON payload")
            return
        }

        api.sendRequest(
            method: "PATCH",
            subPath: "channels?broadcaster_id=\(broadcasterId)",
            body: jsonData,
            onComplete: { data, response in
                let httpStatusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                                
                // ✅ Handle 204 No Content as success
                if httpStatusCode == 204 {
                    logger.debug("✅ 204 No Content received: Channel information updated successfully.")
                    onComplete(true, "Suceeded with HTTP \(httpStatusCode)")
                    return
                }
                
                // ❌ Handle failure cases
                logger.error("❌ Failed to update channel information. HTTP Status: \(httpStatusCode)")
                onComplete(false, "Failed with HTTP \(httpStatusCode)")
            }
        )
    }

    // MARK: - Get Channel Followers
    func getChannelFollowers(
        broadcasterId: String,
        retryCount: Int = 3,
        delay: TimeInterval = 2.0,
        onComplete: @escaping ([TwitchApiFollowerData]?, Int?, String?) -> Void
    ) {
        api.sendRequest(
            method: "GET",
            subPath: "channels/followers?broadcaster_id=\(broadcasterId)",
            onComplete: { [weak self] data, response in
                guard let self = self else { return }

                let httpStatusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

                switch httpStatusCode {
                    case 200:
                        // ✅ Successfully retrieved data
                        if let data = data {
                            let decodedData = try? JSONDecoder().decode(TwitchApiChannelFollowersResponse.self, from: data)
                            onComplete(decodedData?.data, decodedData?.total, nil)
                        } else {
                            onComplete(nil, nil, "Received 200 OK but response body is empty.")
                        }
                    
                    case 400:
                        print("❌ 400 Bad Request: Invalid broadcaster ID or missing parameter.")
                        onComplete(nil, nil, "400 Bad Request: Invalid broadcaster ID or missing parameter.")
                    
                    case 401:
                        print("❌ 401 Unauthorized: Missing or invalid authentication token.")
                        onComplete(nil, nil, "401 Unauthorized: Missing or invalid authentication token. Ensure the OAuth token is valid and contains the required scope.")
                    
                    default:
                        print("❌ Unexpected HTTP Status: \(httpStatusCode)")
                        onComplete(nil, nil, "Unexpected error: HTTP \(httpStatusCode)")
                }
            }
        )
    }

    // MARK: - Helper Method for JSON Decoding
    // ✅ Version for handling only `Data?`
    private func decode<T: Decodable>(
        _ type: T.Type,
        _ onComplete: @escaping (T?) -> Void
    ) -> (Data?) -> Void {
        return { data in
            guard let data = data else {
                onComplete(nil)
                return
            }
            onComplete(try? JSONDecoder().decode(T.self, from: data))
        }
    }

    // ✅ Version for handling `(Data?, URLResponse?)`
    private func decode<T: Decodable>(
        _ type: T.Type,
        _ onComplete: @escaping (T?) -> Void
    ) -> (Data?, URLResponse?) -> Void {
        return { data, _ in
            guard let data = data else {
                onComplete(nil)
                return
            }
            onComplete(try? JSONDecoder().decode(T.self, from: data))
        }
    }
}

// MARK: - Get Channel Information Response
struct TwitchApiChannelInformationResponse: Decodable {
    let data: [TwitchApiChannelInformationData]
}

// MARK: - Channel Information Data Model
struct TwitchApiChannelInformationData: Decodable {
    let broadcaster_id: String
    let broadcaster_name: String
    let broadcaster_language: String
    let game_id: String
    let game_name: String
    let title: String
    let delay: Int
    let tags: [String]?
}

// MARK: - Modify Channel Information Request
struct TwitchApiModifyChannelInformationRequest: Encodable {
    let game_id: String?
    let title: String?
    let broadcaster_language: String?
    let delay: Int?
}

// MARK: - Get Channel Followers Response
struct TwitchApiChannelFollowersResponse: Decodable {
    let total: Int
    let data: [TwitchApiFollowerData]
}

// MARK: - Follower Data Model
struct TwitchApiFollowerData: Decodable {
    let user_id: String
    let user_name: String
    let followed_at: String
}
