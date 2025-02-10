import Foundation

public struct ChatMessage {
    public let channel: String

    // New for primary message data
    public let uniqueId: String?        // "id" tag for PRIVMSG
    public let login: String?           // "login" tag for the sender's login
    public let emotes: [TwitchEmote]
    public let emoteSets: [String]      // "emote-sets" tag
    public let badges: [String]
    public let badgeInfo: [String: String]  // Parsed from "badge-info"
    public let sender: String
    public let userId: String?
    public let senderColor: String?
    public let text: String
    public let timestamp: Date?         // from "tmi-sent-ts"
    public let roomId: String?
    
    // Flags for message type/status
    public let announcement: Bool
    public let firstMessage: Bool
    public let subscriber: Bool
    public let moderator: Bool
    public let turbo: Bool
    public let bits: String?
    
    // New shared chat fields (optional)
    public let sourceBadges: [String]   // "source-badges" tag
    public let sourceUserId: String?    // "source-user-id" tag
    public let sourceDisplayName: String?  // "source-display-name" tag
    public let sourceLogin: String?        // "source-login" tag
    public let sourceColor: String?        // "source-color" tag
    public let sourceRoomId: String?

    public var description: String {
        var components: [String] = []
        components.append("ChatMessage:")
        components.append("  Channel: \(channel)")
        if let uniqueId = uniqueId { components.append("  Unique ID: \(uniqueId)") }
        if let login = login { components.append("  Login: \(login)") }
        if !emotes.isEmpty { components.append("  Emotes: \(emotes)") }
        if !emoteSets.isEmpty { components.append("  Emote Sets: \(emoteSets.joined(separator: ", "))") }
        if !badges.isEmpty { components.append("  Badges: \(badges.joined(separator: ", "))") }
        if !badgeInfo.isEmpty { components.append("  Badge Info: \(badgeInfo)") }
        components.append("  Sender: \(sender)")
        if let userId = userId { components.append("  User ID: \(userId)") }
        if let senderColor = senderColor { components.append("  Sender Color: \(senderColor)") }
        components.append("  Text: \(text)")
        if let timestamp = timestamp {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            components.append("  Timestamp: \(formatter.string(from: timestamp))")
        }
        if let roomId = roomId { components.append("  Room ID: \(roomId)") }

        components.append("  Flags:")
        components.append("    Announcement: \(announcement)")
        components.append("    First Message: \(firstMessage)")
        components.append("    Subscriber: \(subscriber)")
        components.append("    Moderator: \(moderator)")
        components.append("    Turbo: \(turbo)")
        if let bits = bits { components.append("    Bits: \(bits)") }

        if !sourceBadges.isEmpty { components.append("  Source Badges: \(sourceBadges.joined(separator: ", "))") }
        if let sourceUserId = sourceUserId { components.append("  Source User ID: \(sourceUserId)") }
        if let sourceDisplayName = sourceDisplayName { components.append("  Source Display Name: \(sourceDisplayName)") }
        if let sourceLogin = sourceLogin { components.append("  Source Login: \(sourceLogin)") }
        if let sourceColor = sourceColor { components.append("  Source Color: \(sourceColor)") }
        if let sourceRoomId = sourceRoomId { components.append("  Source Room ID: \(sourceRoomId)") }

        return components.joined(separator: "\n")
    }
    
    public init?(_ message: Message) {
        // Ensure we have a channel, text, and valid sender.
        guard message.parameters.count >= 2,
              let channel = message.parameters.first,
              let text = message.parameters.last,
              let sender = message.sender else {
            return nil
        }
        
        var announcement = false
        var firstMessage = false
        var subscriber = false
        var moderator = false
        var turbo = false
        
        // Extract new common fields.
        let uniqueId = message.uniqueId           // from the "id" tag (for PRIVMSG/USERNOTICE)
        let timestamp = message.tmiSentTs          // converted from "tmi-sent-ts"
        let login = message.login
        let badgeInfo = message.badgeInfo ?? [:]

        // Process message flags based on type.
        switch message.command {
        case .privateMessage:
            firstMessage = message.first_message == "1"
            subscriber = message.subscriber == "1"
            moderator = message.moderator == "1"
            turbo = message.turbo == "1"
        case .userNotice:
            announcement = message.noticeType == "announcement"
        default:
            return nil
        }

        self.channel = channel
        self.uniqueId = uniqueId
        self.login = login
        self.emotes = message.emotes
        self.emoteSets = message.emoteSets
        self.badges = message.badges
        self.badgeInfo = badgeInfo
        self.text = text
        self.sender = sender
        self.userId = message.userId
        self.senderColor = message.color
        self.timestamp = timestamp
        self.announcement = announcement
        self.firstMessage = firstMessage
        self.subscriber = subscriber
        self.moderator = moderator
        self.turbo = turbo
        self.bits = message.bits
        self.roomId = message.roomId

        // Populate shared chat fields. These tags will be empty if not applicable.
        self.sourceBadges = message.sourceBadges
        self.sourceUserId = message.sourceUserId
        self.sourceDisplayName = message.sourceDisplayName
        self.sourceLogin = message.sourceLogin
        self.sourceColor = message.sourceColor
        self.sourceRoomId = message.sourceRoomId
    }
}


