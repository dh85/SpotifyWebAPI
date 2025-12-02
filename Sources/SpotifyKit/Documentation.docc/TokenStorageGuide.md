# Token Storage Guide

Learn how to securely store and manage Spotify authentication tokens across different scenarios.

## Overview

SpotifyKit provides secure token storage by default, but you can customize it for advanced use cases like sharing tokens between app extensions, syncing across devices, or adding encryption.

## Default Storage

SpotifyKit automatically uses the most secure storage available:

- **Apple Platforms** (iOS, macOS, tvOS, watchOS): Keychain via `KeychainTokenStore`
- **Linux**: Restricted file with 0600 permissions via `RestrictedFileTokenStore`

```swift
// Uses default storage automatically
let client: UserSpotifyClient = .pkce(
    clientID: "your-client-id",
    redirectURI: URL(string: "myapp://callback")!,
    scopes: [.userReadPrivate]
)
```

## Custom Token Storage

Implement the `TokenStore` protocol for custom storage:

```swift
public protocol TokenStore: Actor {
    func load() async throws -> SpotifyTokens?
    func save(_ tokens: SpotifyTokens) async throws
    func clear() async throws
}
```

## App Groups (Share Between Extensions)

Share tokens between your main app and extensions (Today Widget, Share Extension, etc.).

### 1. Enable App Groups

1. In Xcode, select your target
2. Go to "Signing & Capabilities"
3. Add "App Groups" capability
4. Create a group: `group.com.yourcompany.yourapp`
5. Repeat for all targets that need access

### 2. Create App Group Token Store

```swift
import Foundation

/// Token store that uses App Groups for sharing between app and extensions.
public actor AppGroupTokenStore: TokenStore {
    private let userDefaults: UserDefaults
    private let key: String
    
    public init(appGroupIdentifier: String, key: String = "spotify_tokens") {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else {
            fatalError("Failed to create UserDefaults with app group: \(appGroupIdentifier)")
        }
        self.userDefaults = defaults
        self.key = key
    }
    
    public func load() async throws -> SpotifyTokens? {
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }
        return try JSONDecoder().decode(SpotifyTokens.self, from: data)
    }
    
    public func save(_ tokens: SpotifyTokens) async throws {
        let data = try JSONEncoder().encode(tokens)
        userDefaults.set(data, forKey: key)
    }
    
    public func clear() async throws {
        userDefaults.removeObject(forKey: key)
    }
}
```

### 3. Use in Your App

```swift
// Main app
let tokenStore = AppGroupTokenStore(
    appGroupIdentifier: "group.com.yourcompany.yourapp"
)

let client: UserSpotifyClient = .pkce(
    clientID: "your-client-id",
    redirectURI: URL(string: "myapp://callback")!,
    scopes: [.userReadPrivate],
    tokenStore: tokenStore
)

// Widget extension (same code)
let tokenStore = AppGroupTokenStore(
    appGroupIdentifier: "group.com.yourcompany.yourapp"
)

let client: UserSpotifyClient = .pkce(
    clientID: "your-client-id",
    redirectURI: URL(string: "myapp://callback")!,
    scopes: [.userReadPrivate],
    tokenStore: tokenStore
)
```

## CloudKit Sync (Multi-Device)

Sync tokens across user's devices using CloudKit.

### 1. Enable CloudKit

1. In Xcode, add "iCloud" capability
2. Enable "CloudKit"
3. Create a container or use default

### 2. Create CloudKit Token Store

