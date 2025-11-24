# Security Checklist

Practical steps to keep Spotify user data private while you ship iOS, macOS, and server apps with SpotifyWebAPI.

## Keep Transport Locked Down

- Use `URLSessionHTTPClient` with a custom `URLSession` so you can enable certificate pinning, ATS exceptions, or enterprise trust evaluation.
- Adjust `NetworkRecoveryConfiguration` to balance UX and rate-limit protection. Quick retries feel great for playback controls; slower retries avoid hammering the API during sync jobs.
- Add interceptors (`Sources/SpotifyWebAPI/Core/Networking/Interceptors`) to redact headers or bodies before logs leave the device.

## Protect Tokens & Scopes

- `RestrictedFileTokenStore` is safe for local builds. For production, back the `SpotifyTokenStore` protocol with the keychain, App Groups, or your backend.
- Listen to `tokenExpirationCallback` to refresh UI widgets or expire sessions without printing raw tokens.
- Build scope lists with the `SpotifyScope` enums and request only what the current feature needs.

## Test Without Real Accounts

- `SpotifyMockAPIServer` spins up a local sandbox so UI tests and demos never touch real credentials.
- `MockSpotifyClient` conforms to `SpotifyClientProtocol`, letting you inject canned data into SwiftUI previews, snapshot tests, or offline dev builds.

## Observe Safely

- Enable `Debug/SpotifyRequestLogger` in staging to capture sanitized payload metadata.
- Forward retry events from `NetworkRetryObserver` to your telemetry backend so ops teams can react to spikes without seeing raw JSON.

## Release Checklist

1. Rotate client secrets and refresh tokens per environment.
2. Confirm token stores reside in secure directories or keychain groups before submitting builds.
3. Ensure logging interceptors strip PII and Authorization headers.
4. Run through `Docs/NetworkSecurity.md` scenarios (pinning, sandbox, retry) before each release.
