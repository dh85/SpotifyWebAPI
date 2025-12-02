import Foundation

/// Convenience builders for the most common Spotify models used in consumer tests.
///
/// The fixtures intentionally mirror the payloads returned by the real Web API so
/// you can focus on your business logic instead of assembling verbose structs.
public enum SpotifyTestFixtures {

    /// Returns a mock current user profile with sensible defaults.
    public static func currentUserProfile(
        id: String = "testUser",
        displayName: String? = "Test User",
        email: String? = "test@example.com",
        country: String? = "US",
        product: String? = "premium"
    ) -> CurrentUserProfile {
        CurrentUserProfile(
            id: id,
            displayName: displayName,
            email: email,
            country: country,
            product: product,
            href: URL(string: "https://api.spotify.com/v1/users/\(id)")!,
            externalUrls: SpotifyExternalUrls(
                spotify: URL(string: "https://open.spotify.com/user/\(id)")
            ),
            images: [],
            followers: SpotifyFollowers(href: nil, total: 0),
            explicitContent: nil,
            type: .user,
            uri: "spotify:user:\(id)"
        )
    }

    /// Returns a simplified playlist for testing list UIs.
    public static func simplifiedPlaylist(
        id: String = "testPlaylist",
        name: String = "Mock Playlist",
        ownerID: String = "playlistOwner",
        collaborative: Bool = false,
        isPublic: Bool = true,
        totalTracks: Int = 25
    ) -> SimplifiedPlaylist {
        let href = URL(string: "https://api.spotify.com/v1/playlists/\(id)")!
        return SimplifiedPlaylist(
            collaborative: collaborative,
            description: "Playlist fixture",
            externalUrls: SpotifyExternalUrls(
                spotify: URL(string: "https://open.spotify.com/playlist/\(id)")
            ),
            href: href,
            id: id,
            images: [],
            name: name,
            owner: SpotifyPublicUser(
                externalUrls: nil,
                href: nil,
                id: ownerID,
                type: .user,
                uri: "spotify:user:\(ownerID)",
                displayName: ownerID
            ),
            isPublic: isPublic,
            snapshotId: UUID().uuidString,
            tracks: PlaylistTracksRef(
                href: URL(string: "\(href.absoluteString)/tracks"),
                total: totalTracks
            ),
            type: .playlist,
            uri: "spotify:playlist:\(id)"
        )
    }

    /// Returns a realistic playback state that can be tweaked per test.
    public static func playbackState(
        deviceName: String = "Mock Device",
        isPlaying: Bool = false,
        repeatState: PlaybackState.RepeatState = .off,
        shuffleState: Bool = false,
        currentlyPlayingType: PlaybackState.CurrentlyPlayingType = .ad,
        timestamp: Date = Date()
    ) -> PlaybackState {
        let payload = PlaybackStateFixturePayload(
            device: SpotifyDevice(
                id: "device\(UUID().uuidString.prefix(6))",
                isActive: true,
                isPrivateSession: false,
                isRestricted: false,
                name: deviceName,
                type: "computer",
                volumePercent: 50,
                supportsVolume: true
            ),
            repeatState: repeatState,
            shuffleState: shuffleState,
            context: PlaybackContext(
                type: "playlist",
                href: URL(string: "https://api.spotify.com/v1/playlists/mock")!,
                externalUrls: SpotifyExternalUrls(
                    spotify: URL(string: "https://open.spotify.com/playlist/mock")
                ),
                uri: "spotify:playlist:mock"
            ),
            timestamp: Int64(timestamp.timeIntervalSince1970 * 1000),
            progressMs: 1_500,
            isPlaying: isPlaying,
            currentlyPlayingType: currentlyPlayingType,
            actions: Actions(
                interruptingPlayback: false,
                pausing: false,
                resuming: false,
                seeking: false,
                skippingNext: false,
                skippingPrev: false,
                togglingRepeatContext: false,
                togglingShuffle: false,
                togglingRepeatTrack: false,
                transferringPlayback: false
            )
        )

        return payload.decode()
    }

    /// Builds a page of playlists using the supplied fixtures.
    public static func playlistsPage(
        playlists: [SimplifiedPlaylist] = [],
        limit: Int? = nil,
        offset: Int = 0,
        total: Int? = nil,
        href: URL = URL(string: "https://api.spotify.com/v1/me/playlists")!
    ) -> Page<SimplifiedPlaylist> {
        let resolvedLimit = limit ?? playlists.count
        let resolvedTotal = total ?? playlists.count
        let items = Array(playlists.dropFirst(offset).prefix(resolvedLimit))
        let nextOffset = offset + resolvedLimit
        let previousOffset = max(offset - resolvedLimit, 0)

        return Page(
            href: href,
            items: items,
            limit: resolvedLimit,
            next: nextOffset < resolvedTotal
                ? SpotifyTestFixtures.makePageURL(
                    base: href, limit: resolvedLimit, offset: nextOffset) : nil,
            offset: offset,
            previous: offset > 0
                ? SpotifyTestFixtures.makePageURL(
                    base: href, limit: resolvedLimit, offset: previousOffset) : nil,
            total: resolvedTotal
        )
    }

    /// Builds a page URL with limit and offset query parameters.
    ///
    /// This helper is useful for constructing paginated API URLs in tests.
    ///
    /// - Parameters:
    ///   - base: The base URL for the page
    ///   - limit: The maximum number of items per page
    ///   - offset: The offset into the collection
    /// - Returns: A URL with limit and offset query parameters, or nil if limit is invalid
    public static func makePageURL(base: URL, limit: Int, offset: Int) -> URL? {
        guard limit > 0 else { return nil }
        var components = URLComponents(url: base, resolvingAgainstBaseURL: false)
        var queryItems =
            components?.queryItems?.filter { $0.name != "limit" && $0.name != "offset" } ?? []
        queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        queryItems.append(URLQueryItem(name: "offset", value: String(offset)))
        components?.queryItems = queryItems
        return components?.url
    }
}

// MARK: - Helpers

private struct PlaybackStateFixturePayload: Encodable {
    let device: SpotifyDevice
    let repeatState: PlaybackState.RepeatState
    let shuffleState: Bool
    let context: PlaybackContext?
    let timestamp: Int64
    let progressMs: Int?
    let isPlaying: Bool
    let item: [String: String]? = nil
    let currentlyPlayingType: PlaybackState.CurrentlyPlayingType
    let actions: Actions

    func decode() -> PlaybackState {
        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            let data = try encoder.encode(self)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(PlaybackState.self, from: data)
        } catch {
            fatalError("Failed to build PlaybackState fixture: \(error)")
        }
    }
}
