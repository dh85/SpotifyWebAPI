# Modeling Spotify Data

You get strongly typed Swift models for every Spotify payload, so you can move straight from network responses to SwiftUI lists, Core Data, or widgets without manual JSON parsing.

## Working with Core Models

- `Album`, `Artist`, `Playlist`, `Track`, `Show`, `Episode`, and `Audiobook` live under `Sources/SpotifyWebAPI/Models/Core`. Endpoint responses already return these types—no extra decoding step required.
- `Paging` and `CursorPaging` expose helpers such as `hasNextPage` and `nextOffset`, which plug directly into infinite scrolling or background sync loops.
- All models conform to `Codable`, `Sendable`, and `Hashable`, making them safe to cache, diff, and share between actors.

## Simplified vs. Full Payloads

- Spotify often ships a lightweight “simplified” object inside list endpoints and a richer object for detail endpoints. The SDK mirrors that pattern: `SimplifiedAlbum`/`Album`, `SimplifiedPlaylist`/`Playlist`, etc.
- Use simplified variants when showing grids or carousels, then fetch the full type when a user drills down for credits, followers, or label data.

## Tokens & Permissions

- `SpotifyToken` keeps access, refresh, and expiration timestamps in one place so you can display accurate session messaging.
- `SpotifyScope` exposes curated permission sets (library, playback, user profile). Build your scope list using these enums instead of raw strings to prevent typos.
- The `SpotifyTokenStore` protocol lets you back tokens with the keychain, App Groups, or your backend. Swap implementations per build configuration without changing call sites.

## Helper Types & Fixtures

- `SpotifyDate`, `SpotifyURI`, `SpotifyURL`, and friends centralize parsing for Spotify-specific formats. Reach for them whenever you persist identifiers or parse partial dates.
- `SpotifyTestFixtures` provides ready-made JSON decoders for previews and tests. Example: `SpotifyTestFixtures.playlist("main_playlist")` gives you a populated playlist model without hitting the network.
