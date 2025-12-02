import Foundation
import Testing

@testable import SpotifyKit

// MARK: - JSON Loading

/// A helper to load mock JSON data from files in the test bundle.
enum TestDataLoader {

  /// Loads a JSON file from the `Tests/Mocks` directory.
  ///
  /// - Parameters:
  ///   - file: The name of the file (e.g., "album_full.json").
  ///   - directory: The subdirectory within `Mocks/` (e.g., "Albums").
  /// - Returns: The file's contents as `Data`.
  static func load(_ name: String) throws
    -> Data
  {
    let bundle = Bundle.module

    let sanitizedName = name.replacingOccurrences(of: ".json", with: "")

    guard
      let url = bundle.url(
        forResource: sanitizedName,
        withExtension: "json"
      )
    else {
      let message =
        "Failed to find mock data file: \(sanitizedName).json"
      Issue.record(Comment(stringLiteral: message))
      throw TestError.general(message)
    }

    return try Data(contentsOf: url)
  }
}

// MARK: - Mock Models

extension SpotifyTokens {
  static let mockValid = SpotifyTokens(
    accessToken: "VALID_ACCESS_TOKEN",
    refreshToken: "VALID_REFRESH_TOKEN",
    expiresAt: Date().addingTimeInterval(3600),  // Expires in 1 hour
    scope: "playlist-read-private",
    tokenType: "Bearer"
  )

  static let mockExpired = SpotifyTokens(
    accessToken: "EXPIRED_ACCESS_TOKEN",
    refreshToken: "EXPIRED_REFRESH_TOKEN",
    expiresAt: Date().addingTimeInterval(-3600),  // Expired 1 hour ago
    scope: "playlist-read-private",
    tokenType: "Bearer"
  )
}

// MARK: - Encoding/Decoding Helpers

func decodeModel<T: Decodable>(from data: Data) throws
  -> T
{
  let decoder = JSONDecoder()
  decoder.keyDecodingStrategy = .convertFromSnakeCase
  decoder.dateDecodingStrategy = .iso8601
  return try decoder.decode(T.self, from: data)
}

func encodeModel<T: Encodable>(_ model: T) throws -> Data {
  let encoder = JSONEncoder()
  encoder.keyEncodingStrategy = .convertToSnakeCase
  encoder.dateEncodingStrategy = .iso8601
  return try encoder.encode(model)
}

func decodeFixture<T: Decodable>(
  _ name: String,
  as type: T.Type = T.self
) throws -> T {
  try decodeModel(from: try TestDataLoader.load(name))
}

func assertFixtureEqual<T: Decodable & Equatable>(
  _ name: String,
  expected: T,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column
) throws {
  let decoded: T = try decodeFixture(name, as: T.self)
  let sourceLocation = SourceLocation(
    fileID: String(describing: fileID),
    filePath: String(describing: filePath),
    line: Int(line),
    column: Int(column)
  )
  #expect(
    decoded == expected,
    sourceLocation: sourceLocation
  )
}

func expectCodableRoundTrip<T: Codable & Equatable>(
  _ value: T,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column
) throws {
  let data = try encodeModel(value)
  let decoded: T = try decodeModel(from: data)
  let sourceLocation = SourceLocation(
    fileID: String(describing: fileID),
    filePath: String(describing: filePath),
    line: Int(line),
    column: Int(column)
  )
  #expect(
    decoded == value,
    sourceLocation: sourceLocation
  )
}

// MARK: - JSON Builders

/// Converts a JSON string to Data.
func makeJSONData(_ string: String) -> Data {
  string.data(using: .utf8)!
}

/// Creates a mock playlist snapshot response.
func makeSnapshotResponse(_ id: String = "snapshot123") -> Data {
  makeJSONData("{\"snapshot_id\": \"\(id)\"}")
}

/// Creates a simple album JSON response for testing.
func makeAlbumJSON(
  id: String,
  name: String,
  artistName: String = "Test Artist",
  totalTracks: Int = 10,
  popularity: Int = 50
) -> Data {
  let json = """
    {
        "album_type": "album",
        "total_tracks": \(totalTracks),
        "available_markets": ["US", "CA"],
        "external_urls": {"spotify": "https://open.spotify.com/album/\(id)"},
        "href": "https://api.spotify.com/v1/albums/\(id)",
        "id": "\(id)",
        "images": [],
        "name": "\(name)",
        "release_date": "2023-01-01",
        "release_date_precision": "day",
        "type": "album",
        "uri": "spotify:album:\(id)",
        "artists": [{
            "external_urls": {"spotify": "https://open.spotify.com/artist/artist1"},
            "href": "https://api.spotify.com/v1/artists/artist1",
            "id": "artist1",
            "name": "\(artistName)",
            "type": "artist",
            "uri": "spotify:artist:artist1"
        }],
        "tracks": {
            "href": "https://api.spotify.com/v1/albums/\(id)/tracks",
            "limit": 50,
            "next": null,
            "offset": 0,
            "previous": null,
            "total": \(totalTracks),
            "items": []
        },
        "copyrights": [],
        "external_ids": {},
        "genres": [],
        "label": "Test Label",
        "popularity": \(popularity)
    }
    """
  return makeJSONData(json)
}
