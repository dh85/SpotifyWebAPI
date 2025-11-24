# Authentication Guide

SpotifyWebAPI wraps every Spotify Web API auth flow so you can pick the capability that matches your app.

## Capabilities at a Glance

| Capability | Use Case | Key Types |
| --- | --- | --- |
| Authorization Code | Full user access with refresh tokens | `SpotifyAuthorizationCodeAuthenticator`, `UserAuthCapability` |
| Authorization Code + PKCE | Client-side SwiftUI/macOS/iOS apps without a client secret | `SpotifyPKCEAuthenticator`, `PKCEAuthConfiguration` |
| Client Credentials | Server-to-server or tooling jobs | `SpotifyClientCredentialsAuthenticator`, `AppOnlyAuthCapability` |

All helper factories funnel into `SpotifyClientConfiguration`, which owns the capability, HTTP client, token store, and retry policy.

```swift
let configuration = SpotifyClientConfiguration(
    capability: .user(AuthTestFixtures.authCodeConfig()),
    httpClient: URLSessionHTTPClient(),
    tokenRefresher: SpotifyAuthorizationCodeAuthenticator(...)
)
let client = SpotifyClient(configuration: configuration)
```

## Token Stores

Conform to `SpotifyTokenStore` or use the built-ins:

- `InMemoryTokenStore` for previews and short-lived tooling.
- `FileTokenStore` for desktop or server apps that need persistence.
- `RestrictedFileTokenStore` for hardened POSIX permissions.

The client watches for expiration and asks the authenticator to refresh before making a request. You can subscribe to these events via `tokenExpirationCallback`.

## Tips for Consumers

1. **Limit scopes** per `SpotifyScope` so you only request what you actually need.
2. **Isolate credentials** per environment (staging vs. production) to avoid cross-tenant data leaks.
3. **Handle redirect URIs** with `SpotifyAuthorizationCodeFlowHandler` helpers; they parse the callback, validate `state`, and exchange the code.
4. **Share HTTP clients** between capabilities to centralize certificate pinning, proxies, or debugging interceptors.
