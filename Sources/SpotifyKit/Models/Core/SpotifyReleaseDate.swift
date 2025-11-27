import Foundation

/// Combines the raw release date string with its precision.
///
/// Provides helpers to convert into `DateComponents` depending on whether the API
/// returned a year, month, or day level of granularity.
public struct SpotifyReleaseDate: Codable, Sendable, Equatable {
    public let rawValue: String
    public let precision: ReleaseDatePrecision

    public init(rawValue: String, precision: ReleaseDatePrecision) {
        self.rawValue = rawValue
        self.precision = precision
    }

    public func dateComponents() -> DateComponents? {
        let parts = rawValue.split(separator: "-").map(String.init)
        var components = DateComponents()
        switch precision {
        case .day:
            guard parts.count == 3,
                let year = Int(parts[0]),
                let month = Int(parts[1]),
                let day = Int(parts[2])
            else { return nil }
            components.year = year
            components.month = month
            components.day = day
        case .month:
            guard parts.count >= 2,
                let year = Int(parts[0]),
                let month = Int(parts[1])
            else { return nil }
            components.year = year
            components.month = month
        case .year:
            guard let year = Int(parts.first ?? "") else { return nil }
            components.year = year
        }
        return components
    }
}

// MARK: - Helpers

public protocol SpotifyReleaseDateProviding {
    var releaseDateRawValue: String? { get }
    var releaseDatePrecisionValue: ReleaseDatePrecision? { get }
}

public extension SpotifyReleaseDateProviding {
    var releaseDateInfo: SpotifyReleaseDate? {
        guard
            let raw = releaseDateRawValue,
            let precision = releaseDatePrecisionValue
        else { return nil }
        return SpotifyReleaseDate(rawValue: raw, precision: precision)
    }
}
