# Security & Hardening

Ship consumer apps with confidence by keeping tokens, scopes, and traffic locked down.

## Keep Traffic Private

- ``HTTP/URLSessionHTTPClient`` forces HTTPS and accepts a custom `URLSession` so you can add ATS exceptions, certificate pinning, or enterprise trust evaluators.
- Rate-limit aware retries come from ``Core/Networking/NetworkRecoveryConfiguration``. Tune the backoff to match your UX (for example, fast retries for playback controls, slower retries for library syncs).
- Interceptors under `Core/Networking/Interceptors` let you redact bodies or headers before anything touches your logging pipeline.

## Protect Tokens

- Use ``RestrictedFileTokenStore`` for simulator/local builds and swap in a Keychain-backed `SpotifyTokenStore` for production. The protocol keeps your DI simple across targets.
- ``SpotifyClientEvents/onTokenExpiring(_:)`` tells you when a refresh occurs so you can refresh widgets or show “session expired” banners without dumping raw tokens into analytics.
- Keep scopes tight: build feature-specific arrays of ``SpotifyScope`` values and only request what each screen needs.

## Safe Testing & Sandboxes

- ``SpotifyMockAPIServer`` runs a local HTTPS server with canned responses—perfect for UI tests or demos without touching real accounts.
- ``MockSpotifyClient`` works in pure SwiftUI previews, snapshot tests, or offline development. Inject it wherever your app expects `SpotifyClientProtocol`.

## Observability Without Leaks

- Enable ``Debug/SpotifyRequestLogger`` only in debug builds and configure its redaction rules to strip Authorization headers and customer identifiers.
- ``Debug/NetworkRetryObserver`` surfaces retry events so you can forward them to your telemetry backend without exposing payloads.

## Release Checklist

1. Rotate client secrets and refresh tokens per environment.
2. Verify token stores live in directories (or keychain access groups) with the correct permissions before submitting to TestFlight.
3. Confirm your logging interceptors remove PII and tokens in staging builds.
4. Run the flows from ``Docs/NetworkSecurity.md`` (pinning, sandbox, retry) each release to guard against regressions.
