import Foundation

/// A parsed Spotify URI or URL that identifies a resource.
///
/// Supports parsing both Spotify URIs (`spotify:track:abc123`) and web URLs
/// (`https://open.spotify.com/track/abc123`).
///
/// ## Example
/// ```swift
/// // Parse from URI
/// let uri = SpotifyURI(string: "spotify:track:6rqhFgbbKwnb9MLmUQDhG6")
/// print(uri?.id) // "6rqhFgbbKwnb9MLmUQDhG6"
/// print(uri?.type) // .track
///
/// // Parse from URL
/// let uri2 = SpotifyURI(string: "https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M")
/// print(uri2?.id) // "37i9dQZF1DXcBWIGoYBM5M"
/// print(uri2?.type) // .playlist
///
/// // Convert back
/// print(uri?.uri) // "spotify:track:6rqhFgbbKwnb9MLmUQDhG6"
/// print(uri?.url) // URL("https://open.spotify.com/track/6rqhFgbbKwnb9MLmUQDhG6")
/// ```
public struct SpotifyURI: Sendable, Equatable, Hashable {
  /// The type of Spotify resource
  public let type: ResourceType
  
  /// The Spotify ID for the resource
  public let id: String
  
  /// Supported Spotify resource types
  public enum ResourceType: String, Sendable, Equatable, Hashable {
    case track, album, artist, playlist, show, episode, user
  }
  
  /// Initialize from a Spotify URI or URL string.
  ///
  /// Accepts:
  /// - URIs: `spotify:track:abc123`
  /// - URLs: `https://open.spotify.com/track/abc123`
  /// - Short URLs: `https://spotify.link/abc123`
  ///
  /// - Parameters:
  ///   - string: The URI or URL string to parse
  ///   - expectedType: Optional expected resource type. Returns nil if type doesn't match.
  public init?(string: String, expectedType: ResourceType? = nil) {
    let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Try URI format: spotify:type:id
    if trimmed.hasPrefix("spotify:") {
      let parts = trimmed.split(separator: ":")
      guard parts.count >= 3,
            let type = ResourceType(rawValue: String(parts[1])) else {
        return nil
      }
      
      // Validate expected type if provided
      if let expectedType, type != expectedType {
        return nil
      }
      
      self.type = type
      self.id = String(parts[2])
      return
    }
    
    // Try URL format: https://open.spotify.com/type/id or https://open.spotify.com/type/id?...
    guard let url = URL(string: trimmed),
          let host = url.host,
          (host == "open.spotify.com" || host == "spotify.com") else {
      return nil
    }
    
    let pathComponents = url.pathComponents.filter { $0 != "/" }
    guard pathComponents.count >= 2,
          let type = ResourceType(rawValue: pathComponents[0]) else {
      return nil
    }
    
    // Validate expected type if provided
    if let expectedType, type != expectedType {
      return nil
    }
    
    self.type = type
    self.id = pathComponents[1]
  }
  
  /// The Spotify URI representation: `spotify:type:id`
  public var uri: String {
    "spotify:\(type.rawValue):\(id)"
  }
  
  /// The Spotify web URL representation
  public var url: URL {
    URL(string: "https://open.spotify.com/\(type.rawValue)/\(id)")!
  }
}

extension SpotifyURI: CustomStringConvertible {
  public var description: String { uri }
}

extension SpotifyURI: Codable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let string = try container.decode(String.self)
    guard let parsed = SpotifyURI(string: string) else {
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Invalid Spotify URI: \(string)"
      )
    }
    self = parsed
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(uri)
  }
}
