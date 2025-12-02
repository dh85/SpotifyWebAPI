import Foundation
import Testing

@testable import SpotifyKit

@Suite struct CoreModelHelpersTests {

  @Test
  func releaseDateComponentsHandlePrecisions() {
    let day = SpotifyReleaseDate(rawValue: "2024-11-01", precision: .day)
    let month = SpotifyReleaseDate(rawValue: "2024-11", precision: .month)
    let year = SpotifyReleaseDate(rawValue: "2024", precision: .year)

    #expect(day.dateComponents()?.day == 1)
    #expect(month.dateComponents()?.month == 11)
    #expect(year.dateComponents()?.year == 2024)

    let invalid = SpotifyReleaseDate(rawValue: "invalid", precision: .day)
    #expect(invalid.dateComponents() == nil)
  }

  @Test
  func releaseDateProvidingBuildsSpotifyReleaseDate() {
    struct Provider: SpotifyReleaseDateProviding {
      let releaseDateRawValue: String?
      let releaseDatePrecisionValue: ReleaseDatePrecision?
    }

    let provider = Provider(
      releaseDateRawValue: "2010-05",
      releaseDatePrecisionValue: .month
    )

    let info = provider.releaseDateInfo
    #expect(info?.rawValue == "2010-05")
    #expect(info?.precision == .month)
  }

  @Test
  func spotifyResourceSummaryIncludesIdentifyingFields() {
    struct Resource: SpotifyResource {
      let externalUrls: SpotifyExternalUrls?
      let hrefURL: URL?
      let spotifyID: String?
      let displayName: String
      let objectType: SpotifyObjectType
      let spotifyURI: String?
    }

    let resource = Resource(
      externalUrls: nil,
      hrefURL: URL(string: "https://api.spotify.com/v1/test")!,
      spotifyID: "abc123",
      displayName: "Demo",
      objectType: .album,
      spotifyURI: "spotify:album:abc123"
    )

    #expect(resource.resourceSummary.contains("Demo"))
    #expect(resource.resourceSummary.contains("abc123"))
  }
}
