# Encrypted Token Storage

Secure token storage for Linux and platforms requiring at-rest encryption.

## Overview

``EncryptedTokenStore`` provides AES-GCM authenticated encryption for tokens stored on disk. This is recommended for Linux deployments or any environment where full-disk encryption is unavailable.

## Quick Start

```swift
import SpotifyKit
import Crypto

// Generate a new encryption key (do this once, store securely)
let key = EncryptedTokenStore.generateKey()

// Create encrypted token store
let store = EncryptedTokenStore(
    filename: "spotify_tokens.encrypted",
    wrappingKey: key
)

// Use with SpotifyClient
let client = SpotifyClient.pkce(
    clientID: "your-client-id",
    redirectURI: URL(string: "myapp://callback")!,
    scopes: [.userReadPrivate],
    tokenStore: store
)
```

## Key Management

The encryption key must be managed securely. **Never commit keys to source control.**

### Environment Variable (Recommended for Servers)

```swift
// Generate key once and export
let key = EncryptedTokenStore.generateKey()
let keyString = EncryptedTokenStore.exportKey(key)
print("SPOTIFY_TOKEN_KEY=\(keyString)")

// Load from environment
guard let keyString = ProcessInfo.processInfo.environment["SPOTIFY_TOKEN_KEY"] else {
    fatalError("SPOTIFY_TOKEN_KEY not set")
}
let key = try EncryptedTokenStore.loadKey(fromBase64: keyString)
let store = EncryptedTokenStore(wrappingKey: key)
```

### Keychain (Apple Platforms)

Store the encryption key in Keychain, tokens in encrypted file:

```swift
import Security

actor KeychainKeyStore {
    func loadOrGenerateKey() throws -> SymmetricKey {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.myapp.spotify.encryptionkey",
            kSecAttrAccount as String: "default",
            kSecReturnData as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecSuccess, let data = item as? Data {
            return SymmetricKey(data: data)
        }
        
        // Generate new key
        let key = EncryptedTokenStore.generateKey()
        let keyData = key.withUnsafeBytes { Data($0) }
        
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.myapp.spotify.encryptionkey",
            kSecAttrAccount as String: "default",
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        SecItemAdd(addQuery as CFDictionary, nil)
        return key
    }
}

// Usage
let keyStore = KeychainKeyStore()
let key = try await keyStore.loadOrGenerateKey()
let store = EncryptedTokenStore(wrappingKey: key)
```

### KMS (AWS, Azure, GCP)

```swift
// AWS KMS example
import AWSKMS

func loadKeyFromKMS() async throws -> SymmetricKey {
    let kms = KMS(region: .useast1)
    let response = try await kms.decrypt(
        .init(ciphertextBlob: encryptedKeyData, keyId: "alias/spotify-tokens")
    )
    return SymmetricKey(data: response.plaintext!)
}

let key = try await loadKeyFromKMS()
let store = EncryptedTokenStore(wrappingKey: key)
```

## Security Properties

- **Algorithm:** AES-GCM (Authenticated Encryption with Associated Data)
- **Key Size:** 256 bits
- **Nonce:** Unique per encryption (automatically generated)
- **Authentication:** Prevents tampering via authentication tag
- **File Permissions:** POSIX 0600 (owner read/write only)
- **Directory Permissions:** POSIX 0700 (owner access only)

## Key Rotation

Rotate encryption keys periodically:

```swift
actor TokenMigrator {
    func rotateKey(
        oldStore: EncryptedTokenStore,
        newKey: SymmetricKey
    ) async throws {
        // Load tokens with old key
        guard let tokens = try await oldStore.load() else { return }
        
        // Save with new key
        let newStore = EncryptedTokenStore(
            filename: "spotify_tokens_v2.encrypted",
            wrappingKey: newKey
        )
        try await newStore.save(tokens)
        
        // Clear old store
        try await oldStore.clear()
    }
}
```

## Platform Comparison

| Platform | Default Store | Encrypted Store | Recommendation |
|----------|--------------|-----------------|----------------|
| iOS/macOS/tvOS/watchOS | ``KeychainTokenStore`` | Not needed | Use Keychain |
| Linux (FDE enabled) | ``RestrictedFileTokenStore`` | Optional | Use default |
| Linux (no FDE) | ``RestrictedFileTokenStore`` | **Recommended** | Use ``EncryptedTokenStore`` |
| Docker/Containers | ``RestrictedFileTokenStore`` | **Recommended** | Use ``EncryptedTokenStore`` |

## Best Practices

1. **Generate keys securely:** Use ``EncryptedTokenStore/generateKey()``
2. **Store keys separately:** Never store keys with encrypted data
3. **Rotate regularly:** Rotate keys every 90 days or after incidents
4. **Use KMS when available:** Leverage cloud KMS for key management
5. **Audit access:** Log key access and token operations
6. **Backup keys:** Store key backups in secure offline storage

## Troubleshooting

### "Invalid base64-encoded key"

The key string is corrupted or not base64-encoded. Regenerate:

```swift
let key = EncryptedTokenStore.generateKey()
let keyString = EncryptedTokenStore.exportKey(key)
```

### "Authentication tag mismatch"

The encrypted file was tampered with or the wrong key was used. Verify:
- Correct key is loaded
- File hasn't been modified
- No concurrent writes to the file

### "Permission denied"

File permissions are incorrect. The store automatically sets 0600, but verify:

```bash
ls -la ~/.config/SpotifyKit/
# Should show: -rw------- (600)
```

## See Also

- ``TokenStore``
- ``KeychainTokenStore``
- ``RestrictedFileTokenStore``
- ``TokenStoreFactory``
