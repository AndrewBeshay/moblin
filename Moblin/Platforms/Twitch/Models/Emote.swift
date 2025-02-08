import Foundation

/// Represents the style in which the Twitch emote image is rendered.
public enum EmoteStyle: String {
    case dark, light
    // Additional cases can be added if Twitch provides more style options.
}

/// An error type representing issues encountered when constructing an emote image URL.
public enum EmoteError: Error {
    /// Indicates that the emote image URL could not be constructed.
    case invalidImageURL
}

/// Represents a Twitch emote with an identifier and the range in the chat message where it appears.
public struct TwitchEmote {
    /// The unique identifier for the emote.
    private let identifier: String
    
    /// The range within the chat message where the emote is found.
    public let range: ClosedRange<Int>
    
    /// Creates an `Emote` with the given identifier and range.
    /// - Parameters:
    ///   - identifier: The unique identifier for the emote.
    ///   - range: The closed range (inclusive) indicating the position of the emote in the message.
    private init(identifier: String, range: ClosedRange<Int>) {
        self.identifier = identifier
        self.range = range
    }
    
    /// Generates the URL for the emote image.
    /// - Parameter style: The visual style for the emote (default is `.dark`).
    /// - Throws: An `EmoteError.invalidImageURL` error if the URL cannot be constructed.
    /// - Returns: A `URL` pointing to the emote image.
    public func imageURL(for style: EmoteStyle = .dark) throws -> URL {
        let urlString = "https://static-cdn.jtvnw.net/emoticons/v2/\(identifier)/default/\(style.rawValue)/3.0"
        guard let url = URL(string: urlString) else {
            throw EmoteError.invalidImageURL
        }
        return url
    }
    
    /// Parses a raw emote string into an array of `Emote` instances.
    ///
    /// The raw string typically contains one or more emote definitions separated by slashes (`/`).
    /// Each definition is expected in the format: `emoteID:start-end[,start-end...]`
    ///
    /// - Parameter string: The raw string containing emote definitions.
    /// - Returns: An array of `Emote` objects parsed from the string.
    public static func emotes(from string: String) -> [TwitchEmote] {
        let emoteDefinitions = string.split(separator: "/")
        return emoteDefinitions.flatMap { TwitchEmote.emotes(fromDefinition: $0) }
    }
    
    /// Parses an individual emote definition into an array of `Emote` instances.
    ///
    /// A single definition might include multiple ranges (if the same emote appears in different positions).
    ///
    /// - Parameter definition: A substring representing a single emote definition.
    /// - Returns: An array of `Emote` instances, one for each valid range found.
    private static func emotes(fromDefinition definition: Substring) -> [TwitchEmote] {
        // Split the definition into the emote ID and the ranges string.
        let parts = definition.split(separator: ":")
        guard parts.count == 2,
              let emoteID = parts.first,
              let emoteRangesString = parts.last else {
            return []
        }
        
        let emoteIDString = String(emoteID)
        
        // Process the ranges. Each range is given as "start-end" and multiple ranges are comma-separated.
        let emoteRanges: [ClosedRange<Int>] = emoteRangesString.split(separator: ",").compactMap { rangeString in
            let rangeComponents = rangeString.split(separator: "-")
            guard rangeComponents.count == 2,
                  let startStr = rangeComponents.first,
                  let endStr = rangeComponents.last,
                  let start = Int(startStr),
                  let end = Int(endStr),
                  start <= end else {
                // If the range is invalid (e.g. start > end), skip it.
                return nil
            }
            return start...end
        }
        
        // Create an Emote for each valid range.
        return emoteRanges.map { TwitchEmote(identifier: emoteIDString, range: $0) }
    }
}
