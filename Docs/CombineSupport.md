# Combine Support

SpotifyWebAPI exposes optional Combine publisher variants that mirror the async/await APIs. Everything is wrapped in `#if canImport(Combine)` so Linux builds remain untouched, while Apple platforms running macOS 10.15+/iOS 13+/tvOS 13+/watchOS 6+ can opt into Combine.

## Usage

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

Every `*Publisher` method internally calls the async implementation, so behavior stays identical regardless of which concurrency model you choose.

## Platform Availability

Combine does not exist on Linux or Windows. The publisher APIs only compile on Apple platforms where `Combine` is available, so no extra work is required for cross-platform consumers.
