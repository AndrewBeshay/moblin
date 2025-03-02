//
//  EventSubDelegate.swift
//  Moblin
//
//  Created by Andrew Beshay on 2/3/2025.
//

// MARK: - EventSubDelegate Protocol

/**
 Protocol for handling EventSub events
 */
protocol EventSubDelegate: AnyObject {
    // Connection error handling
    func eventSubMakeErrorToast(title: String)
    func eventSubUnauthorized()
    
    // Raw message notification
    func eventSubNotification(message: String)
    
    // Channel events
    func eventSubChannelFollow(event: EventSubFollowEvent)
    func eventSubChannelSubscribe(event: EventSubSubscribeEvent)
    func eventSubChannelSubscriptionGift(event: EventSubSubscriptionGiftEvent)
    func eventSubChannelSubscriptionMessage(event: EventSubSubscriptionMessageEvent)
    func eventSubChannelRaid(event: EventSubRaidEvent)
    func eventSubChannelCheer(event: EventSubCheerEvent)
    func eventSubChannelModerate(event: EventSubModerateMessage)
    
    // Shared chat events
    func eventSubSharedChatBegin(event: EventSubSharedChatEvent)
    func eventSubSharedChatUpdate(event: EventSubSharedChatEvent)
    func eventSubSharedChatEnd(event: EventSubSharedChatEndEvent)
}

// Default implementations
extension EventSubDelegate {
    func eventSubMakeErrorToast(title: String) {}
    func eventSubUnauthorized() {}
    func eventSubNotification(message: String) {}
    func eventSubChannelFollow(event: EventSubFollowEvent) {}
    func eventSubChannelSubscribe(event: EventSubSubscribeEvent) {}
    func eventSubChannelSubscriptionGift(event: EventSubSubscriptionGiftEvent) {}
    func eventSubChannelSubscriptionMessage(event: EventSubSubscriptionMessageEvent) {}
    func eventSubChannelRaid(event: EventSubRaidEvent) {}
    func eventSubChannelCheer(event: EventSubCheerEvent) {}
    func eventSubChannelModerate(event: EventSubModerateMessage) {}
    func eventSubSharedChatBegin(event: EventSubSharedChatEvent) {}
    func eventSubSharedChatUpdate(event: EventSubSharedChatEvent) {}
    func eventSubSharedChatEnd(event: EventSubSharedChatEndEvent) {}
}
