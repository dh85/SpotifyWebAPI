# API Reference

## SpotifyClient

The main client class for interacting with the Spotify Web API.

### Initialization

```swift
let client = SpotifyClient(authenticator: authenticator)
let client = SpotifyClient(authenticator: authenticator, configuration: config)
```

### User Profile

#### `me() async throws -> CurrentUserProfile`
Get the current user's profile information.

```swift
let profile = try await client.me()
```

#### `getUser(_ userId: String) async throws -> PublicUserProfile`
Get a user's public profile information.

```swift
let user = try await client.getUser("spotify")
```

### Albums

#### `getAlbum(_ id: String, market: String? = nil) async throws -> Album`
Get an album by ID.

#### `getAlbums(_ ids: [String], market: String? = nil) async throws -> [Album]`
Get multiple albums by IDs (max 20).

#### `getAlbumTracks(_ id: String, market: String? = nil, limit: Int = 20, offset: Int = 0) async throws -> Page<SimplifiedTrack>`
Get tracks from an album.

#### `saveAlbums(_ ids: [String]) async throws`
Save albums to user's library (max 50).

#### `removeAlbums(_ ids: [String]) async throws`
Remove albums from user's library (max 50).

#### `checkSavedAlbums(_ ids: [String]) async throws -> [Bool]`
Check if albums are saved in user's library (max 50).

#### `savedAlbums(market: String? = nil, limit: Int = 20, offset: Int = 0) async throws -> Page<SavedAlbum>`
Get user's saved albums.

### Artists

#### `getArtist(_ id: String) async throws -> Artist`
Get an artist by ID.

#### `getArtists(_ ids: [String]) async throws -> [Artist]`
Get multiple artists by IDs (max 50).

#### `getArtistAlbums(_ id: String, includeGroups: Set<AlbumGroup> = [.album], market: String? = nil, limit: Int = 20, offset: Int = 0) async throws -> Page<SimplifiedAlbum>`
Get an artist's albums.

#### `getArtistTopTracks(_ id: String, market: String) async throws -> [Track]`
Get an artist's top tracks.

#### `getRelatedArtists(_ id: String) async throws -> [Artist]`
Get artists similar to a given artist.

### Tracks

#### `getTrack(_ id: String, market: String? = nil) async throws -> Track`
Get a track by ID.

#### `getTracks(_ ids: [String], market: String? = nil) async throws -> [Track]`
Get multiple tracks by IDs (max 50).

#### `saveTracks(_ ids: [String]) async throws`
Save tracks to user's library (max 50).

#### `removeTracks(_ ids: [String]) async throws`
Remove tracks from user's library (max 50).

#### `checkSavedTracks(_ ids: [String]) async throws -> [Bool]`
Check if tracks are saved in user's library (max 50).

#### `savedTracks(market: String? = nil, limit: Int = 20, offset: Int = 0) async throws -> Page<SavedTrack>`
Get user's saved tracks.

#### `getAudioFeatures(_ id: String) async throws -> AudioFeatures`
Get audio features for a track.

#### `getAudioFeatures(_ ids: [String]) async throws -> [AudioFeatures?]`
Get audio features for multiple tracks (max 100).

#### `getAudioAnalysis(_ id: String) async throws -> AudioAnalysis`
Get detailed audio analysis for a track.

### Playlists

#### `getPlaylist(_ id: String, market: String? = nil, fields: String? = nil) async throws -> Playlist`
Get a playlist by ID.

#### `getPlaylistTracks(_ id: String, market: String? = nil, fields: String? = nil, limit: Int = 100, offset: Int = 0) async throws -> Page<PlaylistTrackItem>`
Get tracks from a playlist.

#### `myPlaylists(limit: Int = 20, offset: Int = 0) async throws -> Page<SimplifiedPlaylist>`
Get current user's playlists.

#### `getUserPlaylists(_ userId: String, limit: Int = 20, offset: Int = 0) async throws -> Page<SimplifiedPlaylist>`
Get a user's playlists.

#### `createPlaylist(name: String, description: String? = nil, isPublic: Bool = true, collaborative: Bool = false) async throws -> Playlist`
Create a new playlist.

#### `addTracksToPlaylist(_ playlistId: String, uris: [String], position: Int? = nil) async throws -> String`
Add tracks to a playlist.

#### `removeTracksFromPlaylist(_ playlistId: String, uris: [String]) async throws -> String`
Remove tracks from a playlist.

