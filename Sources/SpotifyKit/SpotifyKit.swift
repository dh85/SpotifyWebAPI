/// Umbrella file for the SpotifyKit library.
///
/// All public types are automatically available when you `import SpotifyKit`.
/// No need to use qualified names like `SpotifyKit.SpotifyClient`.
///
/// ## Quick Start
/// ```swift
/// import SpotifyKit
///
/// let client = SpotifyClient.pkce(
///     clientID: "your-client-id",
///     redirectURI: URL(string: "myapp://callback")!,
///     scopes: [.userReadPrivate, .playlistModifyPublic]
/// )
///
/// // Convenience methods for common tasks
/// let profile = try await client.me()
/// let tracks = try await client.searchTracks("Bohemian Rhapsody")
/// let topArtists = try await client.myTopArtists()
///
/// // Or use the full API
/// let results = try await client.search.query("rock").forTracks().execute()
/// ```
