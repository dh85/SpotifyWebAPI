import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct NarratorTests {

    @Test
    func decodesFromJSON() throws {
        let json = """
            {
                "name": "Jim Dale"
            }
            """
        let data = json.data(using: .utf8)!
        let narrator: Narrator = try decodeModel(from: data)

        #expect(narrator.name == "Jim Dale")
    }

    @Test
    func equatableWorksCorrectly() throws {
        let json = """
            {
                "name": "Stephen Fry"
            }
            """
        let data = json.data(using: .utf8)!
        let narrator1: Narrator = try decodeModel(from: data)
        let narrator2: Narrator = try decodeModel(from: data)

        #expect(narrator1 == narrator2)
    }
}
