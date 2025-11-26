# Combine Support

SpotifyWebAPI exposes optional Combine publisher variants that mirror the async/await APIs. Everything is wrapped in `#if canImport(Combine)` so Linux builds remain untouched, while Apple platforms running macOS 10.15+/iOS 13+/tvOS 13+/watchOS 6+ can opt into Combine.

## Discoverability

Every async service now includes a "Combine Counterparts" callout explaining that publisher helpers
live in the corresponding `Service+Combine.swift` file (for example `AlbumsService+Combine.swift`).
Those Combine files also document the async methods they wrap. Look for method names that end in
`Publisher`—they're guaranteed to call the async implementation behind the scenes, so you never have
to remember two separate request surfaces. Authenticators follow the same pattern inside
`Auth/Combine/Authenticators+Combine.swift`, so flows like PKCE and Authorization Code now expose
`handleCallbackPublisher`, `refreshAccessTokenPublisher`, and related helpers without duplicating
authorization logic.

## Usage Patterns

```swift
import Combine
import SpotifyWebAPI

let client = SpotifyClient.pkce(...)

let meCancellable = client.users.mePublisher()
    .sink(
        receiveCompletion: { completion in
            if case .failure(let error) = completion {
                print("Request failed", error)
            }
        },
        receiveValue: { profile in
            print("Signed in as", profile.displayName ?? "Unknown")
        }
    )

let artistsCancellable = client.users.topArtistsPublisher(range: .longTerm, limit: 50)
    .map(\.items)
    .sink(
        receiveCompletion: { completion in
            if case .failure(let error) = completion { print("Top artists failed", error) }
        },
        receiveValue: { artists in
            artists.forEach { print($0.name) }
        }
    )
```

Every `*Publisher` method internally calls the async implementation via `Publishers.SpotifyRequest`, so behavior stays identical regardless of which concurrency model you choose.

## Authentication & Observability

- **Auth flows:** `SpotifyPKCEAuthenticator`, `SpotifyAuthorizationCodeAuthenticator`, and
    `SpotifyClientCredentialsAuthenticator` each provide publisher variants for their async entry
    points. Swap between `handleCallback(_:)` and `handleCallbackPublisher(_:)` (or
    `refreshAccessTokenIfNeeded` ↔︎ `refreshAccessTokenIfNeededPublisher`) without rewriting PKCE or
    token refresh logic. The Combine helpers still persist tokens and emit instrumentation exactly like
    the async versions.
- **Observers:** `SpotifyClient.observerPublisher(bufferSize:)` streams `SpotifyClientEvent` values
    into Combine so you can tie instrumentation into `sink`/`assign` pipelines or analytics relays.
    Pass a buffer size to drop the oldest events when subscribers fall behind, mirroring the semantics
    of explicit `SpotifyClientObserver` instances.

## Cancellation & Backpressure

- Cancelling the returned `AnyCancellable` cancels the underlying `Task`, so long-running pagination streams stop immediately.
- All publishers emit on the call site scheduler; add `receive(on:)` to hop to the main actor.
- Errors are surfaced as `SpotifyClientError`, making it easy to switch between async and Combine flows without new error handling branches.

## Testing Publishers

Use the helpers in `Tests/Support/TestHelpers.swift`:

- `awaitFirstValue` bridges an `AnyPublisher` into async tests.
- `assertAggregatesPages` verifies pagination helpers aggregate items correctly.
- `assertIDsMutationPublisher`, `assertLimitOutOfRange`, and `assertIDBatchTooLarge` keep validation tests concise.

Combine-focused suites live under `Tests/SpotifyWebAPITests/**/CombineTests.swift`; they double as reference implementations for your own publisher extensions.

## Platform Availability

Combine does not exist on Linux or Windows. The publisher APIs only compile on Apple platforms where `Combine` is available, so no extra work is required for cross-platform consumers.
