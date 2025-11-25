# Testing Support

SpotifyWebAPI is designed to fit cleanly into dependency-injected apps, so you can exercise your features without relying on the live Spotify service during development.

## Protocol-Oriented Client

All services conform to ``Testing/SpotifyClientProtocol``. Construct your app against the protocol, then provide one of the following at runtime:

- ``SpotifyClient`` for real HTTP traffic.
- ``Testing/MockSpotifyClient`` for deterministic responses without having to implement each endpoint yourself. Provide closures for the calls your test cares about and leave the rest untouched.
- ``Testing/SpotifyClientProtocol`` also works great with your own lightweight mocks if you prefer to use a testing framework.

## Sample Data

Because every model is `Codable`, you can build sample data directly in Swift for previews or snapshot tests:

```swift
let demoPlaylist = Playlist(
	id: "123",
	name: "Focus Mix",
	description: "Deep work vibes",
	tracks: .init(items: demoTracks, limit: 20, offset: 0, total: demoTracks.count),
	public: false,
	collaborative: false,
	owner: demoUser,
	externalURLs: [:],
	followers: nil,
	images: []
)
```

Need to drive a UI against the real networking stack without Spotify's servers? Stand up your own HTTP endpoint that mimics Spotify's responses and point `SpotifyClientConfiguration` at it by overriding the `httpClient`.

## Helper Assertions

Combine pipelines are easy to verify by returning `Just` values from your mocks, while async code can be exercised with `async let`/`await` inside XCTest. Because everything funnels through ``SpotifyClientProtocol``, you rarely need to spin up real HTTP traffic for unit tests.

## Instrumentation

Hook into observability once via ``SpotifyClientObserver`` instead of wiring multiple callbacks. Observers receive ``SpotifyClientEvent`` values that cover requests, responses, retries, token lifecycle, and rate limits:

```swift
struct LoggingObserver: SpotifyClientObserver {
	func receive(_ event: SpotifyClientEvent) {
		switch event {
		case .tokenRefreshDidFail(let context):
			logger.error("Token refresh failed: \(context.errorDescription)")
		case .rateLimit(let info):
			logger.info("Remaining requests: \(info.remaining ?? -1)")
		default:
			break
		}
	}
}

let observer = await client.addObserver(LoggingObserver())
```

Remove observers with ``SpotifyClient/removeObserver(_:)`` when you no longer need the events (for example, when a view disappears).

## Continuous Integration Tips

1. Create a shared test target that owns your mock client implementations so apps and frameworks reuse them.
2. Run long-haul stress loops (multiple `swift test` passes) when touching concurrency or networking sensitive features.
3. Capture the requests your app issues by wrapping ``HTTP/HTTPClient``—helpful for snapshotting payloads or ensuring scopes stay minimal.
