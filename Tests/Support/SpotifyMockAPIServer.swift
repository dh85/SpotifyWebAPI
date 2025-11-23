import Foundation
import HTTPTypes
import Hummingbird
import Logging
import NIOCore
import ServiceLifecycle

@testable import SpotifyWebAPI

/// Light-weight HTTP server that mimics a subset of the Spotify Web API for integration tests.
///
/// The server exposes the following endpoints:
/// - `POST /api/token` – issues a mock OAuth token (client credentials style)
/// - `GET /v1/me` – returns the current user profile
/// - `GET /v1/me/playlists` – paginated playlist listing honoring `limit` and `offset`
///
/// Tests can start the server, point a `SpotifyClient` at it by overriding the
/// token endpoint and API base URL, and perform full end-to-end calls without touching the real network.
actor SpotifyMockAPIServer {
    enum Error: Swift.Error, Sendable {
        case failedToStart(String)
    }

    struct Configuration: Sendable {
        let port: Int
        let expectedAccessToken: String
        let profile: CurrentUserProfile
        let playlists: [SimplifiedPlaylist]
        let playlistTracks: [String: [String]]
        let tokenScope: String
        let tokenExpiresIn: Int

        init(
            port: Int = 0,
            expectedAccessToken: String = "integration-access-token",
            profile: CurrentUserProfile = SpotifyTestFixtures.currentUserProfile(),
            playlists: [SimplifiedPlaylist] = SpotifyMockAPIServer.defaultPlaylists(),
            playlistTracks: [String: [String]]? = nil,
            tokenScope: String = "user-read-email playlist-read-private",
            tokenExpiresIn: Int = 3600
        ) {
            self.port = port
            self.expectedAccessToken = expectedAccessToken
            self.profile = profile
            self.playlists = playlists
            if let playlistTracks {
                self.playlistTracks = playlistTracks
            } else {
                self.playlistTracks = SpotifyMockAPIServer.defaultPlaylistTracks(for: playlists)
            }
            self.tokenScope = tokenScope
            self.tokenExpiresIn = tokenExpiresIn
        }
    }

    struct RunningServer: Sendable {
        let baseURL: URL
        let apiBaseURL: URL
        let tokenEndpoint: URL
    }

    private enum ServerState {
        case idle
        case running(RunningServer, ServiceGroup, Task<Void, Swift.Error>)
    }

    private enum StartupSignal: Sendable {
        case listening(Int)
        case failed(String)
    }

    private let configuration: Configuration
    private let logger = Logger(label: "SpotifyMockAPIServer")
    private var state: ServerState = .idle
    private var playlistStates: [String: PlaylistState]

    init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
        self.playlistStates = SpotifyMockAPIServer.bootstrapPlaylistStates(
            playlists: configuration.playlists,
            tracksByPlaylist: configuration.playlistTracks
        )
    }

    /// Start the server if needed and return connection information.
    func start() async throws -> RunningServer {
        if case .running(let info, _, _) = state {
            return info
        }

        let router = buildRouter()
        let (startupStream, startupContinuation) = makeStartupStream()

        let application = Application(
            router: router,
            configuration: .init(
                address: .hostname("127.0.0.1", port: configuration.port),
                serverName: "SpotifyMockAPIServer"
            ),
            onServerRunning: { channel in
                guard let port = channel.localAddress?.port else {
                    startupContinuation.yield(.failed("Channel missing port"))
                    startupContinuation.finish()
                    return
                }
                startupContinuation.yield(.listening(port))
                startupContinuation.finish()
            }
        )

        let serviceGroup = ServiceGroup(
            configuration: .init(
                services: [application],
                logger: logger
            )
        )

        let runTask = Task {
            do {
                try await serviceGroup.run()
            } catch is CancellationError {
                logger.debug("Server task cancelled")
                throw CancellationError()
            } catch {
                let message = "Server crashed: \(error)"
                logger.error("\(message)")
                startupContinuation.yield(.failed(message))
                startupContinuation.finish()
                throw error
            }
        }

        guard let signal = await startupStream.first(where: { _ in true }) else {
            await serviceGroup.triggerGracefulShutdown()
            runTask.cancel()
            throw Error.failedToStart("Server failed to provide startup signal")
        }

        switch signal {
        case .failed(let description):
            await serviceGroup.triggerGracefulShutdown()
            runTask.cancel()
            throw Error.failedToStart(description)
        case .listening(let port):
            let baseURL = URL(string: "http://127.0.0.1:\(port)")!
            let running = RunningServer(
                baseURL: baseURL,
                apiBaseURL: baseURL.appendingPathComponent("v1"),
                tokenEndpoint: baseURL.appendingPathComponent("api/token")
            )

            state = .running(running, serviceGroup, runTask)
            return running
        }
    }

    /// Stop the server if it is currently running.
    func stop() async {
        guard case .running(_, let group, let task) = state else {
            return
        }
        await group.triggerGracefulShutdown()
        _ = try? await task.value
        state = .idle
    }

    /// Run a block while the server is online, ensuring shutdown even on failure.
    @discardableResult
    func withRunningServer<T>(
        _ operation: (RunningServer) async throws -> T
    ) async throws -> T {
        let info = try await start()
        do {
            let result = try await operation(info)
            await stop()
            return result
        } catch {
            await stop()
            throw error
        }
    }

    // MARK: - Routing

    private func buildRouter() -> Router<BasicRequestContext> {
        let router = Router()

        router.get("health") { _, _ -> Response in
            Response(status: .ok)
        }

        router.post("api/token") { request, _ in
            try await self.handleTokenRequest(request)
        }

        let v1 = router.group("v1")
        v1.get("me") { request, _ in
            try await self.handleProfileRequest(request)
        }
        v1.get("me/playlists") { request, _ in
            try await self.handlePlaylistsRequest(request)
        }

        let playlists = v1.group("playlists")
        playlists.get(
            ":playlistID/tracks",
            use: { request, _ in
                try await self.handlePlaylistItemsRequest(request)
            })
        playlists.post(
            ":playlistID/tracks",
            use: { request, _ in
                var mutableRequest = request
                return try await self.handleAddPlaylistItems(&mutableRequest)
            })
        playlists.delete(
            ":playlistID/tracks",
            use: { request, _ in
                var mutableRequest = request
                return try await self.handleRemovePlaylistItems(&mutableRequest)
            })

        return router
    }

    private func handleTokenRequest(_ request: Request) async throws -> Response {
        let payload = TokenResponse(
            accessToken: configuration.expectedAccessToken,
            tokenType: "Bearer",
            expiresIn: configuration.tokenExpiresIn,
            refreshToken: nil,
            scope: configuration.tokenScope
        )
        return try jsonResponse(payload)
    }

    private func handleProfileRequest(_ request: Request) async throws -> Response {
        try validateAuthorizationHeader(on: request)
        return try jsonResponse(configuration.profile)
    }

    private func handlePlaylistsRequest(_ request: Request) async throws -> Response {
        try validateAuthorizationHeader(on: request)
        let limit = request.uri.queryParameters["limit"].flatMap { Int($0) } ?? 20
        let offset = request.uri.queryParameters["offset"].flatMap { Int($0) } ?? 0
        let href = try apiURLAppendingPath("me/playlists")
        let page = SpotifyTestFixtures.playlistsPage(
            playlists: configuration.playlists,
            limit: limit,
            offset: offset,
            total: configuration.playlists.count,
            href: href
        )
        return try jsonResponse(page)
    }

    private func handlePlaylistItemsRequest(_ request: Request) async throws -> Response {
        try validateAuthorizationHeader(on: request)
        let playlistID = try extractPlaylistID(from: request)
        let limit = request.uri.queryParameters["limit"].flatMap { Int($0) } ?? 20
        let offset = request.uri.queryParameters["offset"].flatMap { Int($0) } ?? 0
        guard let state = playlistStates[playlistID] else {
            throw HTTPError(.notFound, message: "Unknown playlist \(playlistID)")
        }
        let href = try apiURLAppendingPath("playlists/\(playlistID)/tracks")
        let slice = Array(state.trackURIs.dropFirst(offset).prefix(limit))
        let items = makePlaylistTrackItems(slice, startingAt: offset)
        let nextOffset = offset + slice.count
        let previousOffset = max(offset - limit, 0)
        let page = Page(
            href: href,
            items: items,
            limit: limit,
            next: nextOffset < state.trackURIs.count
                ? makePagingURL(base: href, limit: limit, offset: nextOffset) : nil,
            offset: offset,
            previous: offset > 0
                ? makePagingURL(base: href, limit: limit, offset: previousOffset) : nil,
            total: state.trackURIs.count
        )
        return try jsonResponse(page)
    }

    private func handleAddPlaylistItems(_ request: inout Request) async throws -> Response {
        try validateAuthorizationHeader(on: request)
        let playlistID = try extractPlaylistID(from: request)
        let payload: AddPlaylistItemsPayload = try await decodeJSONBody(&request)
        guard !payload.uris.isEmpty else {
            throw HTTPError(.badRequest, message: "Payload missing URIs")
        }
        let snapshot = try withPlaylistState(for: playlistID) { state in
            let insertIndex =
                payload.position.map { max(0, min($0, state.trackURIs.count)) }
                ?? state.trackURIs.count
            state.trackURIs.insert(contentsOf: payload.uris, at: insertIndex)
            return state.nextSnapshot()
        }
        return try jsonResponse(SnapshotResponse(snapshotId: snapshot), status: .created)
    }

    private func handleRemovePlaylistItems(_ request: inout Request) async throws -> Response {
        try validateAuthorizationHeader(on: request)
        let playlistID = try extractPlaylistID(from: request)
        let payload: RemovePlaylistItemsPayload = try await decodeJSONBody(&request)
        guard payload.tracks != nil || payload.positions != nil else {
            throw HTTPError(.badRequest, message: "Payload must include tracks or positions")
        }
        let snapshot = try withPlaylistState(for: playlistID) { state in
            if let positions = payload.positions {
                try Self.removePositions(positions, from: &state.trackURIs)
            }
            if let descriptors = payload.tracks {
                try Self.removeTrackDescriptors(descriptors, from: &state.trackURIs)
            }
            return state.nextSnapshot()
        }
        return try jsonResponse(SnapshotResponse(snapshotId: snapshot))
    }

    private func validateAuthorizationHeader(on request: Request) throws {
        let header = request.headers[.authorization] ?? ""
        let expected = "Bearer \(configuration.expectedAccessToken)"
        guard header == expected else {
            throw HTTPError(.unauthorized, message: "Missing or invalid bearer token")
        }
    }

    private struct TokenResponse: Encodable {
        let accessToken: String
        let tokenType: String
        let expiresIn: Int
        let refreshToken: String?
        let scope: String
    }

    private struct SnapshotResponse: Encodable {
        let snapshotId: String
    }

    private func jsonResponse<T: Encodable>(
        _ value: T,
        status: HTTPResponse.Status = .ok
    ) throws -> Response {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .millisecondsSince1970
        let data = try encoder.encode(value)
        var buffer = ByteBufferAllocator().buffer(capacity: data.count)
        buffer.writeBytes(data)
        return Response(
            status: status,
            headers: [.contentType: "application/json"],
            body: .init(byteBuffer: buffer)
        )
    }

    private static func defaultPlaylists(count: Int = 10) -> [SimplifiedPlaylist] {
        (0..<count).map { index in
            SpotifyTestFixtures.simplifiedPlaylist(
                id: "playlist-\(index)",
                name: "Playlist #\(index + 1)",
                ownerID: "owner-\(index)"
            )
        }
    }

    private static func defaultPlaylistTracks(for playlists: [SimplifiedPlaylist]) -> [String:
        [String]]
    {
        playlists.reduce(into: [:]) { result, playlist in
            result[playlist.id] = (0..<3).map { index in
                "spotify:track:\(playlist.id)-track-\(index)"
            }
        }
    }

    private static func bootstrapPlaylistStates(
        playlists: [SimplifiedPlaylist],
        tracksByPlaylist: [String: [String]]
    ) -> [String: PlaylistState] {
        playlists.reduce(into: [:]) { result, playlist in
            let seeds = tracksByPlaylist[playlist.id] ?? []
            result[playlist.id] = PlaylistState(trackURIs: seeds)
        }
    }

    private func makePlaylistTrackItems(_ uris: [String], startingAt offset: Int)
        -> [PlaylistTrackItem]
    {
        uris.enumerated().map { index, uri in
            let trackID = trackIdentifier(from: uri)
            let track = Track(
                album: nil,
                artists: nil,
                availableMarkets: nil,
                discNumber: nil,
                durationMs: nil,
                explicit: false,
                externalIds: nil,
                externalUrls: nil,
                href: URL(string: "https://api.spotify.com/v1/tracks/\(trackID)"),
                id: trackID,
                isPlayable: true,
                linkedFrom: nil,
                restrictions: nil,
                name: "Track \(trackID)",
                popularity: nil,
                trackNumber: offset + index + 1,
                type: .track,
                uri: uri,
                isLocal: false
            )
            return PlaylistTrackItem(
                addedAt: nil,
                addedBy: nil,
                isLocal: false,
                track: .track(track)
            )
        }
    }

    private func extractPlaylistID(from request: Request) throws -> String {
        let components = request.uri.path.split(separator: "/")
        guard let index = components.firstIndex(of: "playlists"),
            components.indices.contains(index + 1)
        else {
            throw HTTPError(.badRequest, message: "Missing playlist identifier in path")
        }
        return String(components[index + 1])
    }

    private func apiURLAppendingPath(_ path: String) throws -> URL {
        guard case .running(let info, _, _) = state else {
            throw HTTPError(.internalServerError, message: "Server not ready")
        }
        return info.apiBaseURL.appendingPathComponent(path)
    }

    private func makePagingURL(base: URL, limit: Int, offset: Int) -> URL? {
        guard limit > 0 else { return nil }
        var components = URLComponents(url: base, resolvingAgainstBaseURL: false)
        var queryItems =
            components?.queryItems?.filter { $0.name != "limit" && $0.name != "offset" } ?? []
        queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        queryItems.append(URLQueryItem(name: "offset", value: String(offset)))
        components?.queryItems = queryItems
        return components?.url
    }

    private func decodeJSONBody<T: Decodable>(_ request: inout Request) async throws -> T {
        let bodyBuffer = try await request.collectBody(upTo: Self.maxBodyBytes)
        let data = Data(bodyBuffer.readableBytesView)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    }

    private func withPlaylistState<T>(
        for playlistID: String,
        _ mutate: (inout PlaylistState) throws -> T
    ) throws -> T {
        guard var state = playlistStates[playlistID] else {
            throw HTTPError(.notFound, message: "Unknown playlist \(playlistID)")
        }
        let result = try mutate(&state)
        playlistStates[playlistID] = state
        return result
    }

    private static func removePositions(_ positions: [Int], from tracks: inout [String]) throws {
        guard !positions.isEmpty else { return }
        for index in positions.sorted(by: >) {
            guard tracks.indices.contains(index) else {
                throw HTTPError(.badRequest, message: "Invalid playlist position \(index)")
            }
            tracks.remove(at: index)
        }
    }

    private static func removeTrackDescriptors(
        _ descriptors: [RemovePlaylistItemsPayload.TrackDescriptor],
        from tracks: inout [String]
    ) throws {
        guard !descriptors.isEmpty else { return }
        for descriptor in descriptors {
            if let positions = descriptor.positions, !positions.isEmpty {
                try removePositions(positions, from: &tracks)
            } else if let index = tracks.firstIndex(of: descriptor.uri) {
                tracks.remove(at: index)
            }
        }
    }

    private func trackIdentifier(from uri: String) -> String {
        uri.split(separator: ":").last.map(String.init) ?? uri
    }

    private struct PlaylistState {
        var trackURIs: [String]
        private var snapshotCounter: Int

        init(trackURIs: [String], snapshotCounter: Int = 0) {
            self.trackURIs = trackURIs
            self.snapshotCounter = snapshotCounter
        }

        mutating func nextSnapshot() -> String {
            snapshotCounter += 1
            return "snapshot-\(snapshotCounter)"
        }
    }

    private struct AddPlaylistItemsPayload: Decodable {
        let uris: [String]
        let position: Int?
    }

    private struct RemovePlaylistItemsPayload: Decodable {
        struct TrackDescriptor: Decodable {
            let uri: String
            let positions: [Int]?
        }

        let tracks: [TrackDescriptor]?
        let positions: [Int]?
    }

    private static let maxBodyBytes = 1_048_576

    private func makeStartupStream() -> (
        AsyncStream<StartupSignal>,
        AsyncStream<StartupSignal>.Continuation
    ) {
        var continuation: AsyncStream<StartupSignal>.Continuation!
        let stream = AsyncStream<StartupSignal> { cont in
            continuation = cont
        }
        return (stream, continuation)
    }
}
