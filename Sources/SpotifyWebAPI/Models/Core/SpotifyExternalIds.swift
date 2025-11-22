/// External IDs for a track.
///
/// Contains various industry-standard identifiers used to identify recordings.
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-track)
public struct SpotifyExternalIds: Codable, Sendable, Equatable {
    /// International Standard Recording Code (ISRC).
    public let isrc: String?
    /// International Article Number (EAN-13 barcode).
    public let ean: String?
    /// Universal Product Code (UPC barcode).
    public let upc: String?
}
