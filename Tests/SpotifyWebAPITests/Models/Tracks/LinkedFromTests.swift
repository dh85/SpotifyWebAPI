import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct LinkedFromTests {

    @Test
    func decodesWithAllFields() throws {
        let json = """
            {
                "external_urls": {
                    "spotify": "https://open.spotify.com/track/original123"
                },
                "href": "https://api.spotify.com/v1/tracks/original123",
                "id": "original123",
                "type": "track",
                "uri": "spotify:track:original123"
            }
            """
        let data = json.data(using: .utf8)!
        let linkedFrom: LinkedFrom = try decodeModel(from: data)

        #expect(
            linkedFrom.externalUrls?.spotify?.absoluteString
                == "https://open.spotify.com/track/original123")
        #expect(linkedFrom.href?.absoluteString == "https://api.spotify.com/v1/tracks/original123")
        #expect(linkedFrom.id == "original123")
        #expect(linkedFrom.type == .track)
        #expect(linkedFrom.uri == "spotify:track:original123")
    }

    @Test
    func decodesWithNullFields() throws {
        let json = """
            {
                "external_urls": null,
                "href": null,
                "id": null,
                "type": null,
                "uri": null
            }
            """
        let data = json.data(using: .utf8)!
        let linkedFrom: LinkedFrom = try decodeModel(from: data)

        #expect(linkedFrom.externalUrls == nil)
        #expect(linkedFrom.href == nil)
        #expect(linkedFrom.id == nil)
        #expect(linkedFrom.type == nil)
        #expect(linkedFrom.uri == nil)
    }

    @Test
    func decodesWithEmptyObject() throws {
        let json = "{}"
        let data = json.data(using: .utf8)!
        let linkedFrom: LinkedFrom = try decodeModel(from: data)

        #expect(linkedFrom.externalUrls == nil)
        #expect(linkedFrom.href == nil)
        #expect(linkedFrom.id == nil)
        #expect(linkedFrom.type == nil)
        #expect(linkedFrom.uri == nil)
    }

    @Test
    func encodesCorrectly() throws {
        let linkedFrom = LinkedFrom(
            externalUrls: SpotifyExternalUrls(
                spotify: URL(string: "https://open.spotify.com/track/test")),
            href: URL(string: "https://api.spotify.com/v1/tracks/test"),
            id: "test",
            type: .track,
            uri: "spotify:track:test"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(linkedFrom)
        let decoded: LinkedFrom = try JSONDecoder().decode(LinkedFrom.self, from: data)

        #expect(decoded == linkedFrom)
    }

    @Test
    func equatableWorksCorrectly() {
        let linkedFrom1 = LinkedFrom(
            externalUrls: nil,
            href: URL(string: "https://api.spotify.com/v1/tracks/t1"),
            id: "t1",
            type: .track,
            uri: "spotify:track:t1"
        )
        let linkedFrom2 = LinkedFrom(
            externalUrls: nil,
            href: URL(string: "https://api.spotify.com/v1/tracks/t1"),
            id: "t1",
            type: .track,
            uri: "spotify:track:t1"
        )
        let linkedFrom3 = LinkedFrom(
            externalUrls: nil,
            href: URL(string: "https://api.spotify.com/v1/tracks/t2"),
            id: "t2",
            type: .track,
            uri: "spotify:track:t2"
        )

        #expect(linkedFrom1 == linkedFrom2)
        #expect(linkedFrom1 != linkedFrom3)
    }
}
