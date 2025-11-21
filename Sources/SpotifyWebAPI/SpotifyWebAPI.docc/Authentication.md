# Authentication

Learn how to authenticate with Spotify using PKCE, Authorization Code, or Client Credentials flows.

## Overview

SpotifyWebAPI supports all three OAuth 2.0 flows provided by Spotify. Choose the flow that matches your application type.

## PKCE Flow

**Best for**: Mobile apps, single-page applications, and any public client that cannot securely store a client secret.

### Setup

```swift
let client = SpotifyClient.pkce(
    clientID: "your-client-id",
    redirectURI: URL(string: "myapp://callback")!,
    scopes: [.userReadPrivate, .playlistModifyPublic]
)
```

### Authorization Flow

```swift
// 1. Generate authorization URL
let authURL = try client.backend.makeAuthorizationURL()

// 2. Open URL in browser/web view
// User authorizes your app

// 3. Handle callback
let tokens = try await client.backend.handleCallback(callbackURL)

// 4. Client is now authenticated
let profile = try await client.users.me()
```

## Authorization Code Flow

**Best for**: Server-side applications that can securely store a client secret.

### Setup

```swift
let client = SpotifyClient.authorizationCode(
    clientID: "your-client-id",
    clientSecret: "your-client-secret",
    redirectURI: URL(string: "https://myapp.com/callback")!,
    scopes: [.userReadPrivate, .playlistModifyPublic]
)
```

### Authorization Flow

Same as PKCE, but uses client secret for token exchange.

## Client Credentials Flow

**Best for**: Server-to-server applications that don't need user-specific data.

### Setup

```swift
let client = SpotifyClient.clientCredentials(
    clientID: "your-client-id",
    clientSecret: "your-client-secret"
)
```

### Usage

```swift
// No authorization flow needed
// Tokens are automatically obtained

let album = try await client.albums.get("album-id")
let results = try await client.search.execute(query: "Queen", types: [.artist])
```

**Note**: Client Credentials flow only provides access to public data. User-specific endpoints (like playlists, library) are not available.

## Scopes

Request only the scopes your app needs:

```swift
let scopes: Set<SpotifyScope> = [
    .userReadPrivate,           // Read user profile
    .userReadEmail,             // Read user email
    .playlistReadPrivate,       // Read private playlists
    .playlistModifyPublic,      // Modify public playlists
    .playlistModifyPrivate,     // Modify private playlists
    .userLibraryRead,           // Read saved albums/tracks
    .userLibraryModify,         // Save/remove albums/tracks
    .userReadPlaybackState,     // Read playback state
    .userModifyPlaybackState,   // Control playback
    .userReadRecentlyPlayed,    // Read recently played
    .userTopRead                // Read top artists/tracks
]
```

## Token Management

Tokens are automatically refreshed when expired. You can also monitor token expiration:

```swift
client.onTokenExpiring { expiresIn in
    if expiresIn < 300 {
        print("Token expires in \(expiresIn) seconds")
    }
}
```

## See Also

- ``SpotifyClient``
- ``SpotifyPKCEAuthenticator``
- ``SpotifyAuthorizationCodeAuthenticator``
- ``SpotifyClientCredentialsAuthenticator``
