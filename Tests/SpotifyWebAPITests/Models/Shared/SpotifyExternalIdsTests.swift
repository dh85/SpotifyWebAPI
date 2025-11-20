import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct SpotifyExternalIdsTests {

    @Test
    func decodesWithAllFields() throws {
        let json = """
            {
                "isrc": "USRC12345678",
                "ean": "1234567890123",
                "upc": "123456789012"
            }
            """
        let data = json.data(using: .utf8)!
        let externalIds: SpotifyExternalIds = try decodeModel(from: data)

        #expect(externalIds.isrc == "USRC12345678")
        #expect(externalIds.ean == "1234567890123")
        #expect(externalIds.upc == "123456789012")
    }

    @Test
    func decodesWithOnlyIsrc() throws {
        let json = """
            {
                "isrc": "USRC12345678"
            }
            """
        let data = json.data(using: .utf8)!
        let externalIds: SpotifyExternalIds = try decodeModel(from: data)

        #expect(externalIds.isrc == "USRC12345678")
        #expect(externalIds.ean == nil)
        #expect(externalIds.upc == nil)
    }

    @Test
    func decodesWithNullValues() throws {
        let json = """
            {
                "isrc": null,
                "ean": null,
                "upc": null
            }
            """
        let data = json.data(using: .utf8)!
        let externalIds: SpotifyExternalIds = try decodeModel(from: data)

        #expect(externalIds.isrc == nil)
        #expect(externalIds.ean == nil)
        #expect(externalIds.upc == nil)
    }

    @Test
    func encodesCorrectly() throws {
        let externalIds = SpotifyExternalIds(
            isrc: "USRC12345678",
            ean: "1234567890123",
            upc: nil
        )
        let encoder = JSONEncoder()
        let data = try encoder.encode(externalIds)
        let decoded: SpotifyExternalIds = try JSONDecoder().decode(
            SpotifyExternalIds.self, from: data)

        #expect(decoded == externalIds)
    }

    @Test
    func equatableWorksCorrectly() {
        let ids1 = SpotifyExternalIds(isrc: "USRC1", ean: "123", upc: "456")
        let ids2 = SpotifyExternalIds(isrc: "USRC1", ean: "123", upc: "456")
        let ids3 = SpotifyExternalIds(isrc: "USRC2", ean: "123", upc: "456")
        let ids4 = SpotifyExternalIds(isrc: nil, ean: nil, upc: nil)

        #expect(ids1 == ids2)
        #expect(ids1 != ids3)
        #expect(ids1 != ids4)
    }
}
