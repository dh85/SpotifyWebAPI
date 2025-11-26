# Security Checklist

Practical steps to keep Spotify user data private while you ship iOS, macOS, and server apps with SpotifyWebAPI.

## Keep Transport Locked Down

- Use `URLSessionHTTPClient` with a custom `URLSession` so you can enable certificate pinning, ATS exceptions, or enterprise trust evaluation. On Apple platforms you can now call `URLSessionHTTPClient.makePinnedSession(pinnedCertificates:)` with DER certificates from your bundle to enforce TLS pinning without writing a delegate by hand.

```swift
let certs = try [
    URLSessionHTTPClient.PinnedCertificate(resource: "spotify_backend", fileExtension: "der")
]
let pinnedSession = try URLSessionHTTPClient.makePinnedSession(
    configuration: .init().withRequestTimeout(15),
    pinnedCertificates: certs
)
let client = URLSessionHTTPClient(session: pinnedSession)
```
- Adjust `NetworkRecoveryConfiguration` to balance UX and rate-limit protection. Quick retries feel great for playback controls; slower retries avoid hammering the API during sync jobs.
- Add interceptors (`Sources/SpotifyWebAPI/Core/Networking/Interceptors`) to redact headers or bodies before logs leave the device.
- When injecting custom headers via `SpotifyClientConfiguration`, prefer `settingCustomHeader(name:value:)` so restricted headers (`Authorization`, `Host`, `Cookie`, etc.) remain protected. Attempts to override those headers now throw `SpotifyClientConfigurationError.restrictedCustomHeader`.

## Protect Tokens & Scopes

- Use `TokenStoreFactory.defaultStore()` for platform-appropriate secure storage (Keychain on Apple platforms, restricted file storage elsewhere).
- Listen to `client.events.onTokenExpiring` to refresh UI widgets or expire sessions without printing raw tokens.
- Build scope lists with the `SpotifyScope` enums and request only what the current feature needs.

> Legacy `FileTokenStore` samples have been removed to avoid encouraging insecure storage. Use
> `TokenStoreFactory.defaultStore()` or provide your own `TokenStore` that enforces platform security
> requirements.

### Token Rotation Best Practices

Implement token rotation to minimize security exposure:

**Automatic refresh before expiration:**
```swift
// Configure your authenticator to rotate refresh tokens
let authenticator = AuthorizationCodeFlowAuthenticator(
    configuration: AuthorizationCodeFlowClientConfiguration(
        clientID: "your-client-id",
        clientSecret: "your-client-secret",
        redirectURL: URL(string: "yourapp://callback")!
    ),
    tokenStore: tokenStore,
    invalidatingPreviousRefreshToken: true  // ← Single-use refresh tokens
)

// Monitor token expiration
let client = SpotifyClient(
    authenticator: authenticator,
    tokenExpirationCallback: { tokens in
        // Log out user if token can't be refreshed
        if tokens.accessToken.expiresIn < 300 {  // 5 minutes
            notifyUserSessionExpiring()
        }
    }
)
```

**Rotation schedule for production:**
- **Client secrets**: Rotate quarterly or after any security incident
- **Refresh tokens**: Use single-use refresh tokens (`invalidatingPreviousRefreshToken: true`)
- **Access tokens**: Let Spotify handle expiration (typically 1 hour)

**Environment-specific credentials:**
```swift
struct SpotifyConfig {
    static var clientID: String {
        #if DEBUG
            return "dev-client-id"
        #elseif STAGING
            return "staging-client-id"
        #else
            return "prod-client-id"
        #endif
    }
    
    static var tokenStore: TokenStore {
        TokenStoreFactory.defaultStore(
            service: "com.yourapp.spotify.\(environment)",
            account: currentUserID
        )
    }
}

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

## Security Audit (November 2025)

**Transport**
- `Sources/SpotifyWebAPI/HTTP/URLSessionHTTPClient.swift` defaults to an ephemeral `URLSession` (no cookies/cache) and now exposes `makePinnedSession(pinnedCertificates:)` for Apple platforms. Linux deployments still need a custom `HTTPClient` implementation for pinning, so plan for an injected client when `Security` APIs are unavailable.

**Token Storage**
- `TokenStoreFactory` chooses Keychain-backed storage on Apple OSes and `RestrictedFileTokenStore` elsewhere (`Sources/SpotifyWebAPI/Auth/Core/TokenStore.swift`). The file store enforces 0700/0600 permissions and surfaces hardening failures, but it intentionally stores JSON in plaintext. Use a custom `TokenStore` if disks are untrusted or if full-disk encryption is disabled.
- For Linux/Windows deployments that need at-rest encryption, implement a custom `TokenStore` that wraps libsodium/NaCl, envelope encryption (AWS KMS, Azure Key Vault), or encrypts with a locally managed key before writing to disk. See the example below for a simple envelope pattern.

**Logging & Telemetry**
- `DebugLogger` (`Sources/SpotifyWebAPI/Core/Debug/DebugLogger.swift`) redacts headers/bodies by default and only emits payload previews when `allowSensitivePayloads` is true. Production configs should leave this off and rely on observers/metrics instead. Enabling verbose logging now prints an explicit exposure warning.
- Keep CI/CD profiles pinned to configurations with `allowSensitivePayloads == false`. Add configuration snapshot tests (see `DebugToolingTests`) so any attempt to enable sensitive logging in release builds fails fast.

**Configuration & Headers**
- `SpotifyClientConfiguration.validate()` rejects protected headers (`Authorization`, `Host`, `Cookie`, etc.) and offers `settingCustomHeader(name:value:)` for safe injection. Favor that API over mutating the `customHeaders` dictionary so denial rules stay enforced.

**Interceptors & Middleware**
- Request interceptors (see `Sources/SpotifyWebAPI/Core/Networking/RequestHelpers.swift`) execute after the SDK applies auth headers but before the transport runs. Only register trusted interceptors and keep them side-effect free; they can still strip security headers if misused.

**Open Follow-Ups**
- Provide a pinning helper for Linux/Windows (`Security` is unavailable there) or expand the docs with a full `HTTPClient` sample.
- Offer an encrypted token-store implementation (File Protection Complete, Secure Enclave, or libsodium) for high-sensitivity backends.
- Document envelope-encrypted token store patterns and provide starter code.

### Example: Envelope-Encrypted Token Store

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
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try sealed.combined?.write(to: url, options: .atomic)
    }

    public func clear() async throws {
        try? FileManager.default.removeItem(at: url)
    }
}
```

Key considerations:
- Manage `wrappingKey` via a secure source (Keychain, KMS, environment secret). Do not check it into source control.
- Rotate keys periodically and support migrating existing ciphertexts.
- Combine this with the directory-permission hardening already enforced by `RestrictedFileTokenStore`.
- The sample uses the open-source [Swift Crypto](https://github.com/apple/swift-crypto) package (`import Crypto`), which mirrors CryptoKit APIs on Linux and other non-Apple platforms.
- Expand automated tests that verify `DebugLogger` never surfaces sensitive payloads when `allowSensitivePayloads` is false.
