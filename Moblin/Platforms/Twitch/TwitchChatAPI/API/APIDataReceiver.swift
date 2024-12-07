import Foundation
import os

final class APIDataReceiver: NSObject, URLSessionWebSocketDelegate {
    init(token: String, nick: String, name: String, continuation: AsyncThrowingStream<String, Error>.Continuation) {
        self.token = token
        self.nick = nick
        self.name = name
        self.continuation = continuation
    }

    private func readMessage(from task: URLSessionWebSocketTask) {
        Task {
            do {
                let message = try await task.receive()
                switch message {
                case .data(let data):
                    throw APIError.receivedDataMessage(data)
                case .string(let string):
                    for line in string.split(whereSeparator: { $0.isNewline }) {
                        continuation.yield(String(line))
                    }
                @unknown default:
                    throw APIError.receivedUnknownMessage
                }
                readMessage(from: task)
            } catch {
                continuation.finish(throwing: error)
                Logger().debug("twitch: chat: Read message error \(error).")
            }
        }
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        Logger().debug("twitch: chat: Connected.")
        readMessage(from: webSocketTask)
        webSocketTask.send(.string("CAP REQ :twitch.tv/membership"), completionHandler: { _ in })
        webSocketTask.send(.string("CAP REQ :twitch.tv/tags"), completionHandler: { _ in })
        webSocketTask.send(.string("CAP REQ :twitch.tv/commands"), completionHandler: { _ in })
        webSocketTask.send(.string("PASS oauth:\(token)"), completionHandler: { _ in })
        webSocketTask.send(.string("NICK \(nick)"), completionHandler: { _ in })
        webSocketTask.send(.string("JOIN #\(name)"), completionHandler: { _ in })
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        Logger().debug("twitch: chat: Disconnected.")
        continuation.finish()
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        Logger().debug("twitch: chat: Completed.")
        continuation.finish()
    }
    
    private let token: String
    private let nick: String
    private let name: String
    private let continuation: AsyncThrowingStream<String, Error>.Continuation
}
