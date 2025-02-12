//
//  TwitchAPIEventSub.swift
//  Moblin
//

import Foundation

final class TwitchAPIEventSub {
    private let api: TwitchAPI

    init(api: TwitchAPI) {
        self.api = api
    }

    // MARK: - Get EventSub Subscriptions
    func getEventSubSubscriptions(onComplete: @escaping ([TwitchApiEventSubSubscription]?, Int?, Int?, Int?) -> Void) {
        api.sendRequest(
            method: "GET",
            subPath: "eventsub/subscriptions",
            onComplete: decode(TwitchApiGetEventSubSubscriptionsResponse.self) {
                onComplete($0?.data, $0?.total, $0?.total_cost, $0?.max_total_cost)
            }
        )
    }

    // MARK: - Create EventSub Subscription
    func createEventSubSubscription(type: String, version: String, condition: [String: String], transport: TwitchApiEventSubTransport, onComplete: @escaping ([TwitchApiEventSubSubscription]?) -> Void) {

        logger.info("📡 Attempting to create EventSub subscription...")
        logger.info("🔹 Subscription Type: \(type)")
        logger.info("🔹 Version: \(version)")
        logger.info("🔹 Condition: \(condition)")
        logger.info("🔹 Transport Method: \(transport.method)")

        let requestBody = TwitchApiCreateEventSubSubscriptionRequest(
            type: type,
            version: version,
            condition: condition,
            transport: transport
        )

        guard let jsonData = try? JSONEncoder().encode(requestBody) else {
            logger.error("❌ Failed to encode JSON payload for creating EventSub subscription")
            onComplete(nil)
            return
        }
        
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            logger.info("📨 EventSub Request Payload: \(jsonString)")
        } else {
            logger.error("❌ JSON Encoding Failed: Invalid request body")
        }

        logger.info("📨 Sending EventSub subscription request...")

        api.sendRequest(
            method: "POST",
            subPath: "eventsub/subscriptions",
            body: jsonData
        ) { data, response  in
            guard let data = data else {
                logger.error("❌ EventSub API request failed: No data returned")
                onComplete(nil)
                return
            }

            // Log HTTP Response Body
            if let responseString = String(data: data, encoding: .utf8) {
                logger.error("❌ EventSub API Response: \(responseString)")
            }

            self.decode(TwitchApiCreateEventSubSubscriptionResponse.self) { response in
                if let data = response?.data, !data.isEmpty {
                    logger.info("✅ Successfully created EventSub subscription with ID: \(data.first!.id)")
                } else {
                    logger.error("❌ Failed to create EventSub subscription. No valid data returned.")
                    logger.error("\(response)")
                }
                onComplete(response?.data)
            }(data, response) // 🔹 Call the returned closure with 'data'
        }
    }

    // MARK: - Delete EventSub Subscription
    func deleteEventSubSubscription(subscriptionId: String, onComplete: @escaping (Bool) -> Void) {
        let subPath = "eventsub/subscriptions?id=\(subscriptionId)"

        api.sendRequest(
            method: "DELETE",
            subPath: subPath,
            onComplete: decode(TwitchApiDeleteEventSubSubscriptionResponse.self) {
                onComplete($0?.success ?? false)
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

// MARK: - Get EventSub Subscriptions Response
struct TwitchApiGetEventSubSubscriptionsResponse: Decodable {
    let data: [TwitchApiEventSubSubscription]
    let total: Int?
    let total_cost: Int
    let max_total_cost: Int
    let pagination: TwitchApiPagination?
}

// MARK: - EventSub Subscription Data Model
struct TwitchApiEventSubSubscription: Codable {
    let id: String
    let status: String // "enabled", "pending", "webhook_callback_verification_pending", etc.
    let type: String
    let version: String
    let condition: [String: String]
    let transport: TwitchApiEventSubTransport
    let created_at: String
}

// MARK: - EventSub Transport Data Model
struct TwitchApiEventSubTransport: Codable {
    let method: String // "webhook", "websocket"
    let callback: String?
    let secret: String?
    let session_id: String?
}

// MARK: - Create EventSub Subscription Request
struct TwitchApiCreateEventSubSubscriptionRequest: Encodable {
    let type: String
    let version: String
    let condition: [String: String]
    let transport: TwitchApiEventSubTransport
}

// MARK: - Create EventSub Subscription Response
struct TwitchApiCreateEventSubSubscriptionResponse: Decodable {
    let data: [TwitchApiEventSubSubscription]
}

// MARK: - Delete EventSub Subscription Response
struct TwitchApiDeleteEventSubSubscriptionResponse: Decodable {
    let success: Bool
}
