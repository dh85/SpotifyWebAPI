public struct UserQueue: Decodable, Sendable, Equatable {
    public let currentlyPlaying: PlayableItem?
    public let queue: [PlayableItem]
    
    enum CodingKeys: String, CodingKey {
        case currentlyPlaying, queue
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.currentlyPlaying = try container.decodeIfPresent(PlayableItemWrapper.self, forKey: .currentlyPlaying)?.item
        
        let queueWrappers = try container.decode([PlayableItemWrapper].self, forKey: .queue)
        self.queue = queueWrappers.map { $0.item }
    }
}

private struct PlayableItemWrapper: Decodable {
    let item: PlayableItem
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let typeContainer = try decoder.container(keyedBy: TypeKey.self)
        let type = try typeContainer.decode(String.self, forKey: .type)
        
        switch type {
        case "track":
            self.item = .track(try container.decode(Track.self))
        case "episode":
            self.item = .episode(try container.decode(Episode.self))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: typeContainer,
                debugDescription: "Unknown playable item type: \(type)"
            )
        }
    }
    
    enum TypeKey: String, CodingKey {
        case type
    }
}