#### `reorderPlaylistTracks(_ playlistId: String, rangeStart: Int, insertBefore: Int, rangeLength: Int = 1, snapshotId: String? = nil) async throws -> String`
Reorder tracks in a playlist.

#### `replacePlaylistTracks(_ playlistId: String, uris: [String]) async throws`
Replace all tracks in a playlist.

#### `changePlaylistDetails(_ playlistId: String, name: String? = nil, description: String? = nil, isPublic: Bool? = nil, collaborative: Bool? = nil) async throws`
Change playlist details.

#### `followPlaylist(_ playlistId: String, isPublic: Bool = true) async throws`
Follow a playlist.

#### `unfollowPlaylist(_ playlistId: String) async throws`
Unfollow a playlist.

#### `checkFollowingPlaylist(_ playlistId: String, userIds: [String]) async throws -> [Bool]`
Check if users are following a playlist.

### Player

#### `playbackState() async throws -> PlaybackState?`
Get current playback state.

#### `getDevices() async throws -> [SpotifyDevice]`
Get available devices.

#### `transferPlayback(to deviceId: String, play: Bool = false) async throws`
Transfer playback to a device.

#### `play(deviceId: String? = nil) async throws`
Start/resume playback.

#### `play(contextURI: String, offset: PlaybackOffset? = nil, positionMs: Int? = nil, deviceId: String? = nil) async throws`
Play a context (album, artist, playlist).

#### `play(uris: [String], offset: PlaybackOffset? = nil, positionMs: Int? = nil, deviceId: String? = nil) async throws`
Play specific tracks.

#### `pause(deviceId: String? = nil) async throws`
Pause playback.

#### `skipToNext(deviceId: String? = nil) async throws`
Skip to next track.

#### `skipToPrevious(deviceId: String? = nil) async throws`
Skip to previous track.

#### `seek(to positionMs: Int, deviceId: String? = nil) async throws`
Seek to position in current track.

#### `setRepeatMode(_ mode: RepeatMode, deviceId: String? = nil) async throws`
Set repeat mode.

#### `setVolume(_ volumePercent: Int, deviceId: String? = nil) async throws`
Set playback volume (0-100).

#### `setShuffle(_ state: Bool, deviceId: String? = nil) async throws`
Toggle shuffle.

#### `addToQueue(_ uri: String, deviceId: String? = nil) async throws`
Add track to queue.

#### `getQueue() async throws -> UserQueue`
Get the user's queue.

#### `recentlyPlayed(limit: Int = 20, after: Date? = nil, before: Date? = nil) async throws -> CursorBasedPage<PlayHistoryItem>`
Get recently played tracks.

### Search

#### `search(query: String, types: Set<SearchType>, market: String? = nil, limit: Int = 20, offset: Int = 0, includeExternal: ExternalContent? = nil) async throws -> SearchResults`
Search for albums, artists, playlists, tracks, shows, or episodes.

### Browse

#### `newReleases(country: String? = nil, limit: Int = 20, offset: Int = 0) async throws -> Page<SimplifiedAlbum>`
Get new album releases.

#### `featuredPlaylists(country: String? = nil, limit: Int = 20, offset: Int = 0, timestamp: Date? = nil) async throws -> Page<SimplifiedPlaylist>`
Get featured playlists.

#### `getCategories(country: String? = nil, locale: String? = nil, limit: Int = 20, offset: Int = 0) async throws -> Page<Category>`
Get browse categories.

#### `getCategory(_ categoryId: String, country: String? = nil, locale: String? = nil) async throws -> Category`
Get a browse category.

#### `getCategoryPlaylists(_ categoryId: String, country: String? = nil, limit: Int = 20, offset: Int = 0) async throws -> Page<SimplifiedPlaylist>`
Get playlists for a category.

#### `getRecommendations(seedArtists: [String] = [], seedGenres: [String] = [], seedTracks: [String] = [], limit: Int = 20, market: String? = nil, ...) async throws -> Recommendations`
Get track recommendations based on seeds.

### Following

#### `followArtists(_ ids: [String]) async throws`
Follow artists (max 50).

#### `unfollowArtists(_ ids: [String]) async throws`
Unfollow artists (max 50).

#### `followUsers(_ ids: [String]) async throws`
Follow users (max 50).

#### `unfollowUsers(_ ids: [String]) async throws`
Unfollow users (max 50).

#### `checkFollowingArtists(_ ids: [String]) async throws -> [Bool]`
Check if following artists (max 50).

