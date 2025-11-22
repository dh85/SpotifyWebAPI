import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct LinkedFromTests {

    @Test
    func decodesLinkedFromJSON() throws {
        let json = """
            {
                "external_urls": { "spotify": "https://open.spotify.com/track/original" },
                "href": "https://api.spotify.com/v1/tracks/original",
                "id": "original",
                "type": "track",
                "uri": "spotify:track:original"
            }
            """
        let data = Data(json.utf8)
        let linkedFrom: LinkedFrom = try decodeModel(from: data)

        #expect(linkedFrom.id == "original")
        #expect(linkedFrom.type == .track)
        #expect(
            linkedFrom.externalUrls?.spotify?.absoluteString
                == "https://open.spotify.com/track/original")
    }
}
