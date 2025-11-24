# Authentication Guide

Authenticate with Spotify using the built-in helpers and capabilities.

## Selecting a Capability

``SpotifyClientConfiguration`` composes an HTTP client, token store, and capability describing which auth flow you need:

- ``Auth/UserAuthCapability`` wraps the Authorization Code flow with refresh tokens for full user-scoped access.
- ``Auth/AppOnlyAuthCapability`` performs the Client Credentials flow for server-to-server integrations.
- ``Auth/SpotifyPKCEAuthenticator`` enables Authorization Code with PKCE, ideal for SwiftUI or Catalyst apps without a client secret.

```swift
let config = SpotifyClientConfiguration(
    capability: .user(.init(
        clientID: "<client-id>",
        clientSecret: "<client-secret>",
        redirectURI: URL(string: "myapp://callback")!,
        scopes: [.userReadEmail, .playlistModifyPrivate]
    )),
    httpClient: URLSessionHTTPClient(),
    tokenRefresher: SpotifyAuthorizationCodeAuthenticator(
        configuration: .init(
            clientID: "<client-id>",
            clientSecret: "<client-secret>",
            redirectURI: URL(string: "myapp://callback")!
        ),
        tokenStore: RestrictedFileTokenStore()
    )
)
let client = SpotifyClient(configuration: config)
```

## Token Management

Token persistence is abstracted by ``Models/Tokens/SpotifyTokenStore`` implementations:

- ``FileTokenStore`` writes JSON to disk with configurable directory and naming.
- ``RestrictedFileTokenStore`` applies POSIX permission hardening for production use.
- ``InMemoryTokenStore`` keeps tokens ephemeral for tests and previews.

Every authenticator conforms to ``SpotifyTokenRefreshing`` so you can swap the backing storage without touching the calling code. Token refresh is coordinated through ``SpotifyClient/tokenExpirationCallback`` which fires whenever a new access token is issued.

## Best Practices

1. **Use separate credentials per environment.** Scopes request logs and limits cross-tenant risk.
2. **Rotate refresh tokens.** Set `invalidatingPreviousRefreshToken: true` on authenticators whenever you want single-use refresh tokens.
3. **Protect secrets.** Prefer PKCE for client-side apps and restrict client secret exposure to server builds.
4. **Centralize retry policy.** ``SpotifyClientConfiguration/networkRecovery`` controls exponential backoff, per-429 overrides, and cancellation so every auth flow shares the same resilience defaults.
