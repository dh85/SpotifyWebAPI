import Crypto
import Foundation
import HTTPTypes
import Hummingbird
import Logging
import NIOCore
import ServiceLifecycle

@testable import SpotifyKit

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
        let errorInjection: ErrorInjectionConfig?
        let rateLimitConfig: RateLimitConfig?
        let oauthConfig: OAuthConfig

        init(
            port: Int = 0,
            expectedAccessToken: String = "integration-access-token",
            profile: CurrentUserProfile = SpotifyTestFixtures.currentUserProfile(),
            playlists: [SimplifiedPlaylist] = SpotifyMockAPIServer.defaultPlaylists(),
            playlistTracks: [String: [String]]? = nil,
            tokenScope: String = "user-read-email playlist-read-private",
            tokenExpiresIn: Int = 3600,
            errorInjection: ErrorInjectionConfig? = nil,
            rateLimitConfig: RateLimitConfig? = nil,
            oauthConfig: OAuthConfig = .default
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
            self.errorInjection = errorInjection
            self.rateLimitConfig = rateLimitConfig
            self.oauthConfig = oauthConfig
        }
    }

    /// Configuration for injecting specific HTTP errors into responses
    struct ErrorInjectionConfig: Sendable {
        enum ErrorBehavior: Sendable {
            case once
            case always
            case nthRequest(Int)
            case everyNthRequest(Int)
        }

        let statusCode: Int
        let errorMessage: String?
        let affectedEndpoints: Set<String>?  // nil means all endpoints
        let behavior: ErrorBehavior

        init(
            statusCode: Int,
            errorMessage: String? = nil,
            affectedEndpoints: Set<String>? = nil,
            behavior: ErrorBehavior = .once
        ) {
            self.statusCode = statusCode
            self.errorMessage = errorMessage
            self.affectedEndpoints = affectedEndpoints
            self.behavior = behavior
        }
    }

    /// Configuration for rate limiting simulation
    struct RateLimitConfig: Sendable {
        let maxRequestsPerWindow: Int
        let windowDuration: TimeInterval
        let retryAfterSeconds: Int

        init(
            maxRequestsPerWindow: Int = 5,
            windowDuration: TimeInterval = 30,
            retryAfterSeconds: Int = 1
        ) {
            self.maxRequestsPerWindow = maxRequestsPerWindow
            self.windowDuration = windowDuration
            self.retryAfterSeconds = retryAfterSeconds
        }
    }

    /// Configuration for OAuth flow simulation
    struct OAuthConfig: Sendable {
        let clientID: String
        let clientSecret: String
        let enablePKCE: Bool
        let enableAuthorizationCode: Bool
        let refreshTokenExpiry: TimeInterval

        static let `default` = OAuthConfig(
            clientID: "test-client-id",
            clientSecret: "test-client-secret",
            enablePKCE: true,
            enableAuthorizationCode: true,
            refreshTokenExpiry: 3600 * 24 * 30  // 30 days
        )

        init(
            clientID: String,
            clientSecret: String,
            enablePKCE: Bool = true,
            enableAuthorizationCode: Bool = true,
            refreshTokenExpiry: TimeInterval = 3600 * 24 * 30
        ) {
            self.clientID = clientID
            self.clientSecret = clientSecret
            self.enablePKCE = enablePKCE
            self.enableAuthorizationCode = enableAuthorizationCode
            self.refreshTokenExpiry = refreshTokenExpiry
        }
    }

    struct RunningServer: Sendable {
        let baseURL: URL
        let apiBaseURL: URL
        let tokenEndpoint: URL
        let authorizeEndpoint: URL
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
    private var rateLimiter: RateLimiter
    private var errorInjector: ErrorInjector
    private var oauthState: OAuthState = .init()

    init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
        self.playlistStates = SpotifyMockAPIServer.bootstrapPlaylistStates(
            playlists: configuration.playlists,
            tracksByPlaylist: configuration.playlistTracks
        )
        let rateLimitTracingEnabled =
            ProcessInfo.processInfo.environment["SPOTIFY_MOCK_RATE_LIMIT_TRACE"] == "1"
        self.rateLimiter = RateLimiter(
            config: configuration.rateLimitConfig,
            traceEnabled: rateLimitTracingEnabled
        )
        let errorTraceEnabled =
            ProcessInfo.processInfo.environment["SPOTIFY_MOCK_ERROR_TRACE"] == "1"
        self.errorInjector = ErrorInjector(
            config: configuration.errorInjection,
            traceEnabled: errorTraceEnabled
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
                tokenEndpoint: baseURL.appendingPathComponent("api/token"),
                authorizeEndpoint: baseURL.appendingPathComponent("authorize")
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
    func withRunningServer<T: Sendable>(
        _ operation: @Sendable (RunningServer) async throws -> T
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

        // OAuth endpoints
        router.get("authorize") { request, _ in
            try await self.handleAuthorizeRequest(request)
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

    // MARK: - OAuth Handlers

    private func handleAuthorizeRequest(_ request: Request) async throws -> Response {
        // Extract OAuth parameters
        let params = request.uri.queryParameters

        guard let clientID = params["client_id"] else {
            return try errorResponse(status: .badRequest, message: "Missing client_id")
        }

        guard clientID == configuration.oauthConfig.clientID else {
            return try errorResponse(status: .unauthorized, message: "Invalid client_id")
        }

        guard let redirectURIValue = params["redirect_uri"],
            let redirectURL = URL(string: String(redirectURIValue))
        else {
            return try errorResponse(status: .badRequest, message: "Invalid redirect_uri")
        }

        guard let stateValue = params["state"], !stateValue.isEmpty else {
            return try errorResponse(status: .badRequest, message: "Missing state parameter")
        }

        let state = String(stateValue)
        let redirectURI = String(redirectURIValue)

        let responseType = params["response_type"] ?? "code"
        guard responseType == "code" else {
            return try errorResponse(status: .badRequest, message: "Unsupported response_type")
        }

        // Check for PKCE parameters
        if let codeChallengeValue = params["code_challenge"],
            let codeChallengeMethodValue = params["code_challenge_method"]
        {
            guard configuration.oauthConfig.enablePKCE else {
                return try errorResponse(status: .badRequest, message: "PKCE not supported")
            }

            let codeChallenge = String(codeChallengeValue)
            let codeChallengeMethod = String(codeChallengeMethodValue)
            let scope = params["scope"].map(String.init) ?? configuration.tokenScope

            // Store PKCE challenge for later verification
            let authCode = generateAuthorizationCode()
            oauthState.pkceData[authCode] = PKCEData(
                codeChallenge: codeChallenge,
                codeChallengeMethod: codeChallengeMethod,
                redirectURI: redirectURI,
                scope: scope,
                state: state,
                expiresAt: Date().addingTimeInterval(600)
            )

            // Redirect with authorization code
            var components = URLComponents(url: redirectURL, resolvingAgainstBaseURL: false)!
            components.queryItems = [
                URLQueryItem(name: "code", value: authCode),
                URLQueryItem(name: "state", value: state),
            ]

            return Response(
                status: .found,
                headers: [.location: components.url!.absoluteString]
            )
        }

        // Standard Authorization Code flow
        guard configuration.oauthConfig.enableAuthorizationCode else {
            return try errorResponse(
                status: .badRequest, message: "Authorization Code flow not enabled")
        }

        let scope = params["scope"].map(String.init) ?? configuration.tokenScope
        let authCode = generateAuthorizationCode()
        oauthState.authCodes[authCode] = AuthCodeData(
            redirectURI: redirectURI,
            scope: scope,
            state: state,
            expiresAt: Date().addingTimeInterval(600)  // 10 minutes
        )

        var components = URLComponents(url: redirectURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "code", value: authCode),
            URLQueryItem(name: "state", value: state),
        ]

        return Response(
            status: .found,
            headers: [.location: components.url!.absoluteString]
        )
    }

    private func handleTokenRequest(_ request: Request) async throws -> Response {
        var mutableRequest = request
        let body = try await mutableRequest.collectBody(upTo: Self.maxBodyBytes)
        let bodyString = String(buffer: body)
        let params = parseFormURLEncoded(bodyString)

        let grantType = params["grant_type"] ?? ""

        switch grantType {
        case "authorization_code":
            return try await handleAuthorizationCodeGrant(params: params)
        case "refresh_token":
            return try await handleRefreshTokenGrant(params: params)
        case "client_credentials":
            return try await handleClientCredentialsGrant(params: params)
        default:
            return try errorResponse(
                status: .badRequest, message: "Unsupported grant_type: \(grantType)")
        }
    }

    private func handleAuthorizationCodeGrant(params: [String: String]) async throws -> Response {
        guard let code = params["code"] else {
            return try errorResponse(status: .badRequest, message: "Missing code")
        }

        guard let redirectURI = params["redirect_uri"] else {
            return try errorResponse(status: .badRequest, message: "Missing redirect_uri")
        }

        // Check if this is a PKCE flow
        if let pkceData = oauthState.pkceData[code] {
            guard let codeVerifier = params["code_verifier"] else {
                return try errorResponse(
                    status: .badRequest, message: "Missing code_verifier for PKCE flow")
            }

            // Verify PKCE challenge
            let isValid = verifyPKCEChallenge(
                verifier: codeVerifier,
                challenge: pkceData.codeChallenge,
                method: pkceData.codeChallengeMethod
            )

            guard isValid else {
                return try errorResponse(status: .badRequest, message: "Invalid code_verifier")
            }

            guard redirectURI == pkceData.redirectURI else {
                return try errorResponse(status: .badRequest, message: "redirect_uri mismatch")
            }

            // Generate tokens
            let accessToken = generateAccessToken()
            let refreshToken = generateRefreshToken()

            oauthState.refreshTokens[refreshToken] = RefreshTokenData(
                accessToken: accessToken,
                scope: pkceData.scope,
                expiresAt: Date().addingTimeInterval(configuration.oauthConfig.refreshTokenExpiry)
            )

            oauthState.pkceData.removeValue(forKey: code)

            let payload = TokenResponse(
                accessToken: accessToken,
                tokenType: "Bearer",
                expiresIn: configuration.tokenExpiresIn,
                refreshToken: refreshToken,
                scope: pkceData.scope
            )
            return try jsonResponse(payload)
        }

        // Standard Authorization Code flow
        guard let authData = oauthState.authCodes[code] else {
            return try errorResponse(
                status: .badRequest, message: "Invalid or expired authorization code")
        }

        guard Date() < authData.expiresAt else {
            oauthState.authCodes.removeValue(forKey: code)
            return try errorResponse(status: .badRequest, message: "Authorization code expired")
        }

        guard redirectURI == authData.redirectURI else {
            return try errorResponse(status: .badRequest, message: "redirect_uri mismatch")
        }

        // Verify client credentials for non-PKCE flow
        let clientID = params["client_id"] ?? ""
        let clientSecret = params["client_secret"] ?? ""

        guard
            clientID == configuration.oauthConfig.clientID
                && clientSecret == configuration.oauthConfig.clientSecret
        else {
            return try errorResponse(status: .unauthorized, message: "Invalid client credentials")
        }

        let accessToken = generateAccessToken()
        let refreshToken = generateRefreshToken()

        oauthState.refreshTokens[refreshToken] = RefreshTokenData(
            accessToken: accessToken,
            scope: authData.scope,
            expiresAt: Date().addingTimeInterval(configuration.oauthConfig.refreshTokenExpiry)
        )

        oauthState.authCodes.removeValue(forKey: code)

        let payload = TokenResponse(
            accessToken: accessToken,
            tokenType: "Bearer",
            expiresIn: configuration.tokenExpiresIn,
            refreshToken: refreshToken,
            scope: authData.scope
        )
        return try jsonResponse(payload)
    }

    private func handleRefreshTokenGrant(params: [String: String]) async throws -> Response {
        guard let refreshToken = params["refresh_token"] else {
            return try errorResponse(status: .badRequest, message: "Missing refresh_token")
        }

        guard let tokenData = oauthState.refreshTokens[refreshToken] else {
            return try errorResponse(status: .badRequest, message: "Invalid refresh_token")
        }

        guard Date() < tokenData.expiresAt else {
            oauthState.refreshTokens.removeValue(forKey: refreshToken)
            return try errorResponse(status: .badRequest, message: "Refresh token expired")
        }

        // Generate new access token
        let newAccessToken = generateAccessToken()

        // Update the refresh token data with new access token
        oauthState.refreshTokens[refreshToken] = RefreshTokenData(
            accessToken: newAccessToken,
            scope: tokenData.scope,
            expiresAt: tokenData.expiresAt
        )

        let payload = TokenResponse(
            accessToken: newAccessToken,
            tokenType: "Bearer",
            expiresIn: configuration.tokenExpiresIn,
            refreshToken: refreshToken,
            scope: tokenData.scope
        )
        return try jsonResponse(payload)
    }

    private func handleClientCredentialsGrant(params: [String: String]) async throws -> Response {
        // Simple client credentials flow (existing behavior)
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

        // Check and increment rate limit
        let endpoint = "/v1/me"
        if !checkAndIncrementRateLimit(for: endpoint) {
            return try rateLimitResponse()
        }

        // Check error injection
        if shouldInjectError(for: endpoint) {
            guard let config = configuration.errorInjection else {
                return try jsonResponse(configuration.profile)
            }
            return try errorResponse(
                status: HTTPResponse.Status(code: config.statusCode),
                message: config.errorMessage ?? "Error"
            )
        }

        return try jsonResponse(configuration.profile)
    }

    private func handlePlaylistsRequest(_ request: Request) async throws -> Response {
        try validateAuthorizationHeader(on: request)

        // Check and increment rate limit
        let endpoint = "/v1/me/playlists"
        if !checkAndIncrementRateLimit(for: endpoint) {
            return try rateLimitResponse()
        }

        // Check error injection
        if shouldInjectError(for: endpoint) {
            guard let config = configuration.errorInjection else {
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
            return try errorResponse(
                status: HTTPResponse.Status(code: config.statusCode),
                message: config.errorMessage ?? "Error"
            )
        }

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
        let endpoint = "/v1/playlists/\(playlistID)/tracks"

        // Check and increment rate limit
        if !checkAndIncrementRateLimit(for: endpoint) {
            return try rateLimitResponse()
        }

        // Check error injection
        if shouldInjectError(for: endpoint) {
            guard let config = configuration.errorInjection else {
                return try buildPlaylistItemsResponse(playlistID: playlistID, request: request)
            }
            return try errorResponse(
                status: HTTPResponse.Status(code: config.statusCode),
                message: config.errorMessage ?? "Error"
            )
        }

        return try buildPlaylistItemsResponse(playlistID: playlistID, request: request)
    }

    private func buildPlaylistItemsResponse(playlistID: String, request: Request) throws -> Response
    {
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
        let endpoint = "/v1/playlists/\(playlistID)/tracks (POST)"

        // Check and increment rate limit
        if !checkAndIncrementRateLimit(for: endpoint) {
            return try rateLimitResponse()
        }

        // Check error injection
        if shouldInjectError(for: endpoint) {
            guard let config = configuration.errorInjection else {
                return try await performAddPlaylistItems(request: &request, playlistID: playlistID)
            }
            return try errorResponse(
                status: HTTPResponse.Status(code: config.statusCode),
                message: config.errorMessage ?? "Error"
            )
        }

        return try await performAddPlaylistItems(request: &request, playlistID: playlistID)
    }

    private func performAddPlaylistItems(request: inout Request, playlistID: String) async throws
        -> Response
    {
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

    // MARK: - OAuth & Security Helper Methods

    private func generateAuthorizationCode() -> String {
        return "auth_code_" + UUID().uuidString.replacingOccurrences(of: "-", with: "")
    }

    private func generateAccessToken() -> String {
        return "access_token_" + UUID().uuidString.replacingOccurrences(of: "-", with: "")
    }

    private func generateRefreshToken() -> String {
        return "refresh_token_" + UUID().uuidString.replacingOccurrences(of: "-", with: "")
    }

    private func verifyPKCEChallenge(verifier: String, challenge: String, method: String) -> Bool {
        switch method {
        case "plain":
            return verifier == challenge
        case "S256":
            guard let data = verifier.data(using: .utf8) else { return false }
            let hash = SHA256.hash(data: data)
            let base64 = Data(hash).base64EncodedString()
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "")
            return base64 == challenge
        default:
            return false
        }
    }

    // MARK: - Rate Limiting Helper Methods

    private func checkAndIncrementRateLimit(for endpoint: String) -> Bool {
        rateLimiter.allow(endpoint: endpoint, logger: logger)
    }

    private func rateLimitResponse() throws -> Response {
        guard let config = configuration.rateLimitConfig else {
            return try errorResponse(status: .tooManyRequests, message: "Rate limit exceeded")
        }

        var headers: HTTPFields = [.contentType: "application/json"]
        headers[.retryAfter] = String(config.retryAfterSeconds)

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let errorBody = ["error": "rate_limit_exceeded", "message": "Too many requests"]
        let data = try encoder.encode(errorBody)
        var buffer = ByteBufferAllocator().buffer(capacity: data.count)
        buffer.writeBytes(data)

        return Response(
            status: .tooManyRequests,
            headers: headers,
            body: .init(byteBuffer: buffer)
        )
    }

    // MARK: - Error Injection Helper Methods

    private func shouldInjectError(for endpoint: String) -> Bool {
        errorInjector.shouldInject(endpoint: endpoint, logger: logger)
    }

    private func errorResponse(status: HTTPResponse.Status, message: String) throws -> Response {
        let errorBody = ["error": status.reasonPhrase, "message": message]
        let encoder = JSONEncoder()
        let data = try encoder.encode(errorBody)
        var buffer = ByteBufferAllocator().buffer(capacity: data.count)
        buffer.writeBytes(data)

        return Response(
            status: status,
            headers: [.contentType: "application/json"],
            body: .init(byteBuffer: buffer)
        )
    }

    // MARK: - Request Parsing Helper Methods

    private func parseFormURLEncoded(_ body: String) -> [String: String] {
        var result: [String: String] = [:]
        let pairs = body.split(separator: "&")
        for pair in pairs {
            let components = pair.split(separator: "=", maxSplits: 1)
            if components.count == 2 {
                let key = String(components[0]).removingPercentEncoding ?? String(components[0])
                let value = String(components[1]).removingPercentEncoding ?? String(components[1])
                result[key] = value
            }
        }
        return result
    }

    private func parseQueryParameters(_ url: String) -> [String: String] {
        guard let queryStart = url.firstIndex(of: "?") else { return [:] }
        let queryString = String(url[url.index(after: queryStart)...])
        return parseFormURLEncoded(queryString)
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
                id: "playlist\(index)",
                name: "Playlist #\(index + 1)",
                ownerID: "owner\(index)"
            )
        }
    }

    private static func defaultPlaylistTracks(for playlists: [SimplifiedPlaylist]) -> [String:
        [String]]
    {
        playlists.reduce(into: [:]) { result, playlist in
            result[playlist.id] = (0..<3).map { index in
                "spotify:track:\(playlist.id)Track\(index)"
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

    // MARK: - OAuth State Management

    private struct OAuthState {
        var authCodes: [String: AuthCodeData] = [:]
        var pkceData: [String: PKCEData] = [:]
        var refreshTokens: [String: RefreshTokenData] = [:]
    }

    private struct AuthCodeData {
        let redirectURI: String
        let scope: String
        let state: String?
        let expiresAt: Date
    }

    private struct PKCEData {
        let codeChallenge: String
        let codeChallengeMethod: String
        let redirectURI: String
        let scope: String
        let state: String?
        let expiresAt: Date
    }

    private struct RefreshTokenData {
        let accessToken: String
        let scope: String
        let expiresAt: Date
    }

    private struct ErrorInjectionState {
        var injectedOnce: Bool = false
        var requestCounts: [String: Int] = [:]
    }

    private struct RateLimiter {
        let config: RateLimitConfig?
        private var requestCounter: [String: Int] = [:]
        private var windowStart: Date?
        private let traceEnabled: Bool

        init(config: RateLimitConfig?, traceEnabled: Bool) {
            self.config = config
            self.traceEnabled = traceEnabled
        }

        mutating func allow(endpoint: String, logger: Logger) -> Bool {
            guard let config else { return true }

            if endpoint.contains("/api/token") || endpoint.contains("/authorize") {
                return true
            }

            let now = Date()
            if let start = windowStart,
                now.timeIntervalSince(start) >= config.windowDuration
            {
                windowStart = now
                requestCounter.removeAll()
            } else if windowStart == nil {
                windowStart = now
            }

            let count = requestCounter[endpoint, default: 0]
            let allowed = count < config.maxRequestsPerWindow
            if traceEnabled {
                logger.info(
                    "Rate limit check",
                    metadata: [
                        "endpoint": "\(endpoint)",
                        "count": "\(count)",
                        "allowed": "\(allowed)",
                        "max": "\(config.maxRequestsPerWindow)",
                    ])
            }

            if allowed {
                requestCounter[endpoint] = count + 1
            }

            return allowed
        }
    }

    private struct ErrorInjector {
        let config: ErrorInjectionConfig?
        private var state = ErrorInjectionState()
        private let traceEnabled: Bool

        init(config: ErrorInjectionConfig?, traceEnabled: Bool) {
            self.config = config
            self.traceEnabled = traceEnabled
        }

        mutating func shouldInject(endpoint: String, logger: Logger) -> Bool {
            guard let config else { return false }

            if let affected = config.affectedEndpoints, !affected.isEmpty {
                let isAffected = affected.contains { pattern in endpoint.contains(pattern) }
                if !isAffected { return false }
            }

            switch config.behavior {
            case .always:
                return true
            case .once:
                guard !state.injectedOnce else { return false }
                state.injectedOnce = true
                log(message: "Injecting error (once)", endpoint: endpoint, logger: logger)
                return true
            case .nthRequest(let n):
                let currentCount = state.requestCounts[endpoint, default: 0] + 1
                state.requestCounts[endpoint] = currentCount
                log(
                    message: "Nth error check",
                    endpoint: endpoint,
                    logger: logger,
                    metadata: [
                        "count": "\(currentCount)",
                        "target": "\(n)",
                    ]
                )
                return currentCount == n
            case .everyNthRequest(let n):
                let currentCount = state.requestCounts[endpoint, default: 0] + 1
                state.requestCounts[endpoint] = currentCount
                let willInject = currentCount % n == 0
                log(
                    message: "EveryNth error check",
                    endpoint: endpoint,
                    logger: logger,
                    metadata: [
                        "count": "\(currentCount)",
                        "interval": "\(n)",
                        "willInject": "\(willInject)",
                    ]
                )
                return willInject
            }
        }

        private func log(
            message: String,
            endpoint: String,
            logger: Logger,
            metadata: [String: String] = [:]
        ) {
            guard traceEnabled else { return }
            var meta: Logger.Metadata = ["endpoint": "\(endpoint)"]
            metadata.forEach { key, value in
                meta[key] = "\(value)"
            }
            logger.info("\(message)", metadata: meta)
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