#### `checkFollowingUsers(_ ids: [String]) async throws -> [Bool]`
Check if following users (max 50).

#### `followedArtists(limit: Int = 20, after: String? = nil) async throws -> CursorBasedPage<Artist>`
Get followed artists.

#### `topArtists(timeRange: TimeRange = .mediumTerm, limit: Int = 20, offset: Int = 0) async throws -> Page<Artist>`
Get user's top artists.

#### `topTracks(timeRange: TimeRange = .mediumTerm, limit: Int = 20, offset: Int = 0) async throws -> Page<Track>`
Get user's top tracks.

## Authentication

### SpotifyAuthorizationCodeAuthenticator

```swift
let authenticator = SpotifyAuthorizationCodeAuthenticator(
    clientId: String,
    clientSecret: String,
    redirectURI: URL,
    scopes: Set<SpotifyScope> = [],
    tokenStore: TokenStore? = nil
)
```

#### Methods

- `makeAuthorizationURL(scopes: Set<SpotifyScope>, state: String, showDialog: Bool = false) -> URL`
- `handleCallback(url: URL, state: String) async throws`
- `refreshAccessTokenIfNeeded() async throws`

### SpotifyPKCEAuthenticator

```swift
let authenticator = SpotifyPKCEAuthenticator(
    clientId: String,
    redirectURI: URL,
    scopes: Set<SpotifyScope> = [],
    tokenStore: TokenStore? = nil
)
```

#### Methods

- `generatePKCE() throws -> PKCEPair`
- `makeAuthorizationURL(scopes: Set<SpotifyScope>, codeChallenge: String, state: String, showDialog: Bool = false) -> URL`
- `handleCallback(url: URL, codeVerifier: String, state: String) async throws`

### SpotifyClientCredentialsAuthenticator

```swift
let authenticator = SpotifyClientCredentialsAuthenticator(
    clientId: String,
    clientSecret: String,
    scopes: Set<SpotifyScope> = [],
    tokenStore: TokenStore? = nil
)
```

## Models

### Core Models

#### CurrentUserProfile
```swift
struct CurrentUserProfile {
    let id: String
    let displayName: String?
    let email: String?
    let country: String?
    let product: String?
    let href: URL
    let externalUrls: SpotifyExternalUrls
    let images: [SpotifyImage]
    let followers: SpotifyFollowers
    let explicitContent: ExplicitContentSettings?
    let type: SpotifyObjectType
    let uri: String
}
```

#### Album
```swift
struct Album {
    let albumType: AlbumType
    let totalTracks: Int
    let availableMarkets: [String]
    let externalUrls: SpotifyExternalUrls
    let href: URL
    let id: String
    let images: [SpotifyImage]?
    let name: String
    let releaseDate: String
    let releaseDatePrecision: ReleaseDatePrecision
    let restrictions: Restriction?
    let type: SpotifyObjectType
    let uri: String
    let artists: [SimplifiedArtist]
    let tracks: Page<SimplifiedTrack>
    let copyrights: [SpotifyCopyright]
    let externalIds: SpotifyExternalIds
    let label: String
    let popularity: Int
    let genres: [String]
}
```

#### Artist
```swift
struct Artist {
    let externalUrls: SpotifyExternalUrls
    let followers: SpotifyFollowers
    let genres: [String]
    let href: URL
    let id: String
    let images: [SpotifyImage]
    let name: String
    let popularity: Int
    let type: SpotifyObjectType
    let uri: String
}
```

#### Track
```swift
struct Track {
    let album: SimplifiedAlbum
    let artists: [SimplifiedArtist]
    let availableMarkets: [String]
    let discNumber: Int
    let durationMs: Int
    let explicit: Bool
    let externalIds: SpotifyExternalIds
    let externalUrls: SpotifyExternalUrls
    let href: URL
    let id: String
    let isPlayable: Bool?
    let linkedFrom: LinkedFrom?
    let restrictions: Restriction?
    let name: String
    let popularity: Int
    let previewUrl: URL?
    let trackNumber: Int
    let type: SpotifyObjectType
    let uri: String
    let isLocal: Bool
}
```

#### Playlist
```swift
struct Playlist {
    let collaborative: Bool
    let description: String?
    let externalUrls: SpotifyExternalUrls
    let followers: SpotifyFollowers
    let href: URL
    let id: String
    let images: [SpotifyImage]
    let name: String
    let owner: SpotifyPublicUser
    let isPublic: Bool?
    let snapshotId: String
    let tracks: Page<PlaylistTrackItem>
    let type: SpotifyObjectType
    let uri: String
}
```

