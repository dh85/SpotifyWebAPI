# Modeling Data

SpotifyKit ships battle-tested Swift models so you can bind Spotify payloads directly to your UI, persistence layer, or widgets without re-implementing JSON parsing.

## Everyday Usage

- Every endpoint call returns typed models (`Album`, `Playlist`, `PlaybackState`, etc.) so you can `switch` over enums, format durations, or diff collections without touching dictionaries.
- Models include convenient computed properties for common operations:
  - `artistNames`: Comma-separated artist names (e.g., "Artist 1, Artist 2")
  - `durationFormatted`: Human-readable duration (e.g., "3:45")
  - `primaryImageURL`: First available image URL for quick access
  - `followerCount`: Follower total for artists and users
  - `ownerName`: Playlist owner display name
  - `trackCount`: Total tracks in playlists and albums
- ``Page`` and ``CursorBasedPage`` expose helpers such as ``PagingContainer/hasMore-swift.property`` and `nextOffset` to drive `List`/`CollectionView` pagination.
- Conformance to `Codable`, `Sendable`, and `Hashable` means you can cache results, share data across actors, and use models as dictionary keys safely.

### Example: Using Convenience Properties

```swift
let track = try await client.tracks.get("track_id")
print("\(track.name) by \(track.artistNames ?? "Unknown")")
print("Duration: \(track.durationFormatted ?? "Unknown")")

if let imageURL = track.album?.primaryImageURL {
    // Load album artwork
}
```

## Detailed vs. Simplified Payloads

- ``Album`` versus ``SimplifiedAlbum`` mirrors Spotify's “full vs. compact” payload pattern. Reach for the simplified versions when loading lists and upgrade to the full type when you need richer metadata like copyrights or label info.
- ``Artist``, ``Track``, and ``Playlist`` follow the same pattern, making it easy to display lightweight previews first and hydrate details on-demand.

## Tokens & Permissions

- ``SpotifyTokens`` keeps access, refresh, and expiration metadata together so you can present accurate “session expires in…” messaging.
- ``SpotifyScope`` provides type-safe permission sets (playback, library, user profile). Use these constants when configuring `AuthorizationCodeFlowClientConfiguration` to avoid typos in raw scope strings.
- ``TokenStore`` is a protocol you can back with the keychain, App Groups, or your server. The included stores (restricted file, in-memory) cover common sandbox vs. production scenarios.

## Helper Types

- ``SpotifyReleaseDate`` normalizes Spotify's partial date formats (year-only, month precision). Feed it directly into `DateFormatter` or your own calendar logic without manual parsing.
- ``SpotifyExternalUrls`` and ``SpotifyExternalIds`` keep URI/URL metadata consistent across features. Use them when storing identifiers locally or routing to deep links.

## Working with Fixtures

- ``SpotifyTestFixtures`` decodes canonical JSON, making it easy to create SwiftUI previews or snapshot tests that stay in sync with Spotify's schema.
- When Spotify introduces a new field you care about, add the fixture update first, regenerate the model via `swift build`, and let Codable surface the new property. No manual JSON plumbing required.
