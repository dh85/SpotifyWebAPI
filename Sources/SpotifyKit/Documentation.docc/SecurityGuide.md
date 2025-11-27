# Security & Hardening

Ship consumer apps with confidence by keeping tokens, scopes, and traffic locked down.

## Keep Transport Locked Down

- ``URLSessionHTTPClient`` forces HTTPS and accepts a custom `URLSession` so you can add ATS
  exceptions, certificate pinning, or enterprise trust evaluators. On Apple platforms you can call
  ``URLSessionHTTPClient/makePinnedSession(configuration:pinnedCertificates:allowsSelfSignedCertificates:delegateQueue:)``
  with DER certificates bundled in your app:

```swift
let pins = try [
    URLSessionHTTPClient.PinnedCertificate(resource: "spotify_backend", fileExtension: "der")
]
let pinnedSession = try URLSessionHTTPClient.makePinnedSession(
    configuration: .init().withRequestTimeout(15),
    pinnedCertificates: pins
)
let client = URLSessionHTTPClient(session: pinnedSession)
```

- Rate-limit aware retries come from ``NetworkRecoveryConfiguration``. Tune the backoff to match your
  UX (fast retries for playback controls, slower retries for background sync).
- Request interceptors let you redact bodies or headers before anything touches your logging pipeline.
- When injecting custom headers via ``SpotifyClientConfiguration``, prefer
  ``SpotifyClientConfiguration/settingCustomHeader(name:value:)`` so restricted headers (`Authorization`,
  `Host`, `Cookie`, …) remain protected.

## Protect Tokens & Scopes

### Default Token Store Behavior

``TokenStoreFactory/defaultStore(service:account:)`` automatically chooses hardened storage for you:

| Platform | Implementation | Notes |
| --- | --- | --- |
| Apple OSes | ``KeychainTokenStore`` | Stored with `kSecAttrAccessibleAfterFirstUnlock`. |
| Linux / other | ``RestrictedFileTokenStore`` | Directories forced to 0700, files to 0600. |

Usage pattern (always provide unique `service` + `account` identifiers):

```swift
let tokenStore = TokenStoreFactory.defaultStore(
    service: "com.yourcompany.spotify.\(environment)",
    account: currentUserID
)
```

Best practices:

1. Use per-user accounts so shared devices cannot load another user’s tokens.
2. Share keychain groups via `service` if you embed extensions on Apple platforms.
3. On Linux, run under a dedicated user and enable disk encryption; otherwise, implement a custom store (see the envelope-encrypted example below).

- ``SpotifyClientEvents/onTokenExpiring(_:)`` lets you refresh UI widgets or expire sessions without logging raw tokens.
- Keep scopes tight: build feature-specific arrays of ``SpotifyScope`` values and only request what each screen needs.

### Token Rotation Best Practices

Rotate early and often to minimize exposure:

```swift
let authenticator = AuthorizationCodeFlowAuthenticator(
    configuration: AuthorizationCodeFlowClientConfiguration(
        clientID: "your-client-id",
        clientSecret: "your-client-secret",
        redirectURL: URL(string: "yourapp://callback")!
    ),
    tokenStore: tokenStore,
    invalidatingPreviousRefreshToken: true // single-use refresh tokens
)

let client = SpotifyClient(
    authenticator: authenticator,
    tokenExpirationCallback: { tokens in
        if tokens.accessToken.expiresIn < 300 {
            notifyUserSessionExpiring()
        }
    }
)
```

- **Client secrets**: rotate quarterly or after any incident.
- **Refresh tokens**: prefer single-use refresh tokens (`invalidatingPreviousRefreshToken: true`).
- **Access tokens**: let Spotify handle expiration (≈1 hour) and refresh proactively based on `expiresAt`.

Environment-specific credentials pattern:

```swift
struct SpotifyConfig {
    static var clientID: String {
        #if DEBUG
        "dev-client-id"
        #elseif STAGING
        "staging-client-id"
        #else
        "prod-client-id"
        #endif
    }

    static var tokenStore: TokenStore {
        TokenStoreFactory.defaultStore(
            service: "com.yourapp.spotify.\(environment)",
            account: currentUserID
        )
    }
}
```

> `FileTokenStore` samples have been removed to avoid encouraging insecure persistence. Use the default store or provide your own hardened `TokenStore`.

