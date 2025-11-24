# Endpoint Coverage

`SpotifyClient` exposes every Spotify Web API surface area through dedicated service namespaces that hang directly off the client (`client.playlists`, `client.player`, etc.).

## Service Namespaces

| Capability | Entry Point | Common Calls |
| --- | --- | --- |
| Albums | `client.albums` | `several(_:)`, `saved(limit:offset:)`, `save(_:market:)`, `remove(_:market:)`. |
| Artists | `client.artists` | `get(id:)`, `topTracks(id:market:)`, `relatedArtists(id:)`, `follow(ids:)`. |
| Audiobooks & Chapters | `client.audiobooks` / `client.chapters` | `get(id:market:)`, `saved(limit:offset:)`, `streamChapters(id:)`. |
| Browse | `client.browse` | `newReleases(limit:country:)`, `featuredPlaylists(locale:country:)`, `categories(limit:locale:)`. |
| Episodes & Shows | `client.episodes` / `client.shows` | `get(id:market:)`, `saved(limit:offset:)`, `save(ids:)` / `remove(ids:)`. |
| Playlists | `client.playlists` | `createPlaylist`, `changeDetails`, `items`, `addItems`, `reorderItems`, `uploadCoverImage`. |
| Player | `client.player` | `currentPlaybackState`, `setShuffle`, `setRepeatMode`, `transferPlayback`, `queue`. |
| Search | `client.search` | `search(query:types:market:limit:)` with combined entity results. |
| Tracks & Users | `client.tracks` / `client.users` | `audioFeatures`, `saved`, `topTracks`, `topArtists`, `profile`. |

Each namespace gives you async methods and, on Apple platforms, Combine publishers. Most methods return strongly typed models (for example `Playlist` or `Paging<Track>`), while write operations return `EmptyResponse` for convenience. If you need to inspect or debug a request, every call also returns the underlying ``SpotifyRequest`` before execution.

## Pagination Patterns

Use any of the following helpers depending on your scenario:

- ``SpotifyClient/collectAllPages(maximumItems:fetchPage:)`` for eagerly collecting items.
- ``Pagination/PagingStreamBuilder`` for streaming pages asynchronously with cancellation.
- Combine equivalents under ``Core/Pagination/Combine``.

Requests accept `limit`, `offset`, `after`, and `before` parameters where Spotify supports them. The client enforces documented bounds (usually 1...50) before firing the HTTP call, returning ``SpotifyClientError/invalidRequest(_: )`` when inputs violate the spec.

## Custom Endpoints

If you need an endpoint that is not yet modeled, extend `SpotifyClient` using the HTTP layer from your own module:

```swift
extension SpotifyClient {
    public func request<T: Decodable>(_ route: SpotifyRequest<T>) async throws -> T {
        try await httpClient.perform(route)
    }
}
```

This lets you keep SpotifyWebAPI up to date while still calling beta endpoints or internal proxies.
