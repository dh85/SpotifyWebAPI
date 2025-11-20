import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct AdditionalItemTypeTests {

    @Test
    func hasCorrectRawValues() {
        #expect(AdditionalItemType.track.rawValue == "track")
        #expect(AdditionalItemType.episode.rawValue == "episode")
    }

    @Test
    func spotifyQueryValueSortsAlphabetically() {
        let types: Set<AdditionalItemType> = [.track, .episode]
        #expect(types.spotifyQueryValue == "episode,track")
    }

    @Test
    func spotifyQueryValueHandlesSingleType() {
        let types: Set<AdditionalItemType> = [.track]
        #expect(types.spotifyQueryValue == "track")
    }

    @Test
    func spotifyQueryValueHandlesBothTypes() {
        let types: Set<AdditionalItemType> = [.episode, .track]
        #expect(types.spotifyQueryValue == "episode,track")
    }
}
