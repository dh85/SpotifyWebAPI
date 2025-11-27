import Foundation
import Testing

@testable import SpotifyKit

@Suite struct SearchResultsTests {

    @Test
    func decodesTrackResultsFromFixture() throws {
        let data = try TestDataLoader.load("search_results")
        let results: SearchResults = try decodeModel(from: data)

        let tracks = try #require(results.tracks)
        #expect(tracks.total == 1)
        let track = try #require(tracks.items.first)
        #expect(track.id == "track1")
        #expect(track.name == "Test Track")
        #expect(track.album?.name == "Test Album")
    }
}
