import Foundation
import Hummingbird
import SpotifyKit

/// Controller that handles all Spotify-related endpoints
struct SpotifyController {
    // Spotify client instance
    let client: UserSpotifyClient

    // Return Spotify endpoints
    var endpoints: RouteCollection<BasicRequestContext> {
        RouteCollection(context: BasicRequestContext.self)
            .get("/", use: root)
            .get("/health", use: health)
            .get("/me", use: getCurrentUserProfile)
            .get("/playlists", use: getUserPlaylists)
            .get("/top/artists", use: getTopArtists)
            .get("/top/tracks", use: getTopTracks)
            .get("/recent", use: getRecentlyPlayed)
            .get("/search", use: search)
            .get("/album/:id", use: getAlbum)
    }

    // MARK: - Route Handlers

    /// Root endpoint
    @Sendable func root(request: Request, context: some RequestContext) async throws -> Response {
        let message = """
            {
                "message": "Spotify Web API Example Server",
                "endpoints": {
                    "profile": "/me",
                    "playlists": "/playlists",
                    "top_artists": "/top/artists",
                    "top_tracks": "/top/tracks",
                    "recently_played": "/recent",
                    "search": "/search?q=query",
                    "album": "/album/:id"
                }
            }
            """
        var response = Response(status: .ok)
        response.headers[.contentType] = "application/json"
        response.body = .init(byteBuffer: ByteBuffer(string: message))
        return response
    }

    /// Health check endpoint
    @Sendable func health(request: Request, context: some RequestContext) async throws -> Response {
        var response = Response(status: .ok)
        response.headers[.contentType] = "application/json"
        response.body = .init(
            byteBuffer: ByteBuffer(
                string: """
                    {"status": "ok"}
                    """))
        return response
    }

    /// Get current user profile
    @Sendable func getCurrentUserProfile(request: Request, context: some RequestContext)
        async throws -> Response
    {
        let profile = try await client.users.me()
        let response = UserProfileResponse(from: profile)
        return try makeJSONResponse(response)
    }

    /// Get user's playlists
    @Sendable func getUserPlaylists(request: Request, context: some RequestContext) async throws
        -> Response
    {
        let page = try await client.playlists.myPlaylists(limit: 20)
        let response = PlaylistsResponse(from: page)
        return try makeJSONResponse(response)
    }

    /// Get top artists
    @Sendable func getTopArtists(request: Request, context: some RequestContext) async throws
        -> Response
    {
        let page = try await client.users.topArtists(limit: 20)
        let response = TopArtistsResponse(from: page)
        return try makeJSONResponse(response)
    }

    /// Get top tracks
    @Sendable func getTopTracks(request: Request, context: some RequestContext) async throws
        -> Response
    {
        let page = try await client.users.topTracks(limit: 20)
        let response = TopTracksResponse(from: page)
        return try makeJSONResponse(response)
    }

    /// Get recently played tracks
    @Sendable func getRecentlyPlayed(request: Request, context: some RequestContext) async throws
        -> Response
    {
        let page = try await client.player.recentlyPlayed(limit: 20)
        let response = RecentlyPlayedResponse(from: page)
        return try makeJSONResponse(response)
    }

    /// Search for tracks, artists, and albums
    @Sendable func search(request: Request, context: some RequestContext) async throws -> Response {
        guard let query = request.uri.queryParameters.get("q") else {
            throw HTTPError(.badRequest, message: "Missing 'q' query parameter")
        }

        let results = try await client.search.execute(
            query: query,
            types: [.track, .artist, .album],
            limit: 10
        )

        let response = SearchResponse(from: results)
        return try makeJSONResponse(response)
    }

    /// Get album by ID
    @Sendable func getAlbum(request: Request, context: some RequestContext) async throws -> Response
    {
        let id = try context.parameters.require("id", as: String.self)
        let album = try await client.albums.get(id)
        let response = AlbumResponse(from: album)
        return try makeJSONResponse(response)
    }

    // MARK: - Helper Methods

    /// Create a JSON response from a Codable value
    private func makeJSONResponse<T: Encodable>(_ value: T) throws -> Response {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(value)
        var response = Response(status: .ok)
        response.headers[.contentType] = "application/json"
        response.body = .init(byteBuffer: ByteBuffer(bytes: data))
        return response
    }
}