private extension Message {
    var sender: String? {
        if let displayName = tags["display-name"], !displayName.isEmpty {
            return displayName
        } else if let source = sourceString,
                  let senderEndIndex = source.firstIndex(of: "!") {
            return String(source.prefix(upTo: senderEndIndex))
        } else {
            return nil
        }
    }
    
    var userId: String? {
        return tags["user-id"]
    }
    
    var color: String? {
        return tags["color"]
    }
    
    var emotes: [TwitchEmote] {
        guard let emoteString = tags["emotes"] else { return [] }
        return TwitchEmote.emotes(from: emoteString)
    }
    
    var badges: [String] {
        guard let badges = tags["badges"] else { return [] }
        return badges.split(separator: ",").map(String.init)
    }
    
    // New: Unique message identifier ("id" tag)
    var uniqueId: String? {
        return tags["id"]
    }
    
    // New: Notice type for USERNOTICE ("msg-id" tag)
    var noticeType: String? {
        return tags["msg-id"]
    }
    
    var first_message: String? {
        return tags["first-msg"]
    }
    
    var subscriber: String? {
        return tags["subscriber"]
    }
    
    var moderator: String? {
        return tags["mod"]
    }
    
    var turbo: String? {
        return tags["turbo"]
    }
    
    var bits: String? {
        return tags["bits"]
    }
    
    // New: User login ("login" tag)
    var login: String? {
        return tags["login"]
    }
    
    // New: Parse "badge-info" into a dictionary.
    var badgeInfo: [String: String]? {
        guard let badgeInfoString = tags["badge-info"], !badgeInfoString.isEmpty else {
            return nil
        }
        var info: [String: String] = [:]
        let pairs = badgeInfoString.split(separator: ",")
        for pair in pairs {
            let components = pair.split(separator: "/")
            if components.count == 2 {
                info[String(components[0])] = String(components[1])
            }
        }
        return info
    }
    
    // New: Convert "tmi-sent-ts" (milliseconds UNIX timestamp) to a Date.
    var tmiSentTs: Date? {
        guard let tsString = tags["tmi-sent-ts"],
              let tsDouble = Double(tsString) else {
            return nil
        }
        return Date(timeIntervalSince1970: tsDouble / 1000)
    }
    
    // New: Parse "emote-sets" into an array.
    var emoteSets: [String] {
        guard let sets = tags["emote-sets"], !sets.isEmpty else {
            return []
        }
        return sets.split(separator: ",").map(String.init)
    }
    
    var roomId: String? {
        return tags["room-id"]
    }
    
    // === Shared Chat Tags ===
    
    // New: Parse source badges ("source-badges" tag).
    var sourceBadges: [String] {
        guard let badges = tags["source-badges"], !badges.isEmpty else { return [] }
        return badges.split(separator: ",").map(String.init)
    }
    
    // New: Source user ID ("source-user-id" tag).
    var sourceUserId: String? {
        return tags["source-user-id"]
    }
    
    // New: Source display name ("source-display-name" tag).
    var sourceDisplayName: String? {
        return tags["source-display-name"]
    }
    
    // New: Source login name ("source-login" tag).
    var sourceLogin: String? {
        return tags["source-login"]
    }
    
    // New: Source color ("source-color" tag).
    var sourceColor: String? {
        return tags["source-color"]
    }
    
    var sourceRoomId: String? {
        return tags["source-room-id"]
    }
}
