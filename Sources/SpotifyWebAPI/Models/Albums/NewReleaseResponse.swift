import Foundation

/// Wrapper for the `GET /v1/browse/new-releases` endpoint response.
struct NewReleasesResponse: Codable, Sendable, Equatable {
    let albums: Page<SimplifiedAlbum>
}
