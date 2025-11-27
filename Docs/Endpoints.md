# Endpoint Reference

This library mirrors Spotify's REST surface area through typed service namespaces. Each service lives under `Sources/SpotifyKit/Features/<Name>` and becomes available via the corresponding property on `SpotifyClient`.

## Service Map

| Namespace | Highlights |
| --- | --- |
| `client.albums` | Fetch several albums at once, manage saved albums, stream album pages, save/remove IDs in chunks of 20. |
| `client.artists` | Artist profiles, top tracks, related artists, followed artists paging, and limit validation. |
| `client.audiobooks` / `client.chapters` | Full audiobook metadata, chapter listings, saved-collection helpers, and pagination streams. |
| `client.browse` | Categories, featured playlists, available markets, and new releases with locale/country knobs. |
| `client.episodes` / `client.shows` | Episode metadata, saved episodes/shows, chunked save/remove up to 50 IDs per call. |
| `client.player` | Playback state, queue, seek/skip, shuffle/repeat, device transfer, and queue operations. |
| `client.playlists` | Playlist CRUD, cover uploads, reorder/replace operations, paginated items with request builders. |
| `client.search` | Full search surface with multiple entity types per request and cursor/offset paging. |
| `client.tracks` | Track metadata, audio features analysis, saved tracks, and library mutations. |
| `client.users` | Profile endpoints, top tracks/artists, follow/unfollow helpers, and saved content checks.

## Conventions

- Every request returns a `SpotifyRequest` wrapper before execution, making it easy to inspect the path, query, and payload inside tests.
- Validation occurs before network I/O. Invalid limits or ID batches throw `SpotifyClientError.invalidRequest`, matching the behavior in test helpers.
- Long-running calls expose helpers such as `collectAllPages` and pagination streams; Combine equivalents live under `Core/Pagination/Combine`.

## Extending Coverage

If you need a Spotify endpoint that is not in the table, implement a new service under `Sources/SpotifyKit/Features` and wire it into `SpotifyClient` by following the existing pattern:

1. Define a protocol (`FooServiceProtocol`) listing async and Combine methods.
2. Implement `FooService` with the necessary `SpotifyRequest` builders.
3. Add a property on `SpotifyClient` that instantiates `FooService` with dependencies (HTTP client, decoder, configuration).
4. Write tests in `Tests/SpotifyKitTests/Features/Foo` plus fixtures in `Tests/Mocks/Foo`.
