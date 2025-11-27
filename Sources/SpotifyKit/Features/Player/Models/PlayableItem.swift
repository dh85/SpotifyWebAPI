import Foundation

/// A playable item in the Spotify catalog.
///
/// Represents content that can be played through the Spotify player,
/// such as tracks or podcast episodes.
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-information-about-the-users-current-playback)
public enum PlayableItem: Codable, Sendable, Equatable {
    /// A music track.
    case track(Track)

    /// A podcast episode.
    case episode(Episode)
}

// MARK: - Polymorphic Decoding Helpers

extension PlayableItem {
    /// Decodes a PlayableItem from a keyed container based on a type discriminator string.
    ///
    /// - Parameters:
    ///   - container: The keyed decoding container.
    ///   - key: The coding key for the item.
    ///   - typeString: The type discriminator ("track", "episode", "ad", "unknown", etc.).
    /// - Returns: A decoded PlayableItem, or nil if the type is unknown or unsupported.
    public static func decode<K: CodingKey>(
        from container: KeyedDecodingContainer<K>,
        forKey key: K,
        typeString: String
    ) throws -> PlayableItem? {
        switch typeString {
        case "track":
            return .track(try container.decode(Track.self, forKey: key))
        case "episode":
            return .episode(try container.decode(Episode.self, forKey: key))
        default:
            // For "ad", "unknown", or other types, return nil
            return nil
        }
    }

    /// Decodes a PlayableItem from a single value container by inspecting the "type" field.
    ///
    /// This is useful when the entire JSON object represents a playable item with a discriminator field.
    ///
    /// - Parameter decoder: The decoder to read from.
    /// - Returns: A decoded PlayableItem.
    /// - Throws: DecodingError if the type is unrecognized or decoding fails.
    public static func decode(from decoder: Decoder) throws -> PlayableItem {
        let container = try decoder.singleValueContainer()
        let typeContainer = try decoder.container(keyedBy: TypeKey.self)
        let type = try typeContainer.decode(String.self, forKey: .type)

        switch type {
        case "track":
            return .track(try container.decode(Track.self))
        case "episode":
            return .episode(try container.decode(Episode.self))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: typeContainer,
                debugDescription: "Unknown playable item type: \(type)"
            )
        }
    }

    private enum TypeKey: String, CodingKey {
        case type
    }
}
