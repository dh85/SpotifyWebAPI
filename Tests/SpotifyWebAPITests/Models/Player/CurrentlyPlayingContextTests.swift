import Foundation
import Testing
@testable import SpotifyWebAPI

@Suite("CurrentlyPlayingContext Tests")
struct CurrentlyPlayingContextTests {

    @Test
    func decodesCurrentlyPlayingFixture() throws {
        let data = try TestDataLoader.load("currently_playing")
        let context: CurrentlyPlayingContext = try decodeModel(from: data)

        #expect(context.isPlaying)
        #expect(context.progressMs == 60_000)
        #expect(context.currentlyPlayingType == "track")
        #expect(context.context?.type == "playlist")

        let expectedTimestamp = Date(timeIntervalSince1970: 1_700_000_000)
        #expect(context.timestamp.timeIntervalSince1970 == expectedTimestamp.timeIntervalSince1970)

        let playableItem = try #require(context.item)
        if case let .track(track) = playableItem {
            #expect(track.id == "track_2")
            #expect(track.name == "Currently Playing Track")
        } else {
            Issue.record("Expected currently playing item to be a track.")
        }
    }
}
