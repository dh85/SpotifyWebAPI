# Authentication Guide

Authenticate with Spotify using the built-in helpers and capabilities.

## Selecting a Capability

``SpotifyClient`` now ships fluent builders that keep the capability selection, HTTP client, token store, and configuration switches in one place:

- ``Auth/UserAuthCapability`` wraps the Authorization Code flow (with or without PKCE) for user-scoped APIs.
- ``Auth/AppOnlyAuthCapability`` performs the Client Credentials flow for server-to-server tools.

```swift
let userClient = UserSpotifyClient
    .builder()
    .withAuthorizationCode(
        clientID: "<client-id>",
        clientSecret: "<client-secret>",
        redirectURI: URL(string: "myapp://callback")!,
        scopes: [.userReadEmail, .playlistModifyPrivate]
    )
    .withTokenStore(RestrictedFileTokenStore())
    .withHTTPClient(URLSessionHTTPClient())
    .withConfiguration(
        SpotifyClientConfiguration.default
            .withRequestTimeout(45)
            .withMaxRateLimitRetries(2)
            .withDebug(.verbose)
            .mergingCustomHeaders(["X-App-Version": "2.1.0"])
    )
    .build()

let appOnlyClient = AppSpotifyClient
    .builder()
    .withClientCredentials(clientID: "bot", clientSecret: "secret")
    .withHTTPClient(URLSessionHTTPClient())
    .build()
```

Prefer the fluent ``SpotifyClientConfiguration/withRequestTimeout(_:)`` and related helpers when you need a single tweak—they keep call sites concise and avoid spelling out every initializer argument.

Use ``SpotifyClientConfiguration`` when you need to tweak retries, debug logging, pinned hosts, or network recovery. The builder feeds that configuration directly into the resulting client so every flow shares the same resilience and telemetry policy.

## Token Management

Token persistence is abstracted by ``Models/Tokens/SpotifyTokenStore`` implementations:

- ``TokenStoreFactory`` provides secure defaults (Keychain on Apple platforms, restricted files elsewhere).
- ``RestrictedFileTokenStore`` applies POSIX permission hardening for production or simulator use.
- ``InMemoryTokenStore`` keeps tokens ephemeral for tests and previews.

Every authenticator conforms to ``SpotifyTokenRefreshing`` so you can swap the backing storage without touching the calling code. Token refresh is coordinated through ``SpotifyClientEvents/onTokenExpiring(_:)`` which fires whenever a new access token is issued.

## Best Practices

1. **Use separate credentials per environment.** Scope requests tightly and prefer the PKCE builder for client-side apps.
2. **Rotate refresh tokens.** Set `invalidatingPreviousRefreshToken: true` on authenticators whenever you want single-use refresh tokens.
3. **Protect secrets.** Prefer PKCE for client-side apps and restrict client secret exposure to server builds.
4. **Centralize retry policy.** ``SpotifyClientConfiguration/networkRecovery`` controls exponential backoff, per-429 overrides, and cancellation so every auth flow shares the same resilience defaults.
