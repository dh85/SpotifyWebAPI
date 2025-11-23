import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct CategoryTests {

    @Test
    func categoryDecodesCorrectly() throws {
        let testData = try TestDataLoader.load("category_full.json")
        let category: SpotifyCategory = try decodeModel(from: testData)
        expectCategoryMatches(category, SpotifyCategory.fullExample)
    }

    private func expectCategoryMatches(_ actual: SpotifyCategory, _ expected: SpotifyCategory) {
        #expect(actual.id == expected.id)
        #expect(actual.name == expected.name)
        #expect(actual.href == expected.href)
        #expect(actual.icons.count == expected.icons.count)
        #expect(actual.icons.first?.height == expected.icons.first?.height)
        #expect(actual.icons.first?.width == expected.icons.first?.width)
        #expect(actual.icons.first?.url == expected.icons.first?.url)
    }
}

extension SpotifyCategory {
    fileprivate static let fullExample = SpotifyCategory(
        href: URL(string: "https://api.spotify.com/v1/browse/categories/party")!,
        icons: [
            SpotifyImage(
                url: URL(
                    string:
                        "https://d34qmkt8w5wll9.cloudfront.net/album/images/party_274x274.jpg"
                )!, height: 274, width: 274)
        ],
        id: "party",
        name: "Party"
    )
}
