import Foundation
import Testing

@testable import SpotifyKit

@Suite struct SimplifiedShowTests {

  @Test
  func decodesSimplifiedShowFixture() throws {
    let data = try TestDataLoader.load("show_full")
    let show: SimplifiedShow = try decodeModel(from: data)

    #expect(show.id == "showid")
    #expect(show.name == "Show Name")
    #expect(show.publisher == "Publisher Name")
    #expect(show.totalEpisodes == 10)
  }
}
