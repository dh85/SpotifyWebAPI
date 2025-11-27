# Combine Integration

Every async endpoint has a matching Combine publisher when `Combine` is available.

## Mirrored APIs

Publisher methods live alongside async variants by appending `Publisher`:

- ``Features/Playlists/PlaylistServiceProtocol/itemsPublisher(_:limit:offset:market:)`` mirrors `items(...)`.
- ``Features/Users/UserProfileServiceProtocol/mePublisher()`` mirrors `me()`.
- ``Features/Artists/ArtistServiceProtocol/severalPublisher(_:)`` mirrors `several(_:)`.

Under the hood, the publisher simply wraps the async implementation inside ``Publishers.SpotifyRequest`` so you get identical validation, retry behavior, and logging whether you use async/await or Combine.

## Discoverability

Every async service (`AlbumsService`, `TracksService`, etc.) documents where to find its Combine
counterparts. Look for the "Combine Counterparts" section at the top of each service file or jump
straight to the adjacent `Service+Combine.swift` file in the same folder. All publisher helpers end
with `Publisher`, making it trivial to map from an async method like ``PlaylistsService/get(_:market:fields:additionalTypes:)`` to
``PlaylistsService/getPublisher(_:market:fields:additionalTypes:priority:)``.

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

## Authentication

The authenticators provide publisher counterparts for all major token operations. This allows you to drive your login flow entirely with Combine.

### Handling Callbacks

When your app receives a redirect URL, pass it to the authenticator's publisher:

```swift
func handleRedirect(_ url: URL) {
    authenticator.handleCallbackPublisher(url)
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Login failed: \(error)")
                }
            },
            receiveValue: { tokens in
                print("Logged in! Access token: \(tokens.accessToken)")
            }
        )
        .store(in: &cancellables)
}
```

### Token Refresh

You can manually trigger a token refresh if needed, though the client handles this automatically for requests.

```swift
authenticator.refreshAccessTokenIfNeededPublisher()
    .sink(
        receiveCompletion: { _ in },
        receiveValue: { tokens in
            print("Tokens are valid until: \(tokens.expirationDate)")
        }
    )
    .store(in: &cancellables)
```

## Observability & Metrics

You can monitor all client activity—requests, responses, rate limits, and performance metrics—by subscribing to the `observerPublisher`. This is useful for logging, debugging, or feeding analytics SDKs.

The publisher emits `SpotifyClientEvent` enums.

```swift
client.observerPublisher()
    .sink { event in
        switch event {
        case .request(let context):
            print("⬆️ \(context.method) \(context.url?.absoluteString ?? "")")
            
        case .response(let context):
            print("⬇️ Status: \(context.statusCode ?? 0) (\(context.dataBytes) bytes)")
            
        case .rateLimit(let info):
            print("⚠️ Rate limited! Reset in \(info.resetAfter)s")
            
        case .performance(let metrics):
            print("⏱️ \(metrics.operationName) took \(metrics.duration)s")
            
        case .tokenRefresh(let info):
            print("🔄 Token refresh: \(info.reason)")
        }
    }
    .store(in: &cancellables)
```

### Thread Safety

The `observerPublisher` guarantees that all events are emitted on the **Main Thread**. If you are doing heavy processing (like writing to a database or disk), you should hop to a background queue:

```swift
client.observerPublisher()
    .receive(on: DispatchQueue.global(qos: .utility))
    .sink { event in
        // Safe to perform blocking I/O here
        DiskLogger.write(event)
    }
    .store(in: &cancellables)
```
