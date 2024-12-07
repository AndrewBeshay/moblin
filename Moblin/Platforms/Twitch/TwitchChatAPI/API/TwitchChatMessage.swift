public struct ChatMessage {
    public let channel: String
    public let emotes: [Emote]
    public let badges: [String]
    public let sender: String
    public let userId: String?
    public let senderColor: String?
    public let text: String
    public let announcement: Bool
    public let firstMessage: Bool
    public let subscriber: Bool
    public let moderator: Bool
    public let turbo: Bool
    public let bits: String?

    public init?(_ message: Message) {
        guard message.parameters.count == 2,
              let channel = message.parameters.first,
              let text = message.parameters.last,
              let sender = message.sender
        else { return nil }

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
            announcement = message.messageId == "announcement"
        default:
            return nil
        }

        self.channel = channel
        self.emotes = message.emotes
        self.badges = message.badges
        self.text = text
        self.sender = sender
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

private extension Message {
    var sender: String? {
        if let displayName = tags["display-name"] {
            return displayName
        } else if let source = sourceString,
                  let senderEndIndex = source.firstIndex(of: "!") {
            return String(source.prefix(upTo: senderEndIndex))
        } else {
            return nil
        }
    }

    var userId: String? {
        tags["user-id"]
    }

    var color: String? {
        tags["color"]
    }

    var emotes: [Emote] {
        guard let emoteString = tags["emotes"] else { return [] }
        return Emote.emotes(from: emoteString)
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