```swift
import CloudKit
import Foundation

/// Token store that syncs tokens across devices using CloudKit.
public actor CloudKitTokenStore: TokenStore {
    private let container: CKContainer
    private let recordType = "SpotifyTokens"
    private let recordID = CKRecord.ID(recordName: "user_tokens")
    
    public init(containerIdentifier: String? = nil) {
        if let identifier = containerIdentifier {
            self.container = CKContainer(identifier: identifier)
        } else {
            self.container = CKContainer.default()
        }
    }
    
    public func load() async throws -> SpotifyTokens? {
        let database = container.privateCloudDatabase
        
        do {
            let record = try await database.record(for: recordID)
            
            guard let accessToken = record["accessToken"] as? String,
                  let expiresAtTimestamp = record["expiresAt"] as? Double else {
                return nil
            }
            
            let refreshToken = record["refreshToken"] as? String
            let expiresAt = Date(timeIntervalSince1970: expiresAtTimestamp)
            
            return SpotifyTokens(
                accessToken: accessToken,
                refreshToken: refreshToken,
                expiresAt: expiresAt
            )
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }
    
    public func save(_ tokens: SpotifyTokens) async throws {
        let database = container.privateCloudDatabase
        let record = CKRecord(recordType: recordType, recordID: recordID)
        
        record["accessToken"] = tokens.accessToken
        record["refreshToken"] = tokens.refreshToken
        record["expiresAt"] = tokens.expiresAt.timeIntervalSince1970
        
        _ = try await database.save(record)
    }
    
    public func clear() async throws {
        let database = container.privateCloudDatabase
        try await database.deleteRecord(withID: recordID)
    }
}
```

### 3. Use CloudKit Store

```swift
let tokenStore = CloudKitTokenStore()

let client: UserSpotifyClient = .pkce(
    clientID: "your-client-id",
    redirectURI: URL(string: "myapp://callback")!,
    scopes: [.userReadPrivate],
    tokenStore: tokenStore
)
```

### 4. Handle Sync Conflicts

```swift
public actor CloudKitTokenStore: TokenStore {
    // ... previous code ...
    
    public func save(_ tokens: SpotifyTokens) async throws {
        let database = container.privateCloudDatabase
        
        // Fetch existing record to preserve server change tag
        let existingRecord: CKRecord
        do {
            existingRecord = try await database.record(for: recordID)
        } catch let error as CKError where error.code == .unknownItem {
            existingRecord = CKRecord(recordType: recordType, recordID: recordID)
        }
        
        existingRecord["accessToken"] = tokens.accessToken
        existingRecord["refreshToken"] = tokens.refreshToken
        existingRecord["expiresAt"] = tokens.expiresAt.timeIntervalSince1970
        existingRecord["updatedAt"] = Date().timeIntervalSince1970
        
        _ = try await database.save(existingRecord)
    }
}
```

## Encrypted Storage

Add encryption layer on top of any token store.

### 1. Create Encrypted Token Store

```swift
import CryptoKit
import Foundation

/// Token store that encrypts tokens before storage.
public actor EncryptedTokenStore: TokenStore {
    private let wrappedStore: TokenStore
    private let encryptionKey: SymmetricKey
    
    public init(wrappedStore: TokenStore, encryptionKey: SymmetricKey) {
        self.wrappedStore = wrappedStore
        self.encryptionKey = encryptionKey
    }
    
    /// Convenience initializer with password-based key derivation.
    public init(wrappedStore: TokenStore, password: String, salt: Data) throws {
        self.wrappedStore = wrappedStore
        
        // Derive key from password using PBKDF2
        guard let passwordData = password.data(using: .utf8) else {
            throw EncryptionError.invalidPassword
        }
        
        let key = try Self.deriveKey(from: passwordData, salt: salt)
        self.encryptionKey = key
    }
    
    public func load() async throws -> SpotifyTokens? {
        // Load encrypted data
        guard let encryptedTokens = try await wrappedStore.load() else {
            return nil
        }
        
        // Decrypt
        return try decrypt(encryptedTokens)
    }
    
    public func save(_ tokens: SpotifyTokens) async throws {
        // Encrypt
        let encryptedTokens = try encrypt(tokens)
        
        // Save encrypted data
        try await wrappedStore.save(encryptedTokens)
    }
    
    public func clear() async throws {
        try await wrappedStore.clear()
    }
    
    // MARK: - Encryption Helpers
    
    private func encrypt(_ tokens: SpotifyTokens) throws -> SpotifyTokens {
        let data = try JSONEncoder().encode(tokens)
        let sealedBox = try AES.GCM.seal(data, using: encryptionKey)
        
        guard let combined = sealedBox.combined else {
            throw EncryptionError.encryptionFailed
        }
        
        // Store encrypted data as base64 in access token field
        return SpotifyTokens(
            accessToken: combined.base64EncodedString(),
            refreshToken: nil,
            expiresAt: Date.distantFuture
        )
    }
    
    private func decrypt(_ encryptedTokens: SpotifyTokens) throws -> SpotifyTokens {
        guard let combined = Data(base64Encoded: encryptedTokens.accessToken) else {
            throw EncryptionError.decryptionFailed
        }
        
        let sealedBox = try AES.GCM.SealedBox(combined: combined)
        let decryptedData = try AES.GCM.open(sealedBox, using: encryptionKey)
        
        return try JSONDecoder().decode(SpotifyTokens.self, from: decryptedData)
    }
    
    private static func deriveKey(from password: Data, salt: Data) throws -> SymmetricKey {
        // Use PBKDF2 with 100,000 iterations
        let iterations = 100_000
        let keyLength = 32 // 256 bits
        
        var derivedKeyData = Data(count: keyLength)
        let result = derivedKeyData.withUnsafeMutableBytes { derivedKeyBytes in
            salt.withUnsafeBytes { saltBytes in
                password.withUnsafeBytes { passwordBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBytes.baseAddress, password.count,
                        saltBytes.baseAddress, salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(iterations),
                        derivedKeyBytes.baseAddress, keyLength
                    )
                }
            }
        }
        
        guard result == kCCSuccess else {
            throw EncryptionError.keyDerivationFailed
        }
        
        return SymmetricKey(data: derivedKeyData)
    }
    
    enum EncryptionError: Error {
        case invalidPassword
        case encryptionFailed
        case decryptionFailed
        case keyDerivationFailed
    }
}
```

