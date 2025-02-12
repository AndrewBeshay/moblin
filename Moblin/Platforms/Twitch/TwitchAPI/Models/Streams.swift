//
//  TwitchAPIStreams.swift
//  Moblin
//

import Foundation

final class TwitchAPIStreams {
    private let api: TwitchAPI

    init(api: TwitchAPI) {
        self.api = api
    }
    
    // MARK: - Get Stream Key
    func getStreamKey(broadcasterId: String, onComplete: @escaping (String?) -> Void) {
        let subPath = "streams/key?broadcaster_id=\(broadcasterId)"
        api.sendRequest(method: "GET", subPath: subPath) { data, response  in
            self.decode(TwitchApiStreamKeyResponse.self, data: data) { response in
                onComplete(response?.data.first?.stream_key)
            }
        }
    }
    
    // MARK: - Get Streams
    func getStreams(userIds: [String] = [], gameIds: [String] = [], languages: [String] = [], onComplete: @escaping ([TwitchApiStreamData]?) -> Void) {
        var query = "streams?"
        if !userIds.isEmpty {
            query += userIds.map { "user_id=\($0)" }.joined(separator: "&") + "&"
        }
        if !gameIds.isEmpty {
            query += gameIds.map { "game_id=\($0)" }.joined(separator: "&") + "&"
        }
        if !languages.isEmpty {
            query += languages.map { "language=\($0)" }.joined(separator: "&")
        }
        // Remove trailing '&' if necessary
        let subPath = query.trimmingCharacters(in: CharacterSet(charactersIn: "&"))
        
        api.sendRequest(method: "GET", subPath: subPath) { data, response  in
            self.decode(TwitchApiStreams.self, data: data) { response in
                onComplete(response?.data)
            }
        }
    }
    
    // MARK: - Get Followed Streams
    func getFollowedStreams(userId: String, onComplete: @escaping ([TwitchApiStreamData]?) -> Void) {
        let subPath = "streams/followed?user_id=\(userId)"
        api.sendRequest(method: "GET", subPath: subPath) { data, response in
            self.decode(TwitchApiFollowedStreamsResponse.self, data: data) { response in
                onComplete(response?.data)
            }
        }
    }
    
    // MARK: - Create Stream Marker
    func createStreamMarker(userId: String, description: String?, onComplete: @escaping (TwitchApiCreateStreamMarkerResponse.StreamMarkerData?) -> Void) {
        let requestBody = TwitchApiCreateStreamMarkerRequest(user_id: userId, description: description)
        guard let jsonData = try? JSONEncoder().encode(requestBody) else {
            print("❌ Failed to encode JSON payload for creating stream marker")
            onComplete(nil)
            return
        }
        
        api.sendRequest(method: "POST", subPath: "streams/markers", body: jsonData) { data, response in
            self.decode(TwitchApiCreateStreamMarkerResponse.self, data: data) { response in
                onComplete(response?.data.first)
            }
        }
    }
    
    // MARK: - Helper Method for JSON Decoding
    private func decode<T: Decodable>(_ type: T.Type, data: Data?, onComplete: @escaping (T?) -> Void) {
        guard let data = data else { onComplete(nil); return }
        onComplete(try? JSONDecoder().decode(T.self, from: data))
    }
}

// MARK: - Data Models

// Get Stream Key Response
struct TwitchApiStreamKeyResponse: Decodable {
    let data: [StreamKeyData]
    
    struct StreamKeyData: Decodable {
        let stream_key: String
    }
}

// Get Streams Response
struct TwitchApiStreams: Decodable {
    let data: [TwitchApiStreamData]
}

struct TwitchApiStreamData: Decodable {
    let id: String
    let user_id: String
    let user_name: String
    let game_id: String
    let game_name: String
    let type: String   // "live" or ""
    let title: String
    let viewer_count: Int
    let started_at: String
    let language: String
    let thumbnail_url: String
}

// Get Followed Streams Response
struct TwitchApiFollowedStreamsResponse: Decodable {
    let data: [TwitchApiStreamData]
}

// Create Stream Marker Request
struct TwitchApiCreateStreamMarkerRequest: Encodable {
    let user_id: String
    let description: String?
}

// Create Stream Marker Response
struct TwitchApiCreateStreamMarkerResponse: Decodable {
    let data: [StreamMarkerData]
    
    struct StreamMarkerData: Decodable {
        let id: String
        let created_at: String
        let position_seconds: Int
        let description: String?
    }
}
