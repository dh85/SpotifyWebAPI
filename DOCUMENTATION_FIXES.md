# Documentation API Corrections

## Corrections Needed

### 1. Authentication - Use Factory Methods

❌ **Incorrect:**
```swift
let authenticator = SpotifyPKCEAuthenticator(...)
let client = SpotifyClient(authenticator: authenticator)
```

✅ **Correct:**
```swift
let client = SpotifyClient.pkce(
    clientID: "your-client-id",
    redirectURI: URL(string: "myapp://callback")!,
    scopes: [.userReadPrivate]
)
```

### 2. Playlists - Method Names

❌ **Incorrect:**
```swift
let playlists = try await client.playlists.my()
```

✅ **Correct:**
```swift
let playlists = try await client.playlists.myPlaylists()
```

### 3. Pagination - Use Service Methods

❌ **Incorrect:**
```swift
let allPlaylists = try await client.collectAllPages { offset in
    try await client.playlists.my(offset: offset, limit: 50)
}
```

✅ **Correct:**
```swift
let allPlaylists = try await client.playlists.allMyPlaylists()
```

### 4. Streaming - Use Service Methods

❌ **Incorrect:**
```swift
for try await playlist in client.streamPages({ offset in
    try await client.playlists.my(offset: offset, limit: 50)
}) {
    print(playlist.name)
}
```

✅ **Correct:**
```swift
for try await item in client.playlists.streamItems("playlist_id") {
    if let track = item.track as? Track {
        print(track.name)
    }
}
```

### 5. Testing - Use Swift Testing

❌ **Incorrect:**
```swift
import XCTest
@testable import SpotifyWebAPI

class MyTests: XCTestCase {
    func testUserProfile() async throws {
        XCTAssertEqual(viewModel.userName, "Test User")
    }
}
```

✅ **Correct:**
```swift
import Testing
@testable import SpotifyWebAPI

@Suite("My Tests")
struct MyTests {
    @Test("User profile loads correctly")
    func userProfile() async throws {
        let mock = MockSpotifyClient()
        mock.mockProfile = CurrentUserProfile(
            id: "test-user",
            displayName: "Test User",
            email: "test@example.com"
        )
        
        let viewModel = MyViewModel(client: mock)
        await viewModel.loadProfile()
        
        #expect(viewModel.userName == "Test User")
        #expect(mock.getUsersCalled)
    }
}
```

### 6. Albums/Tracks - Use Set for IDs

❌ **Incorrect:**
```swift
let albums = try await client.albums.several(["id1", "id2"])
```

✅ **Correct:**
```swift
let albums = try await client.albums.several(ids: ["id1", "id2", "id3"])
```

### 7. Player - Correct Method Names

❌ **Incorrect:**
```swift
try await client.player.play()
```

✅ **Correct:**
```swift
// Resume playback
try await client.player.resume()

// Or play specific content
try await client.player.play(contextURI: "spotify:playlist:...")
try await client.player.play(uris: ["spotify:track:..."])
```

### 8. Playlist Creation - Requires User ID

❌ **Incorrect:**
```swift
let playlist = try await client.playlists.create(
    name: "My Playlist"
)
```

✅ **Correct:**
```swift
let profile = try await client.users.me()
let playlist = try await client.playlists.create(
    for: profile.id,
    name: "My Playlist",
    description: "Created with SpotifyWebAPI"
)
```

## Files to Update

1. README.md
2. Sources/SpotifyWebAPI/SpotifyWebAPI.docc/GettingStarted.md
3. Sources/SpotifyWebAPI/SpotifyWebAPI.docc/Authentication.md
4. Sources/SpotifyWebAPI/SpotifyWebAPI.docc/Pagination.md
5. TESTING.md
6. DOCUMENTATION_EXAMPLES.md
7. README_DOCUMENTATION.md

## Summary of Changes

- Replace all authenticator initialization with factory methods
- Fix `my()` to `myPlaylists()`
- Remove direct `collectAllPages` usage, use service methods
- Remove direct `streamPages` usage, use service methods  
- Update testing examples to Swift Testing
- Fix `several()` to use `ids:` parameter
- Fix `play()` to `resume()` or `play(contextURI:)` / `play(uris:)`
- Add user ID to playlist creation examples