### 2. Use Encrypted Store

```swift
// Generate or load encryption key
let encryptionKey = SymmetricKey(size: .bits256)

// Or derive from password
let salt = Data(count: 16) // Store this securely
let encryptedStore = try EncryptedTokenStore(
    wrappedStore: KeychainTokenStore(),
    password: "user-password",
    salt: salt
)

let client: UserSpotifyClient = .pkce(
    clientID: "your-client-id",
    redirectURI: URL(string: "myapp://callback")!,
    scopes: [.userReadPrivate],
    tokenStore: encryptedStore
)
```

### 3. Store Encryption Key Securely

```swift
import Security

actor KeychainKeyStore {
    private let service = "com.yourapp.encryption"
    private let account = "token-encryption-key"
    
    func saveKey(_ key: SymmetricKey) throws {
        let keyData = key.withUnsafeBytes { Data($0) }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }
    
    func loadKey() throws -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let keyData = result as? Data else {
            return nil
        }
        
        return SymmetricKey(data: keyData)
    }
    
    enum KeychainError: Error {
        case saveFailed(OSStatus)
    }
}
```

## In-Memory Storage (Testing)

For tests or temporary sessions:

```swift
public actor InMemoryTokenStore: TokenStore {
    private var tokens: SpotifyTokens?
    
    public init() {}
    
    public func load() async throws -> SpotifyTokens? {
        tokens
    }
    
    public func save(_ tokens: SpotifyTokens) async throws {
        self.tokens = tokens
    }
    
    public func clear() async throws {
        self.tokens = nil
    }
}

// Use in tests
let client: UserSpotifyClient = .pkce(
    clientID: "test-id",
    redirectURI: URL(string: "test://callback")!,
    scopes: [.userReadPrivate],
    tokenStore: InMemoryTokenStore()
)
```

## Best Practices

### 1. Choose the Right Storage

```swift
// ✅ Default for most apps
let client: UserSpotifyClient = .pkce(...)

// ✅ App with extensions
let store = AppGroupTokenStore(appGroupIdentifier: "group.com.app")
let client: UserSpotifyClient = .pkce(..., tokenStore: store)

// ✅ Multi-device sync
let store = CloudKitTokenStore()
let client: UserSpotifyClient = .pkce(..., tokenStore: store)

// ✅ High security requirements
let store = try EncryptedTokenStore(
    wrappedStore: KeychainTokenStore(),
    password: userPassword,
    salt: salt
)
let client: UserSpotifyClient = .pkce(..., tokenStore: store)
```

