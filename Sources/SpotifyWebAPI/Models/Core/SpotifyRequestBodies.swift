import Foundation

// MARK: - Generic Bodies

/// A generic structure for sending a list of IDs in a request body.
/// Used for `{"ids": ["..."]}` payloads.
public struct IDsBody: Codable, Sendable {
    public let ids: Set<String>
    
    public init(ids: Set<String>) {
        self.ids = ids
    }
}

/// A generic structure for sending a list of URIs in a request body.
/// Used for `{"uris": ["..."]}` payloads.
public struct URIsBody: Codable, Sendable {
    public let uris: [String]
    
    public init(uris: [String]) {
        self.uris = uris
    }
}

// MARK: - Common Response Wrappers

/// A common response wrapper containing a snapshot ID.
/// Used by playlist operations and other endpoints that return a snapshot identifier.
public struct SnapshotResponse: Decodable, Sendable {
    public let snapshotId: String
    
    public init(snapshotId: String) {
        self.snapshotId = snapshotId
    }
}

// MARK: - Playlist Bodies

/// Request body for following a playlist with optional public visibility setting.
public struct FollowPlaylistBody: Encodable, Sendable {
    public let isPublic: Bool?
    
    public init(isPublic: Bool?) {
        self.isPublic = isPublic
    }
    
    enum CodingKeys: String, CodingKey {
        case isPublic = "public"
    }
}

/// Request body for adding items to a playlist.
public struct AddPlaylistItemsBody: Encodable, Sendable {
    public let uris: [String]
    public let position: Int?
    
    public init(uris: [String], position: Int? = nil) {
        self.uris = uris
        self.position = position
    }
}

/// Request body for changing playlist details (name, description, visibility, collaborative).
public struct ChangePlaylistDetailsBody: Encodable, Sendable {
    public let name: String?
    public let isPublic: Bool?
    public let collaborative: Bool?
    public let description: String?
    
    public init(
        name: String? = nil,
        isPublic: Bool? = nil,
        collaborative: Bool? = nil,
        description: String? = nil
    ) {
        self.name = name
        self.isPublic = isPublic
        self.collaborative = collaborative
        self.description = description
    }
    
    enum CodingKeys: String, CodingKey {
        case name, collaborative, description
        case isPublic = "public"
    }
}

/// Request body for creating a new playlist.
public struct CreatePlaylistBody: Encodable, Sendable {
    public let name: String
    public let isPublic: Bool?
    public let collaborative: Bool?
    public let description: String?
    
    public init(
        name: String,
        isPublic: Bool? = nil,
        collaborative: Bool? = nil,
        description: String? = nil
    ) {
        self.name = name
        self.isPublic = isPublic
        self.collaborative = collaborative
        self.description = description
    }
    
    enum CodingKeys: String, CodingKey {
        case name, collaborative, description
        case isPublic = "public"
    }
}

/// Request body for reordering items in a playlist.
public struct ReorderPlaylistItemsBody: Encodable, Sendable {
    public let rangeStart: Int
    public let insertBefore: Int
    public let rangeLength: Int?
    public let snapshotId: String?
    
    public init(
        rangeStart: Int,
        insertBefore: Int,
        rangeLength: Int? = nil,
        snapshotId: String? = nil
    ) {
        self.rangeStart = rangeStart
        self.insertBefore = insertBefore
        self.rangeLength = rangeLength
        self.snapshotId = snapshotId
    }
    
    enum CodingKeys: String, CodingKey {
        case rangeStart = "range_start"
        case insertBefore = "insert_before"
        case rangeLength = "range_length"
        case snapshotId = "snapshot_id"
    }
}

/// Request body for removing items from a playlist.
/// Can remove by URIs or by positions.
public struct RemovePlaylistItemsBody: Encodable, Sendable {
    public let tracks: [TrackURIObject]?
    public let positions: [Int]?
    public let snapshotId: String?
    
    public init(
        tracks: [TrackURIObject]? = nil,
        positions: [Int]? = nil,
        snapshotId: String? = nil
    ) {
        self.tracks = tracks
        self.positions = positions
        self.snapshotId = snapshotId
    }

    enum CodingKeys: String, CodingKey {
        case tracks, positions
        case snapshotId = "snapshot_id"
    }

    public static func byURIs(_ uris: [String], snapshotId: String? = nil) -> Self {
        let trackObjects = uris.map { TrackURIObject(uri: $0) }
        return .init(
            tracks: trackObjects,
            positions: nil,
            snapshotId: snapshotId
        )
    }

    public static func byPositions(_ positions: [Int], snapshotId: String? = nil) -> Self {
        return .init(tracks: nil, positions: positions, snapshotId: snapshotId)
    }
}

/// A track URI object used in playlist operations.
public struct TrackURIObject: Encodable, Sendable {
    public let uri: String
    
    public init(uri: String) {
        self.uri = uri
    }
}

// MARK: - Player Bodies

/// Request body for starting or resuming playback.
public struct StartPlaybackBody: Encodable, Sendable {
    public let contextUri: String?
    public let uris: [String]?
    public let offset: PlaybackOffset?
    public let positionMs: Int?

    public init(
        contextUri: String? = nil,
        uris: [String]? = nil,
        offset: PlaybackOffset? = nil,
        positionMs: Int? = nil
    ) {
        self.contextUri = contextUri
        self.uris = uris
        self.offset = offset
        self.positionMs = positionMs
    }

    enum CodingKeys: String, CodingKey {
        case contextUri = "context_uri"
        case uris
        case offset
        case positionMs = "position_ms"
    }

    public static var resume: StartPlaybackBody {
        StartPlaybackBody(contextUri: nil, uris: nil, offset: nil, positionMs: nil)
    }

    public static func context(
        _ uri: String,
        offset: PlaybackOffset? = nil,
        positionMs: Int? = nil
    ) -> StartPlaybackBody {
        StartPlaybackBody(contextUri: uri, uris: nil, offset: offset, positionMs: positionMs)
    }

    public static func tracks(_ uris: [String], positionMs: Int? = nil) -> StartPlaybackBody {
        StartPlaybackBody(contextUri: nil, uris: uris, offset: nil, positionMs: positionMs)
    }
}

/// Request body for transferring playback to a different device.
public struct TransferPlaybackBody: Encodable, Sendable {
    public let deviceIds: [String]
    public let play: Bool?

    public init(deviceIds: [String], play: Bool? = nil) {
        self.deviceIds = deviceIds
        self.play = play
    }

    enum CodingKeys: String, CodingKey {
        case deviceIds = "device_ids"
        case play
    }
}

