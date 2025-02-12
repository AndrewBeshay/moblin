//
//  TwitchAPINetworking.swift
//  Moblin
//

import Foundation

class TwitchApiNetworking {
    private let clientId: String
    private let accessToken: String
    private let urlSession: URLSession
    weak var delegate: TwitchApiDelegate?

    init(clientId: String, accessToken: String, urlSession: URLSession) {
        self.clientId = clientId
        self.accessToken = accessToken
        self.urlSession = urlSession
    }

    func sendRequest(
        method: String,
        subPath: String,
        body: Data? = nil,
        onComplete: @escaping (Data?, URLResponse?, Error?) -> Void
    ) {
        guard let url = URL(string: "https://api.twitch.tv/helix/\(subPath)") else {
            onComplete(nil, nil, NSError(domain: "TwitchAPI", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(clientId, forHTTPHeaderField: "Client-Id")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        if let body = body, method != "GET" {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }

        logger.info("📡 Sending \(method) request to \(url.absoluteString)")

        let task = urlSession.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                onComplete(data, response, error)
            }
        }
        task.resume()
    }
}
