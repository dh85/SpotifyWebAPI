# Authentication Guide

SpotifyKit wraps every Spotify Web API auth flow so you can pick the capability that matches your app.

## Capabilities at a Glance

| Capability | Use Case | Key Types |
| --- | --- | --- |
| Authorization Code | Full user access with refresh tokens | `SpotifyAuthorizationCodeAuthenticator`, `UserAuthCapability` |
| Authorization Code + PKCE | Client-side SwiftUI/macOS/iOS apps without a client secret | `SpotifyPKCEAuthenticator`, `PKCEAuthConfiguration` |
| Client Credentials | Server-to-server or tooling jobs | `SpotifyClientCredentialsAuthenticator`, `AppOnlyAuthCapability` |

### Builder API (Recommended)

`SpotifyClient` now ships a fluent builder so you can wire the auth flow, token store, HTTP client, and configuration once and reuse the same knobs across flows:

```swift
let client = UserSpotifyClient
    .builder()
    .withPKCE(
        clientID: Env.clientID,
        redirectURI: URL(string: "myapp://callback")!,
        scopes: [.userReadEmail, .playlistModifyPublic]
    )
    .withTokenStore(AppGroupTokenStore())
    .withHTTPClient(PinnedURLSessionHTTPClient())
    .withConfiguration(
        SpotifyClientConfiguration.default
            .withRequestTimeout(45)
            .withMaxRateLimitRetries(2)
            .withDebug(.verbose)
            .mergingCustomHeaders(["X-App-Version": AppInfo.version])
    )
    .build()
```

Fluent `with…` modifiers on `SpotifyClientConfiguration` keep configuration tweaks lightweight—adjusting the timeout or debug settings no longer requires repeating every initialiser argument.

The builder keeps related switches discoverable and makes it trivial to share HTTP clients (for TLS pinning or interceptors) between PKCE and authorization-code flows. The same fluent API works for app-only clients:

```swift
let maintenanceClient = AppSpotifyClient
    .builder()
    .withClientCredentials(clientID: Env.botID, clientSecret: Env.botSecret)
    .withHTTPClient(PinnedURLSessionHTTPClient())
    .build()
```

## Token Stores

Conform to `SpotifyTokenStore` or use the built-ins:

- `InMemoryTokenStore` for previews and short-lived tooling.
- `RestrictedFileTokenStore` for hardened POSIX permissions and non-Apple deployments.
- `TokenStoreFactory.defaultStore()` picks Keychain (Apple platforms) or `RestrictedFileTokenStore` automatically.

The client watches for expiration and asks the authenticator to refresh before making a request. You can subscribe to these events via `client.events.onTokenExpiring`.

## Combine Helpers

All authenticator actors now ship a Combine mirror of their async API surface:

- `SpotifyPKCEAuthenticator`: `handleCallbackPublisher`, `refreshAccessTokenPublisher`, and
    `refreshAccessTokenIfNeededPublisher` wrap the async calls so SwiftUI apps built around Combine can
    authorize without rewriting PKCE state handling.
- `SpotifyAuthorizationCodeAuthenticator`: the same trio of publishers mirrors the server-side flow
    (`handleCallback`, `refreshAccessToken`, and `refreshAccessTokenIfNeeded`).
- `SpotifyClientCredentialsAuthenticator`: use `appAccessTokenPublisher` and
    `loadPersistedTokensPublisher` when background jobs prefer publisher chaining.

Each helper forwards to the async implementation, so token persistence, validation, and metrics stay
in one place regardless of concurrency paradigm.

## Tips for Consumers

1. **Limit scopes** per `SpotifyScope` so you only request what you actually need.
2. **Isolate credentials** per environment (staging vs. production) to avoid cross-tenant data leaks.
3. **Handle redirect URIs** with `SpotifyAuthorizationCodeFlowHandler` helpers; they parse the callback, validate `state`, and exchange the code.
4. **Share HTTP clients** between capabilities to centralize certificate pinning, proxies, or debugging interceptors. The builder API above makes this a one-liner.
