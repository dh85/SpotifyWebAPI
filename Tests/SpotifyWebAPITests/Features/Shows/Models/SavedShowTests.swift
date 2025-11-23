import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct SavedShowTests {

    @Test
    func decodesSavedShowsPage() throws {
        let data = try TestDataLoader.load("shows_saved")
        let page: Page<SavedShow> = try decodeModel(from: data)

        #expect(page.total == 1)
        let item = try #require(page.items.first)
        #expect(item.show.id == "saved1")
        #expect(item.show.name == "Saved Show")
    }
}
