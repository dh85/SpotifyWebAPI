import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct SpotifyTokensTests {

    @Test
    func decodesWithAllFields() throws {
        let json = """
            {
                "accessToken": "access123",
                "refreshToken": "refresh456",
                "expiresAt": "2024-01-15T10:30:00Z",
                "scope": "user-read-private user-read-email",
                "tokenType": "Bearer"
            }
            """
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let tokens = try decoder.decode(SpotifyTokens.self, from: data)

        #expect(tokens.accessToken == "access123")
        #expect(tokens.refreshToken == "refresh456")
        #expect(tokens.scope == "user-read-private user-read-email")
        #expect(tokens.tokenType == "Bearer")
    }

    @Test
    func decodesWithoutOptionalFields() throws {
        let json = """
            {
                "accessToken": "access789",
                "expiresAt": "2024-01-15T10:30:00Z",
                "tokenType": "Bearer"
            }
            """
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let tokens = try decoder.decode(SpotifyTokens.self, from: data)

        #expect(tokens.accessToken == "access789")
        #expect(tokens.refreshToken == nil)
        #expect(tokens.scope == nil)
        #expect(tokens.tokenType == "Bearer")
    }

    @Test
    func isExpiredReturnsTrueForPastDate() {
        let tokens = SpotifyTokens(
            accessToken: "test",
            refreshToken: nil,
            expiresAt: Date(timeIntervalSince1970: 0),
            scope: nil,
            tokenType: "Bearer"
        )

        #expect(tokens.isExpired == true)
    }

    @Test
    func isExpiredReturnsFalseForFutureDate() {
        let tokens = SpotifyTokens(
            accessToken: "test",
            refreshToken: nil,
            expiresAt: Date(timeIntervalSinceNow: 3600),
            scope: nil,
            tokenType: "Bearer"
        )

        #expect(tokens.isExpired == false)
    }

    @Test
    func encodesCorrectly() throws {
        let tokens = SpotifyTokens(
            accessToken: "access123",
            refreshToken: "refresh456",
            expiresAt: Date(timeIntervalSince1970: 1_700_000_000),
            scope: "user-read-private",
            tokenType: "Bearer"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(tokens)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(SpotifyTokens.self, from: data)

        #expect(decoded.accessToken == tokens.accessToken)
        #expect(decoded.refreshToken == tokens.refreshToken)
        #expect(decoded.scope == tokens.scope)
        #expect(decoded.tokenType == tokens.tokenType)
    }

    @Test
    func equatableWorksCorrectly() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let tokens1 = SpotifyTokens(
            accessToken: "access1",
            refreshToken: "refresh1",
            expiresAt: date,
            scope: "scope1",
            tokenType: "Bearer"
        )
        let tokens2 = SpotifyTokens(
            accessToken: "access1",
            refreshToken: "refresh1",
            expiresAt: date,
            scope: "scope1",
            tokenType: "Bearer"
        )
        let tokens3 = SpotifyTokens(
            accessToken: "access2",
            refreshToken: "refresh1",
            expiresAt: date,
            scope: "scope1",
            tokenType: "Bearer"
        )

        #expect(tokens1 == tokens2)
        #expect(tokens1 != tokens3)
    }
}