### 2. Handle Storage Errors

```swift
do {
    let profile = try await client.users.me()
} catch {
    // Token might be corrupted or storage unavailable
    // Clear and re-authenticate
    try? await client.clearTokens()
    showLoginScreen()
}
```

### 3. Secure Encryption Keys

```swift
// ❌ Don't hardcode keys
let key = SymmetricKey(data: Data([1, 2, 3, ...]))

// ✅ Generate and store securely
let key = SymmetricKey(size: .bits256)
try await keyStore.saveKey(key)

// ✅ Or derive from user password
let key = try deriveKey(from: userPassword, salt: salt)
```

### 4. Test Storage Implementation

```swift
@Test
func tokenStoreSaveAndLoad() async throws {
    let store = AppGroupTokenStore(appGroupIdentifier: "group.test")
    
    let tokens = SpotifyTokens(
        accessToken: "test-token",
        refreshToken: "refresh-token",
        expiresAt: Date().addingTimeInterval(3600)
    )
    
    try await store.save(tokens)
    let loaded = try await store.load()
    
    #expect(loaded?.accessToken == tokens.accessToken)
    #expect(loaded?.refreshToken == tokens.refreshToken)
}
```

### 5. Handle Migration

```swift
actor TokenStoreMigrator {
    func migrate(from oldStore: TokenStore, to newStore: TokenStore) async throws {
        guard let tokens = try await oldStore.load() else {
            return
        }
        
        try await newStore.save(tokens)
        try await oldStore.clear()
    }
}

// Migrate from default to app group
let migrator = TokenStoreMigrator()
try await migrator.migrate(
    from: KeychainTokenStore(),
    to: AppGroupTokenStore(appGroupIdentifier: "group.com.app")
)
```

## Common Scenarios

### Scenario 1: Today Widget

```swift
// Shared token store
let tokenStore = AppGroupTokenStore(
    appGroupIdentifier: "group.com.yourapp"
)

// Main app authenticates
let client: UserSpotifyClient = .pkce(
    clientID: "your-client-id",
    redirectURI: URL(string: "myapp://callback")!,
    scopes: [.userReadPrivate, .userTopRead],
    tokenStore: tokenStore
)

// Widget reads tokens
struct NowPlayingWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "NowPlaying", provider: Provider()) { entry in
            NowPlayingView(entry: entry)
        }
    }
}

struct Provider: TimelineProvider {
    let client: UserSpotifyClient = .pkce(
        clientID: "your-client-id",
        redirectURI: URL(string: "myapp://callback")!,
        scopes: [.userReadPrivate],
        tokenStore: AppGroupTokenStore(appGroupIdentifier: "group.com.yourapp")
    )
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        Task {
            let state = try? await client.player.state()
            // Update widget
        }
    }
}
```

### Scenario 2: Multi-Device App

```swift
// Enable CloudKit sync
let tokenStore = CloudKitTokenStore()

let client: UserSpotifyClient = .pkce(
    clientID: "your-client-id",
    redirectURI: URL(string: "myapp://callback")!,
    scopes: [.userReadPrivate],
    tokenStore: tokenStore
)

// User logs in on iPhone
// Tokens automatically sync to iPad and Mac
```

### Scenario 3: Enterprise App with Encryption

```swift
// Load or generate encryption key
let keyStore = KeychainKeyStore()
let encryptionKey = try await keyStore.loadKey() ?? {
    let key = SymmetricKey(size: .bits256)
    try await keyStore.saveKey(key)
    return key
}()

// Wrap default store with encryption
let encryptedStore = EncryptedTokenStore(
    wrappedStore: KeychainTokenStore(),
    encryptionKey: encryptionKey
)

let client: UserSpotifyClient = .pkce(
    clientID: "your-client-id",
    redirectURI: URL(string: "myapp://callback")!,
    scopes: [.userReadPrivate],
    tokenStore: encryptedStore
)
```

## Topics

### Related Guides

- <doc:AuthGuide>
- <doc:SecurityGuide>
- <doc:TestingGuide>
