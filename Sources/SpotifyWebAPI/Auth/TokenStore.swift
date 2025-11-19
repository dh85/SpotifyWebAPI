import Foundation

/// Abstraction for loading/saving tokens, so you can plug in Keychain, file,
/// UserDefaults, encrypted storage, etc.
public protocol TokenStore: Sendable {
    func load() async throws -> SpotifyTokens?
    func save(_ tokens: SpotifyTokens) async throws
    func clear() async throws
}

/// Simple filesystem-based token store for demonstration / macOS use.
/// On iOS, a Keychain-backed implementation is recommended.
public actor FileTokenStore: TokenStore {
    private let fileURL: URL

    /// - Parameters:
    ///   - filename: File name to store tokens under (default `spotify_tokens.json`).
    ///   - directory: Optional base directory. If `nil`, uses the user's
    ///                Documents directory, or `NSTemporaryDirectory()` as a fallback.
    public init(
        filename: String = "spotify_tokens.json",
        directory: URL? = nil
    ) {
        if let directory {
            self.fileURL = directory.appendingPathComponent(filename)
        } else {
            let base: URL
            if let documentsURL = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first,
               FileManager.default.fileExists(atPath: documentsURL.path) {
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
