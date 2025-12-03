# Parsing Spotify URIs and URLs

Extract resource IDs from Spotify URIs and URLs with the SpotifyURI utility.

## Overview

Spotify resources can be identified by either URIs (`spotify:track:abc123`) or web URLs (`https://open.spotify.com/track/abc123`). The ``SpotifyURI`` struct provides a unified way to parse both formats and extract the resource type and ID.

This eliminates the need for manual string parsing and regular expressions in your application code.

## Basic Usage

Parse a Spotify URI or URL to extract the resource type and ID:

```swift
import SpotifyKit

// Parse from URI
let uri = SpotifyURI(string: "spotify:track:6rqhFgbbKwnb9MLmUQDhG6")
print(uri?.type) // .track
print(uri?.id)   // "6rqhFgbbKwnb9MLmUQDhG6"

// Parse from URL
let uri2 = SpotifyURI(string: "https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M")
print(uri2?.type) // .playlist
print(uri2?.id)   // "37i9dQZF1DXcBWIGoYBM5M"
```

## Supported Formats

### URI Format
```
spotify:track:6rqhFgbbKwnb9MLmUQDhG6
spotify:album:4aawyAB9vmqN3uQ7FjRGTy
spotify:artist:0OdUWJ0sBjDrqHygGUXeCF
spotify:playlist:37i9dQZF1DXcBWIGoYBM5M
spotify:show:4rOoJ6Egrf8K2IrywzwOMk
spotify:episode:512ojhOuo1ktJprKbVcKyQ
spotify:user:spotify
```

### URL Format
```
https://open.spotify.com/track/6rqhFgbbKwnb9MLmUQDhG6
https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M?si=abc123
https://spotify.com/track/6rqhFgbbKwnb9MLmUQDhG6
```

## Converting Between Formats

Convert between URI and URL representations:

```swift
let uri = SpotifyURI(string: "https://open.spotify.com/track/6rqhFgbbKwnb9MLmUQDhG6")!

// Get URI string
print(uri.uri) // "spotify:track:6rqhFgbbKwnb9MLmUQDhG6"

// Get URL
print(uri.url) // URL("https://open.spotify.com/track/6rqhFgbbKwnb9MLmUQDhG6")
```

## Using with API Calls

Use parsed URIs to make API calls:

```swift
// User provides a playlist URL or URI
let input = "https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M"

// Parse and validate type in one step
guard let uri = SpotifyURI(string: input, expectedType: .playlist) else {
    print("Invalid playlist URL")
    return
}

// Use the extracted ID
let playlist = try await client.playlists.get(uri.id)
print("Playlist: \(playlist.name)")
```

## CLI Application Example

Simplify URL parsing in command-line tools:

```swift
// Before: Manual parsing (15 lines)
func extractPlaylistID(from url: String) throws -> String {
    if url.hasPrefix("spotify:playlist:") {
        return String(url.dropFirst("spotify:playlist:".count))
    }
    
    if let range = url.range(of: #"playlist/([a-zA-Z0-9]+)"#, options: .regularExpression) {
        let match = String(url[range])
        return String(match.dropFirst("playlist/".count))
    }
    
    throw InvalidURLError()
}

// After: Using SpotifyURI (3 lines)
func extractPlaylistID(from url: String) throws -> String {
    guard let uri = SpotifyURI(string: url, expectedType: .playlist) else {
        throw InvalidURLError()
    }
    return uri.id
}
```

## Type Validation

Validate the resource type during parsing:

```swift
// Only accept playlist URLs
if let uri = SpotifyURI(string: userInput, expectedType: .playlist) {
    let playlist = try await client.playlists.get(uri.id)
}

// Only accept track URLs
if let uri = SpotifyURI(string: userInput, expectedType: .track) {
    let track = try await client.tracks.get(uri.id)
}

// Accept any valid Spotify URL
if let uri = SpotifyURI(string: userInput) {
    switch uri.type {
    case .track:
        let track = try await client.tracks.get(uri.id)
    case .playlist:
        let playlist = try await client.playlists.get(uri.id)
    default:
        print("Unsupported type: \(uri.type)")
    }
}
```

## Validation

SpotifyURI returns `nil` for invalid inputs:

```swift
SpotifyURI(string: "invalid") // nil
SpotifyURI(string: "spotify:invalid:123") // nil
SpotifyURI(string: "https://google.com/track/123") // nil
SpotifyURI(string: "") // nil
```

Validate resource types:

```swift
let input = getUserInput()

guard let uri = SpotifyURI(string: input) else {
    print("Invalid Spotify URL or URI")
    return
}

switch uri.type {
case .track:
    let track = try await client.tracks.get(uri.id)
case .playlist:
    let playlist = try await client.playlists.get(uri.id)
case .album:
    let album = try await client.albums.get(uri.id)
default:
    print("Unsupported resource type: \(uri.type)")
}
```

## Collections and Codable

SpotifyURI conforms to `Equatable`, `Hashable`, and `Codable`:

```swift
// Use in Sets
var favorites = Set<SpotifyURI>()
favorites.insert(SpotifyURI(string: "spotify:track:abc123")!)

// Use in Dictionaries
var metadata: [SpotifyURI: String] = [:]
metadata[SpotifyURI(string: "spotify:track:abc123")!] = "My favorite song"

// Encode/Decode
struct Playlist: Codable {
    let name: String
    let tracks: [SpotifyURI]
}

let playlist = Playlist(
    name: "My Playlist",
    tracks: [
        SpotifyURI(string: "spotify:track:abc123")!,
        SpotifyURI(string: "spotify:track:xyz789")!
    ]
)

let encoded = try JSONEncoder().encode(playlist)
let decoded = try JSONDecoder().decode(Playlist.self, from: encoded)
```

## Resource Types

Supported resource types:

- ``SpotifyURI/ResourceType/track`` - Individual tracks
- ``SpotifyURI/ResourceType/album`` - Albums
- ``SpotifyURI/ResourceType/artist`` - Artists
- ``SpotifyURI/ResourceType/playlist`` - Playlists
- ``SpotifyURI/ResourceType/show`` - Podcast shows
- ``SpotifyURI/ResourceType/episode`` - Podcast episodes
- ``SpotifyURI/ResourceType/user`` - User profiles

## See Also

- ``SpotifyURI``
- ``SpotifyURI/ResourceType``