## Safe Testing & Sandboxes

- `SpotifyMockAPIServer` runs a local HTTPS server with canned responses—perfect for UI tests or demos without touching real accounts.
- ``MockSpotifyClient`` works in SwiftUI previews, snapshot tests, or offline development. Inject it wherever your app expects ``SpotifyClientProtocol``.

## Observability Without Leaks

- Use ``DebugLogger`` only in debug builds and configure its redaction rules to strip Authorization
  headers and customer identifiers.
- Observe ``SpotifyClientEvents`` to surface retry events so you can forward them to telemetry without
  exposing payloads.

## Release Checklist

1. Rotate client secrets and refresh tokens per environment.
2. Verify token stores live in secure directories or keychain access groups before shipping.
3. Confirm interceptors remove PII and tokens in staging builds.
4. Re-run the scenarios from <doc:NetworkSecurity> (pinning, sandbox, retry) each release to guard against regressions.

## Security Audit (November 2025)

**Transport**

- ``URLSessionHTTPClient`` defaults to an ephemeral session (no cookies/cache) and exposes
  `makePinnedSession` for Apple platforms. Linux deployments should inject a custom ``HTTPClient`` when
  `Security` APIs are unavailable.

**Token Storage**

- ``TokenStoreFactory`` selects Keychain-backed storage on Apple OSes and ``RestrictedFileTokenStore`` elsewhere. The file store enforces POSIX permissions but intentionally writes JSON in plaintext; use a custom store if disks are untrusted or FDE is disabled.
- For Linux/Windows deployments that need at-rest encryption, implement a ``TokenStore`` that wraps libsodium/NaCl, envelope encryption (AWS KMS, Azure Key Vault), or encrypts with a locally managed key.

**Logging & Telemetry**

- ``DebugLogger`` redacts headers/bodies by default and only emits payload previews when `allowSensitivePayloads` is true. Production configs should leave this off and rely on observers/metrics.
- Keep CI/CD profiles pinned to configurations with `allowSensitivePayloads == false`. Add configuration snapshot tests (see `DebugToolingTests`) so builds fail if sensitive logging is ever enabled.

**Configuration & Headers**

- ``SpotifyClientConfiguration/validate()`` rejects protected headers (`Authorization`, `Host`,
  `Cookie`, …) and enforces the safe `settingCustomHeader` workflow.

**Interceptors & Middleware**

- Request interceptors execute after the SDK applies auth headers but before transport. Register only trusted interceptors and keep them side-effect free—they can still strip security headers if misused.

**Open Follow-Ups**

1. Provide a pinning helper for Linux/Windows or document a full ``HTTPClient`` sample.
2. Offer an encrypted token-store implementation (Secure Enclave, File Protection Complete, libsodium) for high-sensitivity backends.
3. Expand automated tests that verify ``DebugLogger`` never surfaces sensitive payloads when `allowSensitivePayloads` is false.

## Example: Envelope-Encrypted Token Store

```swift
import Foundation
import Crypto

public actor EncryptedFileTokenStore: TokenStore {
    private let url: URL
    private let wrappingKey: SymmetricKey

    public init(url: URL, wrappingKey: SymmetricKey) {
        self.url = url
        self.wrappingKey = wrappingKey
    }

    public func load() async throws -> SpotifyTokens? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let blob = try Data(contentsOf: url)
        let sealedBox = try AES.GCM.SealedBox(combined: blob)
        let data = try AES.GCM.open(sealedBox, using: wrappingKey)
        return try JSONDecoder().decode(SpotifyTokens.self, from: data)
    }

    public func save(_ tokens: SpotifyTokens) async throws {
        let data = try JSONEncoder().encode(tokens)
        let sealed = try AES.GCM.seal(data, using: wrappingKey)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try sealed.combined?.write(to: url, options: .atomic)
    }

    public func clear() async throws {
        try? FileManager.default.removeItem(at: url)
    }
}
```

Key considerations:

- Manage `wrappingKey` via a secure source (Keychain, KMS, environment secret). Never check it into source control.
- Rotate keys periodically and support migrating existing ciphertexts.
- Combine this with the directory-permission hardening already enforced by ``RestrictedFileTokenStore``.
- The sample uses [Swift Crypto](https://github.com/apple/swift-crypto) so it works the same on Apple and Linux.
