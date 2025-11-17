import Foundation

public struct SpotifyImage: Codable, Sendable, Equatable {
    public let url: URL
    public let height: Int?
    public let width: Int?
}
