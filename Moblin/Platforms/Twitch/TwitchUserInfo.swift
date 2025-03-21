import Foundation

/// Represents user information from Twitch
struct TwitchUserInfo: Codable {
    let id: String
    let login: String
    let displayName: String
    let profileImageUrl: String
    let email: String?
    let broadcasterType: String
    let description: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case login
        case displayName = "display_name"
        case profileImageUrl = "profile_image_url"
        case email
        case broadcasterType = "broadcaster_type"
        case description
        case createdAt = "created_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        login = try container.decode(String.self, forKey: .login)
        displayName = try container.decode(String.self, forKey: .displayName)
        profileImageUrl = try container.decode(String.self, forKey: .profileImageUrl)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        broadcasterType = try container.decode(String.self, forKey: .broadcasterType)
        description = try container.decode(String.self, forKey: .description)
        
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: createdAtString) {
            createdAt = date
        } else {
            // Fallback to simpler format if fractional seconds are not present
            formatter.formatOptions = [.withInternetDateTime]
            createdAt = formatter.date(from: createdAtString) ?? Date()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(login, forKey: .login)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(profileImageUrl, forKey: .profileImageUrl)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encode(broadcasterType, forKey: .broadcasterType)
        try container.encode(description, forKey: .description)
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let createdAtString = formatter.string(from: createdAt)
        try container.encode(createdAtString, forKey: .createdAt)
    }
} 