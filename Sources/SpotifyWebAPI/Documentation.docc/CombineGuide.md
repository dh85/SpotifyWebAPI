# Combine Integration

Every async endpoint has a matching Combine publisher when `Combine` is available.

## Mirrored APIs

Publisher methods live alongside async variants by appending `Publisher`:

- ``Features/Playlists/PlaylistServiceProtocol/itemsPublisher(_:limit:offset:market:)`` mirrors `items(...)`.
- ``Features/Users/UserProfileServiceProtocol/mePublisher()`` mirrors `me()`.
- ``Features/Artists/ArtistServiceProtocol/severalPublisher(_:)`` mirrors `several(_:)`.

Under the hood, the publisher simply wraps the async implementation inside ``Publishers.SpotifyRequest`` so you get identical validation, retry behavior, and logging whether you use async/await or Combine.

## Lifecycle Management

Each publisher yields a standard `AnyPublisher<Value, SpotifyClientError>`. Cancellation propagates to the underlying `Task`, so long-running pagination streams stop immediately when the downstream subscriber cancels.

```swift
let cancellable = client.playlists.itemsPublisher("playlistID", limit: 50)
    .flatMap { $0.items.publisher }
    .sink(receiveCompletion: handle, receiveValue: render)
```

## Testing Publishers

Point your app code at ``Testing/MockSpotifyClient`` when unit testing Combine pipelines. You control each publisher by providing closures, making it easy to assert UI state without touching the network:

```swift
let mock = MockSpotifyClient()
mock.playlists.itemsPublisher = { _ in
    Just(.init(items: sampleItems, limit: 20, offset: 0, total: 2))
        .setFailureType(to: SpotifyClientError.self)
        .eraseToAnyPublisher()
}
```

For integration tests, keep using the real `SpotifyClient` but point it at `SpotifyMockAPIServer` so your pipelines run end-to-end in a sandbox.
