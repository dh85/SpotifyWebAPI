import Foundation

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

    /// Configuration tailored for PKCE flows (public / mobile clients).
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

    /// Configuration for the OAuth 2.0 Authorization Code flow (confidential clients).
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

    /// Configuration for the OAuth 2.0 Client Credentials flow
    /// (no redirect, app-only tokens).
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
