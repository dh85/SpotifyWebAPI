# Getting Started

Learn how to integrate SpotifyWebAPI into your project and make your first API call.

## Installation

Add SpotifyWebAPI to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/SpotifyWebAPI.git", from: "1.0.0")
]
```

## Quick Start

### 1. Create a Spotify App

Visit the [Spotify Developer Dashboard](https://developer.spotify.com/dashboard) and create a new app to get your client ID and secret.

### 2. Choose an Authentication Flow

SpotifyWebAPI supports three authentication flows:

**PKCE (Recommended for mobile/public apps)**
```swift
let client = SpotifyClient.pkce(
    clientID: "your-client-id",
    redirectURI: URL(string: "myapp://callback")!,
    scopes: [.userReadPrivate, .playlistModifyPublic]
)
```

**Authorization Code (For server-side apps)**
```swift
let client = SpotifyClient.authorizationCode(
    clientID: "your-client-id",
    clientSecret: "your-client-secret",
    redirectURI: URL(string: "https://myapp.com/callback")!,
    scopes: [.userReadPrivate]
)
```

**Client Credentials (For app-only access)**
```swift
let client = SpotifyClient.clientCredentials(
    clientID: "your-client-id",
    clientSecret: "your-client-secret"
)
```

### 3. Make Your First Request

```swift
// Get current user profile
let profile = try await client.users.me()
print("Hello, \(profile.displayName ?? "User")!")

// Search for tracks
let results = try await client.search.execute(
    query: "Bohemian Rhapsody",
    types: [.track]
)

// Get a playlist
let playlist = try await client.playlists.get("37i9dQZF1DXcBWIGoYBM5M")
print("\(playlist.name) has \(playlist.totalTracks) tracks")
```

## Next Steps

- Learn about <doc:Authentication> flows in detail
- Explore <doc:Pagination> for handling large collections
- Check out the API reference for specific services
