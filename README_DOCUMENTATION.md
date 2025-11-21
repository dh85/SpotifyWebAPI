# SpotifyWebAPI Documentation

Add this section to your README.md:

---

## 📚 Documentation

Comprehensive documentation is available at: **[https://yourusername.github.io/SpotifyWebAPI/documentation/spotifywebapi/](https://yourusername.github.io/SpotifyWebAPI/documentation/spotifywebapi/)**

### Quick Links

- [Getting Started](https://yourusername.github.io/SpotifyWebAPI/documentation/spotifywebapi/gettingstarted) - Installation and first API call
- [Authentication](https://yourusername.github.io/SpotifyWebAPI/documentation/spotifywebapi/authentication) - PKCE, Authorization Code, and Client Credentials flows
- [Pagination](https://yourusername.github.io/SpotifyWebAPI/documentation/spotifywebapi/pagination) - Handling large collections efficiently
- [API Reference](https://yourusername.github.io/SpotifyWebAPI/documentation/spotifywebapi) - Complete API documentation

### Features

- ✅ **100% API Coverage** - All Spotify Web API endpoints
- ✅ **50+ Code Examples** - Real-world usage patterns
- ✅ **Type Documentation** - Every public type documented
- ✅ **Guides & Tutorials** - Step-by-step instructions
- ✅ **Search** - Find what you need quickly

---

## Quick Example

```swift
import SpotifyWebAPI

// Create client
let client = SpotifyClient.pkce(
    clientID: "your-client-id",
    redirectURI: URL(string: "myapp://callback")!,
    scopes: [.userReadPrivate, .playlistModifyPublic]
)

// Get user profile
let profile = try await client.users.me()
print("Hello, \(profile.displayName ?? "User")!")

// Search for tracks
let results = try await client.search.execute(
    query: "Bohemian Rhapsody",
    types: [.track]
)

// Control playback
try await client.player.play(
    contextURI: "spotify:playlist:37i9dQZF1DXcBWIGoYBM5M"
)
```

See the [Getting Started guide](https://yourusername.github.io/SpotifyWebAPI/documentation/spotifywebapi/gettingstarted) for more examples.

---
