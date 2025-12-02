import Foundation
import Testing

@testable import SpotifyKit

@Suite
struct SavedItemTests {

  // Test data
  private let baseDate = Date(timeIntervalSince1970: 1_704_110_400)  // 2024-01-01
  private let olderDate = Date(timeIntervalSince1970: 1_703_000_000)  // ~2023-12-19
  private let newerDate = Date(timeIntervalSince1970: 1_705_000_000)  // ~2024-01-11

  private func makeSavedAlbum(addedAt: Date) -> SavedAlbum {
    SavedAlbum(
      addedAt: addedAt,
      album: Album(
        albumType: .album,
        totalTracks: 10,
        availableMarkets: ["US"],
        externalUrls: SpotifyExternalUrls(spotify: nil),
        href: URL(string: "https://api.spotify.com/v1/albums/test")!,
        id: "test",
        images: [],
        name: "Test Album",
        releaseDate: "2024",
        releaseDatePrecision: .year,
        restrictions: nil,
        type: .album,
        uri: "spotify:album:test",
        artists: [],
        tracks: Page(
          href: URL(string: "https://api.spotify.com/v1/albums/test/tracks")!,
          items: [],
          limit: 50,
          next: nil,
          offset: 0,
          previous: nil,
          total: 0
        ),
        copyrights: [],
        externalIds: SpotifyExternalIds(isrc: nil, ean: nil, upc: nil),
        label: nil,
        popularity: nil
      )
    )
  }

  @Test
  func wasAddedAfterReturnsTrue() {
    let saved = makeSavedAlbum(addedAt: newerDate)
    #expect(saved.wasAddedAfter(baseDate))
  }

  @Test
  func wasAddedAfterReturnsFalse() {
    let saved = makeSavedAlbum(addedAt: olderDate)
    #expect(!saved.wasAddedAfter(baseDate))
  }

  @Test
  func wasAddedBeforeReturnsTrue() {
    let saved = makeSavedAlbum(addedAt: olderDate)
    #expect(saved.wasAddedBefore(baseDate))
  }

  @Test
  func wasAddedBeforeReturnsFalse() {
    let saved = makeSavedAlbum(addedAt: newerDate)
    #expect(!saved.wasAddedBefore(baseDate))
  }

  @Test
  func sortedByAddedDateDescending() {
    let items = [
      makeSavedAlbum(addedAt: baseDate),
      makeSavedAlbum(addedAt: newerDate),
      makeSavedAlbum(addedAt: olderDate),
    ]

    let sorted = items.sortedByAddedDate(ascending: false)

    #expect(sorted[0].addedAt == newerDate)
    #expect(sorted[1].addedAt == baseDate)
    #expect(sorted[2].addedAt == olderDate)
  }

  @Test
  func sortedByAddedDateAscending() {
    let items = [
      makeSavedAlbum(addedAt: baseDate),
      makeSavedAlbum(addedAt: newerDate),
      makeSavedAlbum(addedAt: olderDate),
    ]

    let sorted = items.sortedByAddedDate(ascending: true)

    #expect(sorted[0].addedAt == olderDate)
    #expect(sorted[1].addedAt == baseDate)
    #expect(sorted[2].addedAt == newerDate)
  }

  @Test
  func addedBetweenFiltersCorrectly() {
    let items = [
      makeSavedAlbum(addedAt: olderDate),
      makeSavedAlbum(addedAt: baseDate),
      makeSavedAlbum(addedAt: newerDate),
    ]

    let filtered = items.addedBetween(olderDate, and: baseDate)

    #expect(filtered.count == 2)
    #expect(filtered.contains { $0.addedAt == olderDate })
    #expect(filtered.contains { $0.addedAt == baseDate })
  }

  @Test
  func addedAfterFiltersCorrectly() {
    let items = [
      makeSavedAlbum(addedAt: olderDate),
      makeSavedAlbum(addedAt: baseDate),
      makeSavedAlbum(addedAt: newerDate),
    ]

    let filtered = items.addedAfter(baseDate)

    #expect(filtered.count == 1)
    #expect(filtered[0].addedAt == newerDate)
  }

  @Test
  func addedBeforeFiltersCorrectly() {
    let items = [
      makeSavedAlbum(addedAt: olderDate),
      makeSavedAlbum(addedAt: baseDate),
      makeSavedAlbum(addedAt: newerDate),
    ]

    let filtered = items.addedBefore(baseDate)

    #expect(filtered.count == 1)
    #expect(filtered[0].addedAt == olderDate)
  }

  @Test
  func addedBetweenWithEmptyResult() {
    let items = [
      makeSavedAlbum(addedAt: baseDate)
    ]

    let filtered = items.addedBetween(newerDate, and: Date(timeIntervalSince1970: 1_706_000_000))

    #expect(filtered.isEmpty)
  }

  @Test
  func savedItemContentPropertyWorks() {
    let saved = makeSavedAlbum(addedAt: baseDate)
    #expect(saved.content.id == "test")
    #expect(saved.content.name == "Test Album")
  }
}
