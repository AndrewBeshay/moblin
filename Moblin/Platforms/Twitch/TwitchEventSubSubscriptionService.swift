import Foundation

// MARK: - Subscription Service Protocol
protocol TwitchEventSubSubscriptionServiceProtocol {
    func subscribe(sessionId: String, userId: String, completion: @escaping (Bool) -> Void)
    func makeSubscribeErrorToastIfNotOk(ok: Bool, eventType: String)
}

final class TwitchEventSubSubscriptionService: TwitchEventSubSubscriptionServiceProtocol {
    // MARK: - Properties
    private let twitchApi: TwitchApi
    private weak var delegate: TwitchEventSubDelegate?
    private var started = false
    
    // MARK: - Initialization
    init(twitchApi: TwitchApi, delegate: TwitchEventSubDelegate?) {
        self.twitchApi = twitchApi
        self.delegate = delegate
    }
    
    // MARK: - Public Methods
    func subscribe(sessionId: String, userId: String, completion: @escaping (Bool) -> Void) {
        self.started = true
        subscribeToChannelFollow(sessionId: sessionId, userId: userId) { [weak self] success in
            guard let self = self, success else {
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    func makeSubscribeErrorToastIfNotOk(ok: Bool, eventType: String) {
        guard !ok else {
            return
        }
        guard started else {
            return
        }
        delegate?
            .twitchEventSubMakeErrorToast(
                title: String(localized: "Failed to subscribe to Twitch \(eventType) event")
            )
    }
    
    // MARK: - Private Subscription Methods
    private func subscribeToChannelFollow(sessionId: String, userId: String, completion: @escaping (Bool) -> Void) {
        let body = createBody(
            type: TwitchEventSubSubscriptionType.channelFollow,
            version: 2,
            condition: "{\"broadcaster_user_id\":\"\(userId)\",\"moderator_user_id\":\"\(userId)\"}",
            sessionId: sessionId
        )
        
        twitchApi.createEventSubSubscription(body: body) { [weak self] ok in
            self?.makeSubscribeErrorToastIfNotOk(ok: ok, eventType: "follow")
            guard ok else {
                completion(false)
                return
            }
            self?.subscribeToChannelSubscribe(sessionId: sessionId, userId: userId, completion: completion)
        }
    }
    
    private func subscribeToChannelSubscribe(sessionId: String, userId: String, completion: @escaping (Bool) -> Void) {
        subscribeBroadcasterUserId(type: TwitchEventSubSubscriptionType.channelSubscribe, 
                                   sessionId: sessionId,
                                   userId: userId,
                                   eventType: "subscription") { [weak self] in
            self?.subscribeToChannelSubscriptionGift(sessionId: sessionId, userId: userId, completion: completion)
        }
    }
    
    private func subscribeToChannelSubscriptionGift(sessionId: String, userId: String, completion: @escaping (Bool) -> Void) {
        subscribeBroadcasterUserId(type: TwitchEventSubSubscriptionType.channelSubscriptionGift, 
                                   sessionId: sessionId,
                                   userId: userId,
                                   eventType: "subscription gift") { [weak self] in
            self?.subscribeToChannelSubscriptionMessage(sessionId: sessionId, userId: userId, completion: completion)
        }
    }
    
    private func subscribeToChannelSubscriptionMessage(sessionId: String, userId: String, completion: @escaping (Bool) -> Void) {
        subscribeBroadcasterUserId(type: TwitchEventSubSubscriptionType.channelSubscriptionMessage,
                                  sessionId: sessionId,
                                  userId: userId,
                                  eventType: "subscription message") { [weak self] in
            self?.subscribeToChannelPointsCustomRewardRedemptionAdd(sessionId: sessionId, userId: userId, completion: completion)
        }
    }
    
    private func subscribeToChannelPointsCustomRewardRedemptionAdd(sessionId: String, userId: String, completion: @escaping (Bool) -> Void) {
        subscribeBroadcasterUserId(type: TwitchEventSubSubscriptionType.channelPointsCustomRewardRedemptionAdd,
                                  sessionId: sessionId,
                                  userId: userId,
                                  eventType: "reward redemption") { [weak self] in
            self?.subscribeToChannelRaid(sessionId: sessionId, userId: userId, completion: completion)
        }
    }
    
    private func subscribeToChannelRaid(sessionId: String, userId: String, completion: @escaping (Bool) -> Void) {
        let body = createBody(type: TwitchEventSubSubscriptionType.channelRaid,
                              version: 1,
                              condition: "{\"to_broadcaster_user_id\":\"\(userId)\"}",
                              sessionId: sessionId)
        
        twitchApi.createEventSubSubscription(body: body) { [weak self] ok in
            self?.makeSubscribeErrorToastIfNotOk(ok: ok, eventType: "raid")
            guard ok else {
                completion(false)
                return
            }
            self?.subscribeToChannelCheer(sessionId: sessionId, userId: userId, completion: completion)
        }
    }
    
    private func subscribeToChannelCheer(sessionId: String, userId: String, completion: @escaping (Bool) -> Void) {
        subscribeBroadcasterUserId(type: TwitchEventSubSubscriptionType.channelCheer,
                                  sessionId: sessionId,
                                  userId: userId,
                                  eventType: "cheer") { [weak self] in
            self?.subscribeToChannelHypeTrainBegin(sessionId: sessionId, userId: userId, completion: completion)
        }
    }
    
    private func subscribeToChannelHypeTrainBegin(sessionId: String, userId: String, completion: @escaping (Bool) -> Void) {
        subscribeBroadcasterUserId(type: TwitchEventSubSubscriptionType.channelHypeTrainBegin,
                                  sessionId: sessionId,
                                  userId: userId,
                                  eventType: "hype train begin") { [weak self] in
            self?.subscribeToChannelHypeTrainProgress(sessionId: sessionId, userId: userId, completion: completion)
        }
    }
    
    private func subscribeToChannelHypeTrainProgress(sessionId: String, userId: String, completion: @escaping (Bool) -> Void) {
        subscribeBroadcasterUserId(type: TwitchEventSubSubscriptionType.channelHypeTrainProgress,
                                  sessionId: sessionId,
                                  userId: userId,
                                  eventType: "hype train progress") { [weak self] in
            self?.subscribeToChannelHypeTrainEnd(sessionId: sessionId, userId: userId, completion: completion)
        }
    }
    
    private func subscribeToChannelHypeTrainEnd(sessionId: String, userId: String, completion: @escaping (Bool) -> Void) {
        subscribeBroadcasterUserId(type: TwitchEventSubSubscriptionType.channelHypeTrainEnd,
                                  sessionId: sessionId,
                                  userId: userId,
                                  eventType: "hype train end") { [weak self] in
            self?.subscribeToChannelAdBreakBegin(sessionId: sessionId, userId: userId, completion: completion)
        }
    }
    
    private func subscribeToChannelAdBreakBegin(sessionId: String, userId: String, completion: @escaping (Bool) -> Void) {
        subscribeBroadcasterUserId(type: TwitchEventSubSubscriptionType.channelAdBreakBegin,
                                  sessionId: sessionId,
                                  userId: userId,
                                  eventType: "ad break begin") {
            completion(true)
        }
    }
    
    // MARK: - Helper Methods
    private func subscribeBroadcasterUserId(
        type: String,
        sessionId: String,
        userId: String,
        eventType: String,
        onSuccess: @escaping () -> Void
    ) {
        let body = createBroadcasterUserIdBody(type: type, sessionId: sessionId, userId: userId)
        twitchApi.createEventSubSubscription(body: body) { [weak self] ok in
            self?.makeSubscribeErrorToastIfNotOk(ok: ok, eventType: eventType)
            guard ok else {
                return
            }
            onSuccess()
        }
    }
    
    private func createBody(type: String, version: Int, condition: String, sessionId: String) -> String {
        return """
        {
            "type": "\(type)",
            "version": "\(version)",
            "condition": \(condition),
            "transport": {
                "method": "websocket",
                "session_id": "\(sessionId)"
            }
        }
        """
    }
    
    private func createBroadcasterUserIdBody(type: String, sessionId: String, userId: String, version: Int = 1) -> String {
        return createBody(type: type,
                          version: version,
                          condition: "{\"broadcaster_user_id\":\"\(userId)\"}",
                          sessionId: sessionId)
    }
} 