import Foundation

#if canImport(Security)
    import Security
#endif

/// Abstraction for loading/saving tokens, so you can plug in Keychain, file,
/// UserDefaults, encrypted storage, etc.
public protocol TokenStore: Sendable {
    func load() async throws -> SpotifyTokens?
    func save(_ tokens: SpotifyTokens) async throws
    func clear() async throws
}

public enum TokenStoreFactory {
    /// Returns the recommended secure token store for the current platform.
    /// - Parameters:
    ///   - service: Identifier used for the underlying secure store (Keychain service name
    ///              on Apple platforms, directory name elsewhere).
    ///   - account: Logical account label. On Apple platforms this maps to the Keychain account
    ///              field and lets apps isolate tokens per user/session.
    public static func defaultStore(
        service: String = "com.spotifywebapi.tokens",
        account: String = "default"
    ) -> TokenStore {
        #if canImport(Security)
            return KeychainTokenStore(service: service, account: account)
        #else
            return RestrictedFileTokenStore(
                filename: "tokens_\(account).json",
                directoryName: service.replacingOccurrences(of: ".", with: "_")
            )
        #endif
    }
}

public enum TokenStoreError: Error, Sendable {
    #if canImport(Security)
        case keychain(OSStatus)
    #endif
    case encodingFailed(Error)
    case decodingFailed(Error)
    case fileAccessFailed(Error)
}

#if canImport(Security)
    public actor KeychainTokenStore: TokenStore {
        private let service: String
        private let account: String
        private let accessGroup: String?
        private let encoder: JSONEncoder
        private let decoder: JSONDecoder

        public init(
            service: String = "com.spotifywebapi.tokens",
            account: String = "default",
            accessGroup: String? = nil
        ) {
            self.service = service
            self.account = account
            self.accessGroup = accessGroup
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            self.encoder = encoder
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            self.decoder = decoder
        }

        public func load() async throws -> SpotifyTokens? {
            var query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
                kSecReturnData as String: kCFBooleanTrue as Any,
                kSecMatchLimit as String: kSecMatchLimitOne,
            ]
            if let accessGroup {
                query[kSecAttrAccessGroup as String] = accessGroup
            }

            var item: CFTypeRef?
            let status = SecItemCopyMatching(query as CFDictionary, &item)
            if status == errSecItemNotFound {
                return nil
            }
            guard status == errSecSuccess, let data = item as? Data else {
                throw TokenStoreError.keychain(status)
            }

            do {
                return try decoder.decode(SpotifyTokens.self, from: data)
            } catch {
                throw TokenStoreError.decodingFailed(error)
            }
        }

        public func save(_ tokens: SpotifyTokens) async throws {
            let data: Data
            do {
                data = try encoder.encode(tokens)
            } catch {
                throw TokenStoreError.encodingFailed(error)
            }

            var attributes: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
            ]
            if let accessGroup {
                attributes[kSecAttrAccessGroup as String] = accessGroup
            }

            let status = SecItemCopyMatching(attributes as CFDictionary, nil)
            if status == errSecSuccess {
                let updateStatus = SecItemUpdate(
                    attributes as CFDictionary,
                    [kSecValueData as String: data] as CFDictionary
                )
                guard updateStatus == errSecSuccess else {
                    throw TokenStoreError.keychain(updateStatus)
                }
            } else if status == errSecItemNotFound {
                attributes[kSecValueData as String] = data
                let addStatus = SecItemAdd(attributes as CFDictionary, nil)
                guard addStatus == errSecSuccess else {
                    throw TokenStoreError.keychain(addStatus)
                }
            } else {
                throw TokenStoreError.keychain(status)
            }
        }

        public func clear() async throws {
            var query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
            ]
            if let accessGroup {
                query[kSecAttrAccessGroup as String] = accessGroup
            }

            let status = SecItemDelete(query as CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound else {
                throw TokenStoreError.keychain(status)
            }
        }
    }
#endif

/// File-based store that enforces 0700/0600 POSIX permissions and avoids shared directories.
/// This is used as the default store on non-Apple platforms and can be injected manually elsewhere.
public actor RestrictedFileTokenStore: TokenStore {
    private let fileURL: URL
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        filename: String = "spotify_tokens.json",
        directory: URL? = nil,
        directoryName: String = "SpotifyWebAPI",
        fileManager: FileManager = .default,
        encoder: JSONEncoder = RestrictedFileTokenStore.makeDefaultEncoder(),
        decoder: JSONDecoder = RestrictedFileTokenStore.makeDefaultDecoder()
    ) {
        self.fileManager = fileManager
        let resolvedDirectory: URL
        if let directory {
            resolvedDirectory = directory
        } else {
            resolvedDirectory = Self.defaultDirectory(
                directoryName: directoryName,
                fileManager: fileManager
            )
        }
        Self.ensureDirectory(resolvedDirectory, fileManager: fileManager)
        self.fileURL = resolvedDirectory.appendingPathComponent(filename, isDirectory: false)

        self.encoder = encoder
        self.decoder = decoder
    }

    public func load() async throws -> SpotifyTokens? {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        do {
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode(SpotifyTokens.self, from: data)
        } catch let error as DecodingError {
            throw TokenStoreError.decodingFailed(error)
        } catch {
            throw TokenStoreError.fileAccessFailed(error)
        }
    }

    public func save(_ tokens: SpotifyTokens) async throws {
        let data: Data
        do {
            data = try encoder.encode(tokens)
        } catch {
            throw TokenStoreError.encodingFailed(error)
        }

        do {
            Self.ensureDirectory(fileURL.deletingLastPathComponent(), fileManager: fileManager)
            try data.write(to: fileURL, options: .atomic)
            try Self.applyRestrictedPermissions(to: fileURL)
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

    private static func ensureDirectory(_ url: URL, fileManager: FileManager) {
        var isDir: ObjCBool = false
        if fileManager.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
            return
        }
        try? fileManager.createDirectory(
            at: url,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: NSNumber(value: Int16(0o700))]
        )
    }

    @usableFromInline
    static func makeDefaultEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    @usableFromInline
    static func makeDefaultDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
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
}

/// Simple filesystem-based token store kept for samples and local testing.
/// Prefer ``TokenStoreFactory/defaultStore(service:account:)`` for production apps.
public actor FileTokenStore: TokenStore {
    private let fileURL: URL

    public init(
        filename: String = "spotify_tokens.json",
        directory: URL? = nil,
        documentsDirectory: () -> URL? = {
            FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        }
    ) {
        if let directory {
            self.fileURL = directory.appendingPathComponent(filename)
        } else {
            let base: URL
            if let documentsURL = documentsDirectory(),
                FileManager.default.fileExists(atPath: documentsURL.path)
            {
                base = documentsURL
            } else {
                base = URL(fileURLWithPath: NSTemporaryDirectory())
            }
            self.fileURL = base.appendingPathComponent(filename)
        }
    }

    public func load() async throws -> SpotifyTokens? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(SpotifyTokens.self, from: data)
    }

    public func save(_ tokens: SpotifyTokens) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(tokens)
        try data.write(to: fileURL, options: .atomic)
    }

    public func clear() async throws {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
