import Foundation
import Testing

@testable import SpotifyKit

@Suite
struct SpotifyReleaseDateProvidingTests {

    @Test
    func albumReleaseDateFieldsForwarded() throws {
        let album: Album = try decodeFixture("album_full")

        #expect(album.releaseDateRawValue == "2012-11-16")
        #expect(album.releaseDateRawValue == album.releaseDate)
        #expect(album.releaseDatePrecisionValue == .day)
        #expect(album.releaseDatePrecisionValue == album.releaseDatePrecision)
        #expect(
            album.releaseDateInfo
                == SpotifyReleaseDate(
                    rawValue: "2012-11-16",
                    precision: .day
                )
        )
    }

    @Test
    func simplifiedAlbumReleaseDateFieldsForwarded() throws {
        let album: SimplifiedAlbum = try decodeFixture("simplified_album_full")

        #expect(album.releaseDateRawValue == "2024-01-01")
        #expect(album.releaseDateRawValue == album.releaseDate)
        #expect(album.releaseDatePrecisionValue == .day)
        #expect(album.releaseDatePrecisionValue == album.releaseDatePrecision)
        #expect(
            album.releaseDateInfo
                == SpotifyReleaseDate(
                    rawValue: "2024-01-01",
                    precision: .day
                )
        )
    }

    @Test
    func episodeReleaseDateFieldsForwarded() throws {
        let episode: Episode = try decodeFixture("episode_full")

        #expect(episode.releaseDateRawValue == "2023-01-01")
        #expect(episode.releaseDateRawValue == episode.releaseDate)
        #expect(episode.releaseDatePrecisionValue == .day)
        #expect(episode.releaseDatePrecisionValue == episode.releaseDatePrecision)
        #expect(
            episode.releaseDateInfo
                == SpotifyReleaseDate(
                    rawValue: "2023-01-01",
                    precision: .day
                )
        )
    }

    @Test
    func simplifiedEpisodeReleaseDateFieldsForwarded() throws {
        let data = try TestDataLoader.load("episode_full")
        let episode: SimplifiedEpisode = try decodeModel(from: data)

        #expect(episode.releaseDateRawValue == "2023-01-01")
        #expect(episode.releaseDateRawValue == episode.releaseDate)
        #expect(episode.releaseDatePrecisionValue == .day)
        #expect(episode.releaseDatePrecisionValue == episode.releaseDatePrecision)
        #expect(
            episode.releaseDateInfo
                == SpotifyReleaseDate(
                    rawValue: "2023-01-01",
                    precision: .day
                )
        )
    }

    @Test
    func chapterReleaseDateFieldsForwarded() throws {
        let chapter: Chapter = try decodeFixture("chapter_full")

        #expect(chapter.releaseDateRawValue == "2023-01-01")
        #expect(chapter.releaseDateRawValue == chapter.releaseDate)
        #expect(chapter.releaseDatePrecisionValue == .day)
        #expect(
            chapter.releaseDatePrecisionValue
                == ReleaseDatePrecision(rawValue: chapter.releaseDatePrecision)
        )
        #expect(
            chapter.releaseDateInfo
                == SpotifyReleaseDate(
                    rawValue: "2023-01-01",
                    precision: .day
                )
        )
    }

    @Test
    func simplifiedChapterReleaseDateFieldsForwarded() throws {
        let page: Page<SimplifiedChapter> = try decodeFixture("audiobook_chapters")
        let chapter = try #require(page.items.first)

        #expect(chapter.releaseDateRawValue == "2024-01-01")
        #expect(chapter.releaseDateRawValue == chapter.releaseDate)
        #expect(chapter.releaseDatePrecisionValue == .day)
        #expect(chapter.releaseDatePrecisionValue == chapter.releaseDatePrecision)
        #expect(
            chapter.releaseDateInfo
                == SpotifyReleaseDate(
                    rawValue: "2024-01-01",
                    precision: .day
                )
        )
    }
}
