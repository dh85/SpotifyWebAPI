import Foundation

// MARK: - Common Use Case Conveniences

extension SpotifyClient where Capability == UserAuthCapability {
  
  // MARK: - Quick Search
  
  /// Quick search for tracks by name.
  ///
  /// ```swift
  /// let tracks = try await client.searchTracks("Bohemian Rhapsody")
  /// ```
  public func searchTracks(_ query: String, limit: Int = 20) async throws -> [Track] {
    try await search.query(query).forTracks().withLimit(limit).executeTracks().items
  }
  
  /// Quick search for albums by name.
  ///
  /// ```swift
  /// let albums = try await client.searchAlbums("Abbey Road")
  /// ```
  public func searchAlbums(_ query: String, limit: Int = 20) async throws -> [SimplifiedAlbum] {
    try await search.query(query).forAlbums().withLimit(limit).executeAlbums().items
  }
  
  /// Quick search for artists by name.
  ///
  /// ```swift
  /// let artists = try await client.searchArtists("The Beatles")
  /// ```
  public func searchArtists(_ query: String, limit: Int = 20) async throws -> [Artist] {
    try await search.query(query).forArtists().withLimit(limit).executeArtists().items
  }
  
  /// Quick search for playlists by name.
  ///
  /// ```swift
  /// let playlists = try await client.searchPlaylists("workout")
  /// ```
  public func searchPlaylists(_ query: String, limit: Int = 20) async throws -> [SimplifiedPlaylist] {
    try await search.query(query).forPlaylists().withLimit(limit).executePlaylists().items
  }
  
  // MARK: - Current User Shortcuts
  
  /// Get the current user's profile.
  ///
  /// Shortcut for `client.users.me()`.
  public func me() async throws -> CurrentUserProfile {
    try await users.me()
  }
  
  /// Get the current user's saved tracks.
  ///
  /// ```swift
  /// let savedTracks = try await client.mySavedTracks(limit: 50)
  /// ```
  public func mySavedTracks(limit: Int = 20, offset: Int = 0) async throws -> Page<SavedTrack> {
    try await tracks.saved(limit: limit, offset: offset)
  }
  
  /// Get the current user's saved albums.
  ///
  /// ```swift
  /// let savedAlbums = try await client.mySavedAlbums(limit: 50)
  /// ```
  public func mySavedAlbums(limit: Int = 20, offset: Int = 0) async throws -> Page<SavedAlbum> {
    try await albums.saved(limit: limit, offset: offset)
  }
  
  /// Get the current user's playlists.
  ///
  /// ```swift
  /// let playlists = try await client.myPlaylists()
  /// ```
  public func myPlaylists(limit: Int = 20, offset: Int = 0) async throws -> Page<SimplifiedPlaylist> {
    try await playlists.myPlaylists(limit: limit, offset: offset)
  }
  
  /// Get the current user's top artists.
  ///
  /// ```swift
  /// let topArtists = try await client.myTopArtists()
  /// ```
  public func myTopArtists(
    timeRange: TimeRange = .mediumTerm,
    limit: Int = 20
  ) async throws -> [Artist] {
    try await users.topArtists(timeRange: timeRange, limit: limit, offset: 0).items
  }
  
  /// Get the current user's top tracks.
  ///
  /// ```swift
  /// let topTracks = try await client.myTopTracks()
  /// ```
  public func myTopTracks(
    timeRange: TimeRange = .mediumTerm,
    limit: Int = 20
  ) async throws -> [Track] {
    try await users.topTracks(timeRange: timeRange, limit: limit, offset: 0).items
  }
  
  // MARK: - Playback Shortcuts
  
  /// Get the current playback state.
  ///
  /// ```swift
  /// if let state = try await client.currentPlayback() {
  ///     print("Playing: \(state.item?.name ?? "Nothing")")
  /// }
  /// ```
  public func currentPlayback() async throws -> PlaybackState? {
    try await player.state()
  }
  
  /// Get recently played tracks.
  ///
  /// ```swift
  /// let recent = try await client.recentlyPlayed(limit: 10)
  /// ```
  public func recentlyPlayed(limit: Int = 20) async throws -> [PlayHistoryItem] {
    try await player.recentlyPlayed(limit: limit).items
  }
  
  /// Pause playback.
  ///
  /// ```swift
  /// try await client.pause()
  /// ```
  public func pause() async throws {
    try await player.pause()
  }
  
  /// Resume playback.
  ///
  /// ```swift
  /// try await client.resume()
  /// ```
  public func resume() async throws {
    try await player.resume()
  }
  
  /// Play a track, album, or playlist by URI.
  ///
  /// ```swift
  /// try await client.play("spotify:track:...")
  /// ```
  public func play(_ uri: String) async throws {
    try await player.play(contextURI: uri)
  }
}

// MARK: - App Client Conveniences

extension SpotifyClient where Capability == AppOnlyAuthCapability {
  
  /// Quick search for tracks by name (app-only).
  public func searchTracks(_ query: String, limit: Int = 20) async throws -> [Track] {
    try await search.query(query).forTracks().withLimit(limit).executeTracks().items
  }
  
  /// Quick search for albums by name (app-only).
  public func searchAlbums(_ query: String, limit: Int = 20) async throws -> [SimplifiedAlbum] {
    try await search.query(query).forAlbums().withLimit(limit).executeAlbums().items
  }
  
  /// Quick search for artists by name (app-only).
  public func searchArtists(_ query: String, limit: Int = 20) async throws -> [Artist] {
    try await search.query(query).forArtists().withLimit(limit).executeArtists().items
  }
}
