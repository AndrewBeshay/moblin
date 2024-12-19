public struct ChatMessage {
    public let messageId: String? // Add the messageId property
    public let channel: String
    public let emotes: [TwitchEmote]
    public let badges: [String]
    public let displayName: String
    public let loginName: String
    public let userId: String?
    public let senderColor: String?
    public let text: String
    public let announcement: Bool
    public let firstMessage: Bool
    public let subscriber: Bool
    public let moderator: Bool
    public let turbo: Bool
    public let bits: String?

    public init?(_ message: TwitchMessage) {
        guard message.parameters.count == 2,
              let channel = message.parameters.first,
              let text = message.parameters.last,
              let loginName = message.loginName
        else {
            print("ChatMessage initialization failed due to invalid parameters.")
            return nil
        }
        
//        let displayName = message.displayName ?? (message.displayName! + loginName)
        // Parse displayName, defaulting to loginName if unavailable
        
        logger.debug(message.displayName ?? "")
        logger.debug(loginName)
        var displayName = message.displayName ?? loginName
        
        // Check if the display name contains non-English characters
        if displayName.range(of: "\\P{ASCII}", options: .regularExpression) != nil {
            // Append the English equivalent in parentheses
            displayName = "\(displayName) (\(loginName))"
        }
        
        logger.debug(displayName)
        
        // Parse messageId from message.tags
        self.messageId = message.tags["id"] // Extract the message ID here
        
        var announcement = false
        var firstMessage = false
        var subscriber = false
        var moderator = false
        var turbo = false

        switch message.command {
        case .privateMessage:
            firstMessage = message.first_message == "1"
            subscriber = message.subscriber == "1"
            moderator = message.moderator == "1"
            turbo = message.turbo == "1"
        case .userNotice:
            announcement = messageId == "announcement"
        default:
            return nil
        }

        self.channel = channel
        self.emotes = message.emotes
        self.badges = message.badges
        self.text = text
        self.displayName = displayName
        self.loginName = loginName
        self.userId = message.userId
        self.senderColor = message.color
        self.announcement = announcement
        self.firstMessage = firstMessage
        self.subscriber = subscriber
        self.moderator = moderator
        self.turbo = turbo
        self.bits = message.bits
    }
}

private extension TwitchMessage {
    var displayName: String? {
        tags["display-name"]
    }
    
    var loginName: String? {
        if let source = sourceString,
           let senderEndIndex = source.firstIndex(of: "!") {
            return String(source.prefix(upTo: senderEndIndex))
        }
        return nil
    }

    var userId: String? {
        tags["user-id"]
    }

    var color: String? {
        tags["color"]
    }

    var emotes: [TwitchEmote] {
        guard let emoteString = tags["emotes"] else { return [] }
        return TwitchEmote.emotes(from: emoteString)
    }
    
    var badges: [String] {
        guard let badges = tags["badges"] else {
            return []
        }
        return badges.split(separator: ",").map({String($0)})
    }

    var messageId: String? {
        tags["msg-id"]
    }

    var first_message: String? {
        tags["first-msg"]
    }
    
    var subscriber: String? {
        tags["subscriber"]
    }

    var moderator: String? {
        tags["mod"]
    }

    var turbo: String? {
        tags["turbo"]
    }
    
    var bits: String? {
        tags["bits"]
    }
}