#### PlaybackState
```swift
struct PlaybackState {
    let device: SpotifyDevice?
    let repeatState: RepeatMode
    let shuffleState: Bool
    let context: PlaybackContext?
    let timestamp: Int
    let progressMs: Int?
    let isPlaying: Bool
    let item: PlayableItem?
    let currentlyPlayingType: CurrentlyPlayingType
    let actions: Actions
}
```

### Pagination Models

#### Page<T>
```swift
struct Page<T> {
    let href: URL
    let items: [T]
    let limit: Int
    let next: URL?
    let offset: Int
    let previous: URL?
    let total: Int
}
```

#### CursorBasedPage<T>
```swift
struct CursorBasedPage<T> {
    let href: URL
    let items: [T]
    let limit: Int
    let next: URL?
    let cursors: Cursors?
    let total: Int?
}
```

## Configuration

### SpotifyClientConfiguration

```swift
struct SpotifyClientConfiguration {
    let maxRateLimitRetries: Int
    let rateLimitRetryDelay: TimeInterval
    let requestTimeout: TimeInterval
    let customHeaders: [String: String]
    let debugConfiguration: DebugConfiguration
    let networkRecoveryConfiguration: NetworkRecoveryConfiguration
}
```

### DebugConfiguration

```swift
struct DebugConfiguration {
    let enableRequestLogging: Bool
    let enableResponseLogging: Bool
    let enableTokenLogging: Bool
    let enablePerformanceMetrics: Bool
    let logLevel: LogLevel
    let maxPerformanceEntries: Int
}
```

## Error Types

### SpotifyAuthError
```swift
enum SpotifyAuthError: Error {
    case tokenExpired
    case invalidCredentials
    case missingRefreshToken
    case unexpectedResponse
    case stateMismatch
    case missingCode
    case missingState
}
```

### SpotifyAPIError
```swift
struct SpotifyAPIError: Error {
    let statusCode: Int?
    let message: String
    let reason: String?
}
```

### MockError
```swift
enum MockError: Error {
    case noMockData(String)
}
```

## Scopes

### SpotifyScope
```swift
enum SpotifyScope: String, CaseIterable {
    case userReadPrivate = "user-read-private"
    case userReadEmail = "user-read-email"
    case playlistReadPrivate = "playlist-read-private"
    case playlistReadCollaborative = "playlist-read-collaborative"
    case playlistModifyPublic = "playlist-modify-public"
    case playlistModifyPrivate = "playlist-modify-private"
    case userLibraryRead = "user-library-read"
    case userLibraryModify = "user-library-modify"
    case userReadPlaybackState = "user-read-playback-state"
    case userModifyPlaybackState = "user-modify-playback-state"
    case userReadCurrentlyPlaying = "user-read-currently-playing"
    case userReadRecentlyPlayed = "user-read-recently-played"
    case userTopRead = "user-top-read"
    case userFollowRead = "user-follow-read"
    case userFollowModify = "user-follow-modify"
    case ugcImageUpload = "ugc-image-upload"
    case streaming = "streaming"
    case appRemoteControl = "app-remote-control"
}
```

## Testing

### MockSpotifyClient

```swift
class MockSpotifyClient {
    // Mock Data Properties
    var mockProfile: CurrentUserProfile?
    var mockAlbum: Album?
    var mockTrack: Track?
    var mockPlaylist: Playlist?
    var mockPlaylists: [SimplifiedPlaylist]
    var mockArtist: Artist?
    var mockPlaybackState: PlaybackState?
    var mockError: Error?
    
    // Call Tracking Properties
    private(set) var getUsersCalled: Bool
    private(set) var getAlbumCalled: Bool
    private(set) var getTrackCalled: Bool
    private(set) var getPlaylistCalled: Bool
    private(set) var pauseCalled: Bool
    private(set) var playCalled: Bool
    
    // Methods
    func reset()
    func me() async throws -> CurrentUserProfile
    func getAlbum(_ id: String) async throws -> Album
    func getTrack(_ id: String) async throws -> Track
    func getPlaylist(_ id: String) async throws -> Playlist
    func myPlaylists() async throws -> [SimplifiedPlaylist]
    func pause() async throws
    func play() async throws
    func playbackState() async throws -> PlaybackState?
}
```