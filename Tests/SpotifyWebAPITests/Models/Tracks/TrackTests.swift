import Testing
import Foundation
@testable import SpotifyWebAPI

@Suite struct TrackModelTests {

    @Test
    func decodes_Track_Full() throws {
        let testData = try TestDataLoader.load("track_full.json")

        let track: Track = try decodeModel(from: testData)

        #expect(track.id == "track_id")
        #expect(track.name == "Test Track")
        #expect(track.type == .track)
        #expect(track.uri == "spotify:track:track_id")
        #expect(track.durationMs == 200_000)
        #expect(track.explicit == false)
        #expect(track.popularity == 75)
        #expect(track.isLocal == false)
        #expect(track.isPlayable == true)
        #expect(track.trackNumber == 5)
        #expect(track.discNumber == 1)

        #expect(track.album?.name == "Test Album")
        #expect(track.artists?.first?.name == "Test Artist")
        #expect(track.externalIds?.isrc == "US-S1Z-23-00001")
        #expect(track.externalIds?.ean == "1234567890")
        #expect(track.externalIds?.upc == "0987654321")

        #expect(track.linkedFrom?.id == "linked_id")
        #expect(track.restrictions?.reason == .market)

        #expect(track.availableMarkets?.contains("US") == true)
    }

    @Test
    func decodes_Track_Minimal() throws {
        let testData = try TestDataLoader.load("track_minimal.json")

        let track: Track = try decodeModel(from: testData)

        #expect(track.id == "track_id")
        #expect(track.name == "Minimal Track")
        #expect(track.type == .track)
        #expect(track.uri == "spotify:track:track_id")

        #expect(track.album == nil)
        #expect(track.artists == nil)
        #expect(track.durationMs == nil)
        #expect(track.popularity == nil)
        #expect(track.isPlayable == nil)
        #expect(track.restrictions == nil)
        #expect(track.externalIds == nil)
    }

    @Test
    func decodes_Track_Production() throws {
        // this is just to test that the response sample from the official
        // documentation decodes successfully
        let testData = try TestDataLoader.load("track_prod.json")

        let track: Track = try decodeModel(from: testData)

        #expect(track.trackNumber == 1)
    }
}
