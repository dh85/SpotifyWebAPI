import Foundation
import Testing

@testable import SpotifyKit

@Suite struct SimplifiedTrackTests {

    @Test
    func decodesSimplifiedTrackFromFixture() throws {
        let data = try TestDataLoader.load("track_full")
        let track: SimplifiedTrack = try decodeModel(from: data)

        #expect(track.id == "track_id")
        #expect(track.name == "Test Track")
        #expect(track.durationMs == 200_000)
        #expect(track.explicit == false)
    }
}
