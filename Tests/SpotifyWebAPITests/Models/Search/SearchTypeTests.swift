import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct SearchTypeTests {

    @Test
    func hasCorrectRawValues() {
        #expect(SearchType.album.rawValue == "album")
        #expect(SearchType.artist.rawValue == "artist")
        #expect(SearchType.playlist.rawValue == "playlist")
        #expect(SearchType.track.rawValue == "track")
        #expect(SearchType.show.rawValue == "show")
        #expect(SearchType.episode.rawValue == "episode")
        #expect(SearchType.audiobook.rawValue == "audiobook")
    }

    @Test
    func spotifyQueryValueSortsAlphabetically() {
        let types: Set<SearchType> = [.track, .album, .artist]
        #expect(types.spotifyQueryValue == "album,artist,track")
    }

    @Test
    func spotifyQueryValueHandlesSingleType() {
        let types: Set<SearchType> = [.track]
        #expect(types.spotifyQueryValue == "track")
    }

    @Test
    func spotifyQueryValueHandlesAllTypes() {
        let types: Set<SearchType> = [
            .album, .artist, .playlist, .track, .show, .episode, .audiobook,
        ]
        #expect(types.spotifyQueryValue == "album,artist,audiobook,episode,playlist,show,track")
    }

    @Test
    func equatableWorksCorrectly() {
        #expect(SearchType.album == SearchType.album)
        #expect(SearchType.album != SearchType.artist)
    }

    @Test
    func caseIterableContainsAllCases() {
        #expect(SearchType.allCases.count == 7)
        #expect(SearchType.allCases.contains(.album))
        #expect(SearchType.allCases.contains(.artist))
        #expect(SearchType.allCases.contains(.playlist))
        #expect(SearchType.allCases.contains(.track))
        #expect(SearchType.allCases.contains(.show))
        #expect(SearchType.allCases.contains(.episode))
        #expect(SearchType.allCases.contains(.audiobook))
    }

    @Test
    func decodesFromRawValue() {
        #expect(SearchType(rawValue: "album") == .album)
        #expect(SearchType(rawValue: "artist") == .artist)
        #expect(SearchType(rawValue: "invalid") == nil)
    }
}
