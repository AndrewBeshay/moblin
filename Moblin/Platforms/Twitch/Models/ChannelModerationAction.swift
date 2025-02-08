//
//  ChannelModerationAction.swift
//  Moblin
//

/// Represents a moderation action from a Twitch channel.moderate event.
enum ChannelModerationAction: String, CodingKey {
    case ban
    case timeout
    case unban
    case untimeout
    case clear
    case emoteonly
    case emoteonlyoff
    case followers
    case followersoff
    case uniquechat
    case uniquechatoff
    case slow
    case slowoff
    case subscribers
    case subscribersoff
    case unraid
    case delete
    case unvip
    case vip
    case raid
    case addBlockedTerm
    case addPermittedTerm
    case removeBlockedTerm
    case removePermittedTerm
    case mod
    case unmod
    case approveUnbanRequest
    case denyUnbanRequest
    case warn
    case sharedChatBan
    case sharedChatTimeout
    case sharedChatUnban
    case sharedChatUntimeout
    case sharedChatDelete
}
