import Foundation
import Testing

@testable import SpotifyKit

@Suite struct SimplifiedEpisodeTests {

    @Test
    func decodesEpisodeFixture() throws {
        let data = try TestDataLoader.load("episode_full")
        let episode: SimplifiedEpisode = try decodeModel(from: data)

        #expect(episode.id == "episodeid")
        #expect(episode.name == "Episode 1")
        #expect(episode.durationMs == 1_800_000)
        #expect(episode.resumePoint?.fullyPlayed == false)
    }
}
