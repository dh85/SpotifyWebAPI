import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct AuthorTests {

    @Test
    func decodesFromJSON() throws {
        let json = """
            {
                "name": "J.K. Rowling"
            }
            """
        let data = json.data(using: .utf8)!
        let author: Author = try decodeModel(from: data)

        #expect(author.name == "J.K. Rowling")
    }

    @Test
    func equatableWorksCorrectly() throws {
        let json = """
            {
                "name": "Stephen King"
            }
            """
        let data = json.data(using: .utf8)!
        let author1: Author = try decodeModel(from: data)
        let author2: Author = try decodeModel(from: data)

        #expect(author1 == author2)
    }
}
