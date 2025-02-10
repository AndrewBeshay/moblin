//
//  ChatModel.swift
//  Moblin
//
//  Created by Andrew Beshay on 9/2/2025.
//
import Foundation
import SwiftUICore

struct ChatMessageEmote: Identifiable {
    var id = UUID()
    var url: URL
    var range: ClosedRange<Int>
}

struct ChatPostSegment: Identifiable, Codable {
    var id: Int
    var text: String?
    var url: URL?
}

func makeChatPostTextSegments(text: String, id: inout Int) -> [ChatPostSegment] {
    var segments: [ChatPostSegment] = []
    for word in text.split(separator: " ") {
        segments.append(ChatPostSegment(
            id: id,
            text: "\(word) "
        ))
        id += 1
    }
    return segments
}

enum ChatHighlightKind: Codable {
    case redemption
    case other
    case firstMessage
    case newFollower
}

struct ChatHighlight {
    let kind: ChatHighlightKind
    let color: Color
    let image: String
    let title: String

    func toWatchProtocol() -> WatchProtocolChatHighlight {
        let watchProtocolKind: WatchProtocolChatHighlightKind
        switch kind {
        case .redemption:
            watchProtocolKind = .redemption
        case .other:
            watchProtocolKind = .other
        case .newFollower:
            watchProtocolKind = .redemption
        case .firstMessage:
            watchProtocolKind = .other
        }
        let color = color.toRgb() ?? .init(red: 0, green: 255, blue: 0)
        return WatchProtocolChatHighlight(
            kind: watchProtocolKind,
            color: .init(red: color.red, green: color.green, blue: color.blue),
            image: image,
            title: title
        )
    }
}

enum ChatPostType: String, Codable {
        case normal // Regular user chat post
        case system // System messages (e.g. "messaged deleted by xxx")
}

struct ChatPost: Identifiable, Equatable {
    static func == (lhs: ChatPost, rhs: ChatPost) -> Bool {
        return lhs.id == rhs.id &&
        lhs.isRevealed == rhs.isRevealed
    }

    var id: UUID
    var type: ChatPostType = .normal
    var user: String?
    var userId: String?
    var userColor: RgbColor?
    var userBadges: [URL]
    var segments: [ChatPostSegment]
    var timestamp: String
    var timestampTime: ContinuousClock.Instant
    var isAction: Bool
    var isSubscriber: Bool
    var bits: String?
    var highlight: ChatHighlight?
    var live: Bool
    var messageId: String?
    
    /// Flag indicating that the message has been deleted.
    var isDeleted: Bool = false
    /// Stores the original segments before deletion, so they can be revealed later.
    var originalSegments: [ChatPostSegment]? = nil
    
    /// Flag tracking whether the deleted message is currently revealed.
    /// When false, the UI will show a placeholder; when true, the original message is displayed.
    var isRevealed: Bool = false
    
    /// If this is a system message, store its text here.
    /// For example, this might be "<message deleted>".
    var systemText: String?
    
    var sourceRoomId: String?
    
    /// Returns the segments to display.
    /// If the message is deleted and not revealed, returns a placeholder segment.
    /// Otherwise, returns the original segments (if available) or the current segments.
    var displaySegments: [ChatPostSegment] {
        if type == .system, let systemText = systemText {
            // For system messages, always display the systemText.
            return [ChatPostSegment(id: -2, text: systemText, url: nil)]
        } else if isDeleted && !isRevealed {
            // Use a unique ID (here -1 is used as a placeholder)
            return [ChatPostSegment(id: -1, text: "<message deleted>", url: nil)]
        } else {
            return segments
        }
    }
    
    /// Returns whether this message is considered a redemption.
    func isRedemption() -> Bool {
        return highlight?.kind == .redemption || highlight?.kind == .newFollower
    }
}
