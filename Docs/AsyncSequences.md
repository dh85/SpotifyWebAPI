# Async Sequence Utilities

SpotifyWebAPI leans on Swift's `AsyncSequence` APIs to expose long-running pagination work in a safe and cancellable way. This guide highlights the core helpers now available along with small code samples you can copy into your app.

## PaginationStreamBuilder

`PaginationStreamBuilder` offers lightweight factories for building `AsyncThrowingStream` values over any paginated endpoint. It wraps the boilerplate needed to clamp page sizes, check for cancellation, and wire up `Task` cancellation to stream termination.

### Streaming full pages

```swift
let pageStream = PaginationStreamBuilder.pages(pageSize: 50) { limit, offset in
    try await client.tracks.saved(limit: limit, offset: offset)
}

let task = Task {
    for try await page in pageStream {
        print("Fetched page starting at \(page.offset)")
        render(page.items)
    }
}

// Cancel from UI interactions
cancelButton.onTap { task.cancel() }
```

### Streaming individual items

```swift
let itemStream = PaginationStreamBuilder.items(maxItems: 250) { limit, offset in
    try await client.playlists.items(for: playlistID, limit: limit, offset: offset)
}

let task = Task {
    for try await track in itemStream {
        try await ingest(track)
    }
}

// Cancel automatically when the user leaves the screen
Task { @MainActor in
    await navigation.dismissed()
    task.cancel()
}
```

## SpotifyClient conveniences

`SpotifyClient` continues to ship `streamPages` and `streamItems` helpers that now internally use the builder above. That means you get the same ergonomics, plus you can still layer your own cancellation logic via `Task` handles:

```swift
let task = Task {
    for try await savedAlbum in client.albums.streamSavedAlbums(maxItems: 1000) {
        try await cache(savedAlbum)
    }
}

// Cancel if network becomes expensive
Task.detached {
    if await isOnCellularData() {
        task.cancel()
    }
}
```

Because the helpers rely on `AsyncThrowingStream`, cancellation is cooperative and immediate. If you stop iterating, or call `task.cancel()`, the underlying network `Task` is cancelled and Spotify requests halt cleanly.

## Service-level helpers

Most high-level services expose typed streaming APIs so you rarely need to drop down to the raw builder yourself. Each saved-items endpoint now offers both item-by-item and page-by-page variants. For example:

```swift
// Saved albums page batches
for try await page in client.albums.streamSavedAlbumPages(maxPages: 5) {
    render(page.items)
}

// Playlist track pages for chunked diffing
for try await page in client.playlists.streamItemPages("playlist_id") {
    diff(page.items)
}

// Current user's playlists, streamed lazily for an infinite scrolling UI
for try await page in client.playlists.streamMyPlaylistPages() {
    append(page.items)
}
```

Prefer the page-based APIs when you need progress updates, want to batch analytics, or plan to cache responses verbatim. Stick with the item variants when you simply need to process each entity sequentially.

The same streaming ergonomics now cover the rest of Spotify's catalog endpoints. A few examples:

```swift
// Artist discography filters (albums, singles, etc.)
for try await page in client.artists.streamAlbumPages(
    for: artistID,
    includeGroups: [.album, .single]
) {
    cache(page.items)
}

// Album track lists with relinking
for try await page in client.albums.streamTrackPages(albumID, market: "US") {
    render(page.items)
}

// Podcast episodes and audiobook chapters for batching downloads
async let shows = client.shows.streamEpisodePages(for: showID)
async let chapters = client.audiobooks.streamChapterPages(for: audiobookID)

// Affinity data for long-running analytics
for try await page in client.users.streamTopTrackPages(range: .longTerm, pageSize: 30) {
    try await store(page.items)
}

// Browse endpoints, e.g. endless category grids
for try await page in client.browse.streamCategoryPages(locale: "es_MX") {
    append(page.items)
}
```

Need item-by-item back-pressure instead? Every catalog helper that streams pages now has an item counterpart built on `streamItems`:

```swift
for try await album in client.artists.streamAlbums(for: artistID, pageSize: 40) {
    await discography.append(album)
}

for try await track in client.albums.streamTracks(albumID, market: "CA") {
    try await enqueueDownload(track)
}

for try await episode in client.shows.streamEpisodes(for: showID, pageSize: 75) {
    try await cache(episode)
}

for try await category in client.browse.streamCategories(locale: "en_US") {
    categories.append(category)
}

for try await artist in client.users.streamTopArtists(range: .shortTerm, maxItems: 100) {
    feature(artist)
}
```

Mix and match the two styles—page-level streams when you need chunks, item-level streams when you prefer steady per-entity processing without building your own buffer.
