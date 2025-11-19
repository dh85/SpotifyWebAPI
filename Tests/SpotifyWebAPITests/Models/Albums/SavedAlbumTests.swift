import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct SavedAlbumTests {

    @Test
    func decodes_SavedAlbum_Correctly() throws {
        // Arrange
        let testData = try TestDataLoader.load("saved_album_item.json")

        // Act
        // Use ISO8601 helper because 'added_at' is a standard date string
        let item: SavedAlbum = try decodeModel(from: testData)

        // Assert
        #expect(item.album.id == "album123")
        #expect(item.album.name == "Test Album")

        // Verify Date Decoding
        // 2024-01-01T12:00:00Z corresponds to 1704110400 seconds since 1970
        #expect(item.addedAt.timeIntervalSince1970 == 1_704_110_400)
    }
}
