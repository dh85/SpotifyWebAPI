# Async Sequence Utilities

SpotifyKit leans on Swift's `AsyncSequence` APIs to expose long-running pagination work in a safe and cancellable way. This guide highlights the core helpers now available along with small code samples you can copy into your app.

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
    let stream = client.users.streamTopTracks(timeRange: .mediumTerm)
    for try await track in stream {
        print(track.name)
    }
}

// Cancelling the task stops the stream and cancels any in-flight network request
task.cancel()
```

## Combine Interop

If you're using Combine, you can bridge these async sequences to publishers using `.publisher`:

```swift
client.users.streamTopTracks(timeRange: .mediumTerm)
    .publisher
    .sink(
        receiveCompletion: { print("Done: \($0)") },
        receiveValue: { track in print("Got track: \(track.name)") }
    )
    .store(in: &cancellables)
```
