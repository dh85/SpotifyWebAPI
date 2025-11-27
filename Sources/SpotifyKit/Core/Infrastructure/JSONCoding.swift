import Foundation

/// Shared JSON encoder/decoder instances for consistent configuration and improved performance.
enum JSONCoding {
    /// Shared JSON encoder for all API requests.
    static let encoder = JSONEncoder()

    /// Shared JSON decoder configured for Spotify API responses.
    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
