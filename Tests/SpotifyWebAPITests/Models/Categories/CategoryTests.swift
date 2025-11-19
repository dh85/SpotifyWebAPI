import Testing
import Foundation
@testable import SpotifyWebAPI

@Suite struct CategoryTests {

    @Test
    func decodes_Category_Correctly() throws {
        let testData = try TestDataLoader.load("category_full.json")

        let category: SpotifyCategory = try decodeModel(from: testData)

        #expect(category.id == "party")
        #expect(category.name == "Party")
        #expect(category.href.absoluteString == "https://api.spotify.com/v1/browse/categories/party")

        let icon = category.icons.first!
        #expect(icon.height == 274)
        #expect(icon.width == 274)
        #expect(icon.url.absoluteString.contains("cloudfront.net"))
    }
}
