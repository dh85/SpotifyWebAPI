import Foundation

/// Configuration for Spotify OAuth 2.0 authentication flows.
///
/// This struct holds the credentials and settings needed for different OAuth flows.
/// Use the static factory methods to create configurations for specific flows:
///
/// - ``pkce(clientID:redirectURI:scopes:showDialog:authorizationEndpoint:tokenEndpoint:)`` for mobile/public apps
/// - ``authorizationCode(clientID:clientSecret:redirectURI:scopes:showDialog:authorizationEndpoint:tokenEndpoint:)`` for server-side apps
/// - ``clientCredentials(clientID:clientSecret:scopes:tokenEndpoint:)`` for app-only access
///
/// ## Example
///
/// ```swift
/// let config = SpotifyAuthConfig.pkce(
///     clientID: "your-client-id",
///     redirectURI: URL(string: "myapp://callback")!,
///     scopes: [.userReadPrivate, .playlistModifyPublic]
/// )
/// ```
public struct SpotifyAuthConfig: Sendable {
    public let clientID: String
    public let clientSecret: String?
    public let redirectURI: URL
    public let scopes: Set<SpotifyScope>
    public let showDialog: Bool
    public let authorizationEndpoint: URL
    public let tokenEndpoint: URL

    public static let defaultAuthorizationEndpoint =
        URL(string: "https://accounts.spotify.com/authorize")!

    public static let defaultTokenEndpoint =
        URL(string: "https://accounts.spotify.com/api/token")!

    fileprivate init(
        clientID: String,
        clientSecret: String? = nil,
        redirectURI: URL,
        scopes: Set<SpotifyScope> = [],
        showDialog: Bool = false,
        authorizationEndpoint: URL = SpotifyAuthConfig
            .defaultAuthorizationEndpoint,
        tokenEndpoint: URL = SpotifyAuthConfig.defaultTokenEndpoint
    ) {
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.redirectURI = redirectURI
        self.scopes = scopes
        self.showDialog = showDialog
        self.authorizationEndpoint = authorizationEndpoint
        self.tokenEndpoint = tokenEndpoint
    }
}

extension SpotifyAuthConfig {

    /// Create a configuration for PKCE flow (public/mobile apps).
    ///
    /// PKCE (Proof Key for Code Exchange) is recommended for apps that cannot securely
    /// store a client secret, such as mobile apps and single-page applications.
    ///
    /// - Parameters:
    ///   - clientID: Your Spotify application's client ID.
    ///   - redirectURI: The redirect URI registered in your Spotify app settings.
    ///   - scopes: The authorization scopes your app needs (default: empty).
    ///   - showDialog: Whether to force the user to approve the app again (default: false).
    ///   - authorizationEndpoint: Custom authorization endpoint (default: Spotify's endpoint).
    ///   - tokenEndpoint: Custom token endpoint (default: Spotify's endpoint).
    /// - Returns: A configured SpotifyAuthConfig.
    public static func pkce(
        clientID: String,
        redirectURI: URL,
        scopes: Set<SpotifyScope> = [],
        showDialog: Bool = false,
        authorizationEndpoint: URL = SpotifyAuthConfig
            .defaultAuthorizationEndpoint,
        tokenEndpoint: URL = SpotifyAuthConfig.defaultTokenEndpoint
    ) -> SpotifyAuthConfig {
        SpotifyAuthConfig(
            clientID: clientID,
            clientSecret: nil,
            redirectURI: redirectURI,
            scopes: scopes,
            showDialog: showDialog,
            authorizationEndpoint: authorizationEndpoint,
            tokenEndpoint: tokenEndpoint
        )
    }

    /// Create a configuration for Authorization Code flow (server-side apps).
    ///
    /// Authorization Code flow is for confidential apps that can securely store a client secret.
    ///
    /// - Parameters:
    ///   - clientID: Your Spotify application's client ID.
    ///   - clientSecret: Your Spotify application's client secret.
    ///   - redirectURI: The redirect URI registered in your Spotify app settings.
    ///   - scopes: The authorization scopes your app needs (default: empty).
    ///   - showDialog: Whether to force the user to approve the app again (default: false).
    ///   - authorizationEndpoint: Custom authorization endpoint (default: Spotify's endpoint).
    ///   - tokenEndpoint: Custom token endpoint (default: Spotify's endpoint).
    /// - Returns: A configured SpotifyAuthConfig.
    public static func authorizationCode(
        clientID: String,
        clientSecret: String,
        redirectURI: URL,
        scopes: Set<SpotifyScope> = [],
        showDialog: Bool = false,
        authorizationEndpoint: URL = SpotifyAuthConfig
            .defaultAuthorizationEndpoint,
        tokenEndpoint: URL = SpotifyAuthConfig.defaultTokenEndpoint
    ) -> SpotifyAuthConfig {
        SpotifyAuthConfig(
            clientID: clientID,
            clientSecret: clientSecret,
            redirectURI: redirectURI,
            scopes: scopes,
            showDialog: showDialog,
            authorizationEndpoint: authorizationEndpoint,
            tokenEndpoint: tokenEndpoint
        )
    }

    /// Create a configuration for Client Credentials flow (app-only access).
    ///
    /// Client Credentials flow is for server-to-server authentication without user context.
    /// It provides access to public data only.
    ///
    /// - Parameters:
    ///   - clientID: Your Spotify application's client ID.
    ///   - clientSecret: Your Spotify application's client secret.
    ///   - scopes: The authorization scopes (default: empty, usually not needed for this flow).
    ///   - tokenEndpoint: Custom token endpoint (default: Spotify's endpoint).
    /// - Returns: A configured SpotifyAuthConfig.
    public static func clientCredentials(
        clientID: String,
        clientSecret: String,
        scopes: Set<SpotifyScope> = [],
        tokenEndpoint: URL = SpotifyAuthConfig.defaultTokenEndpoint
    ) -> SpotifyAuthConfig {
        SpotifyAuthConfig(
            clientID: clientID,
            clientSecret: clientSecret,
            redirectURI: URL(string: "about:blank")!,
            scopes: scopes,
            showDialog: false,
            authorizationEndpoint: SpotifyAuthConfig
                .defaultAuthorizationEndpoint,
            tokenEndpoint: tokenEndpoint
        )
    }
}
