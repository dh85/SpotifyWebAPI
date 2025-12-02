import Crypto
import Foundation

/// AES-GCM encrypted token store for Linux and other platforms requiring at-rest encryption.
///
/// ## Overview
///
/// Provides envelope encryption for tokens stored on disk. Suitable for deployments where
/// full-disk encryption is unavailable or additional protection is required.
///
/// ## Usage
///
/// ```swift
/// // Generate or load a wrapping key (store securely, never commit to source control)
/// let key = SymmetricKey(size: .bits256)
///
/// let store = EncryptedTokenStore(
///     filename: "tokens.encrypted",
///     wrappingKey: key
/// )
///
/// let client = SpotifyClient.pkce(
///     clientID: "...",
///     redirectURI: URL(string: "myapp://callback")!,
///     scopes: [.userReadPrivate],
///     tokenStore: store
/// )
/// ```
///
/// ## Key Management
///
/// The wrapping key must be managed securely:
/// - **Environment variable:** Load from `SPOTIFY_TOKEN_KEY` (base64-encoded)
/// - **KMS:** Fetch from AWS KMS, Azure Key Vault, or similar
/// - **Keychain (Apple):** Store key in Keychain, tokens in encrypted file
/// - **Never:** Hardcode or commit to version control
///
/// ## Security Properties
///
/// - AES-GCM authenticated encryption (AEAD)
/// - 256-bit keys
/// - Unique nonce per encryption
/// - Authentication tag prevents tampering
/// - Combined with POSIX 0600 file permissions
///
/// - SeeAlso: ``RestrictedFileTokenStore``
public actor EncryptedTokenStore: TokenStore {
  private let fileURL: URL
  private let wrappingKey: SymmetricKey
  private let fileManager: FileManager

  /// Creates an encrypted token store.
  ///
  /// - Parameters:
  ///   - filename: Name of the encrypted file (default: "spotify_tokens.encrypted")
  ///   - directory: Custom directory URL (default: platform-specific secure location)
  ///   - directoryName: Directory name when using default location (default: "SpotifyKit")
  ///   - wrappingKey: AES-256 key for encryption
  ///   - fileManager: File manager instance (default: .default)
  public init(
    filename: String = "spotify_tokens.encrypted",
    directory: URL? = nil,
    directoryName: String = "SpotifyKit",
    wrappingKey: SymmetricKey,
    fileManager: FileManager = .default
  ) {
    self.wrappingKey = wrappingKey
    self.fileManager = fileManager

    let resolvedDirectory = directory ?? Self.defaultDirectory(
      directoryName: directoryName,
      fileManager: fileManager
    )

    do {
      try Self.ensureDirectory(resolvedDirectory, fileManager: fileManager)
    } catch {
      Self.logError("Failed to create directory: \(error)")
    }

    self.fileURL = resolvedDirectory.appendingPathComponent(filename, isDirectory: false)
  }

  public func load() async throws -> SpotifyTokens? {
    guard fileManager.fileExists(atPath: fileURL.path) else {
      return nil
    }

    do {
      let ciphertext = try Data(contentsOf: fileURL)
      let sealedBox = try AES.GCM.SealedBox(combined: ciphertext)
      let plaintext = try AES.GCM.open(sealedBox, using: wrappingKey)

      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601
      return try decoder.decode(SpotifyTokens.self, from: plaintext)
    } catch let error as DecodingError {
      throw TokenStoreError.decodingFailed(error)
    } catch {
      throw TokenStoreError.fileAccessFailed(error)
    }
  }

  public func save(_ tokens: SpotifyTokens) async throws {
    do {
      let encoder = JSONEncoder()
      encoder.dateEncodingStrategy = .iso8601
      let plaintext = try encoder.encode(tokens)

      let sealedBox = try AES.GCM.seal(plaintext, using: wrappingKey)
      guard let ciphertext = sealedBox.combined else {
        throw TokenStoreError.encodingFailed(
          NSError(domain: "EncryptedTokenStore", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "Failed to create combined ciphertext"
          ])
        )
      }

      try Self.ensureDirectory(fileURL.deletingLastPathComponent(), fileManager: fileManager)
      try ciphertext.write(to: fileURL, options: .atomic)
      try Self.applyRestrictedPermissions(to: fileURL)
    } catch let error as EncodingError {
      throw TokenStoreError.encodingFailed(error)
    } catch {
      throw TokenStoreError.fileAccessFailed(error)
    }
  }

  public func clear() async throws {
    guard fileManager.fileExists(atPath: fileURL.path) else { return }
    do {
      try fileManager.removeItem(at: fileURL)
    } catch {
      throw TokenStoreError.fileAccessFailed(error)
    }
  }

  // MARK: - Helpers

  private static func defaultDirectory(
    directoryName: String,
    fileManager: FileManager
  ) -> URL {
    #if os(Linux)
      let base = fileManager.homeDirectoryForCurrentUser
        .appendingPathComponent(".config", isDirectory: true)
      return base.appendingPathComponent(directoryName, isDirectory: true)
    #else
      let appSupport =
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        ?? fileManager.temporaryDirectory
      return appSupport.appendingPathComponent(directoryName, isDirectory: true)
    #endif
  }

  private static func ensureDirectory(_ url: URL, fileManager: FileManager) throws {
    var isDir: ObjCBool = false
    if fileManager.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
      return
    }
    try fileManager.createDirectory(
      at: url,
      withIntermediateDirectories: true,
      attributes: [.posixPermissions: NSNumber(value: Int16(0o700))]
    )
  }

  private static func applyRestrictedPermissions(to fileURL: URL) throws {
    var attributes: [FileAttributeKey: Any] = [
      .posixPermissions: NSNumber(value: Int16(0o600))
    ]

    #if os(iOS) || os(tvOS) || os(watchOS)
      attributes[.protectionKey] = FileProtectionType.completeUntilFirstUserAuthentication
    #endif

    try FileManager.default.setAttributes(attributes, ofItemAtPath: fileURL.path)
  }

  private static func logError(_ message: String) {
    if let data = ("[EncryptedTokenStore] \(message)\n").data(using: .utf8) {
      try? FileHandle.standardError.write(contentsOf: data)
    }
  }
}

// MARK: - Key Management Helpers

extension EncryptedTokenStore {
  /// Creates a new random 256-bit encryption key.
  ///
  /// Store this key securely (Keychain, KMS, environment variable).
  /// Never commit to source control.
  public static func generateKey() -> SymmetricKey {
    SymmetricKey(size: .bits256)
  }

  /// Loads a key from a base64-encoded string.
  ///
  /// Useful for loading keys from environment variables or configuration files.
  ///
  /// ```swift
  /// let keyString = ProcessInfo.processInfo.environment["SPOTIFY_TOKEN_KEY"]!
  /// let key = try EncryptedTokenStore.loadKey(fromBase64: keyString)
  /// ```
  public static func loadKey(fromBase64 string: String) throws -> SymmetricKey {
    guard let data = Data(base64Encoded: string) else {
      throw TokenStoreError.fileAccessFailed(
        NSError(domain: "EncryptedTokenStore", code: 2, userInfo: [
          NSLocalizedDescriptionKey: "Invalid base64-encoded key"
        ])
      )
    }
    return SymmetricKey(data: data)
  }

  /// Exports a key as a base64-encoded string.
  ///
  /// Use this to store keys in environment variables or secure configuration.
  public static func exportKey(_ key: SymmetricKey) -> String {
    key.withUnsafeBytes { Data($0).base64EncodedString() }
  }
}
