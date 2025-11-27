import Foundation

extension Album: SpotifyReleaseDateProviding {
    public var releaseDateRawValue: String? { releaseDate }
    public var releaseDatePrecisionValue: ReleaseDatePrecision? {
        releaseDatePrecision
    }
}

extension SimplifiedAlbum: SpotifyReleaseDateProviding {
    public var releaseDateRawValue: String? { releaseDate }
    public var releaseDatePrecisionValue: ReleaseDatePrecision? {
        releaseDatePrecision
    }
}

extension Episode: SpotifyReleaseDateProviding {
    public var releaseDateRawValue: String? { releaseDate }
    public var releaseDatePrecisionValue: ReleaseDatePrecision? {
        releaseDatePrecision
    }
}

extension SimplifiedEpisode: SpotifyReleaseDateProviding {
    public var releaseDateRawValue: String? { releaseDate }
    public var releaseDatePrecisionValue: ReleaseDatePrecision? {
        releaseDatePrecision
    }
}

extension Chapter: SpotifyReleaseDateProviding {
    public var releaseDateRawValue: String? { releaseDate }
    public var releaseDatePrecisionValue: ReleaseDatePrecision? {
        ReleaseDatePrecision(rawValue: releaseDatePrecision)
    }
}

extension SimplifiedChapter: SpotifyReleaseDateProviding {
    public var releaseDateRawValue: String? { releaseDate }
    public var releaseDatePrecisionValue: ReleaseDatePrecision? {
        releaseDatePrecision
    }
}
