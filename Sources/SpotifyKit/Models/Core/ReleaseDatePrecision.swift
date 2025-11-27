/// The precision of a release date.
///
/// Indicates the level of detail available for an album, track, or episode release date.
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-an-album)
public enum ReleaseDatePrecision: String, Codable, Equatable, Sendable {
    /// Release date is known to the year only (e.g., "2023").
    case year
    /// Release date is known to the month (e.g., "2023-01").
    case month
    /// Release date is known to the exact day (e.g., "2023-01-15").
    case day
}
