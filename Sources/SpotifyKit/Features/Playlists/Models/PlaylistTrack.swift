import Foundation

/// A track or episode object in a playlist.
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-playlists-tracks)
public enum PlaylistTrack: Codable, Sendable, Equatable {
  case track(Track)
  case episode(Episode)

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let track = try? container.decode(Track.self) {
      self = .track(track)
    } else if let episode = try? container.decode(Episode.self) {
      self = .episode(episode)
    } else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: decoder.codingPath,
          debugDescription: "Expected Track or Episode"
        )
      )
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .track(let track):
      try container.encode(track)
    case .episode(let episode):
      try container.encode(episode)
    }
  }
}
