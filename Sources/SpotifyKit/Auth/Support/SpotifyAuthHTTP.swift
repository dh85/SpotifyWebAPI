import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

enum SpotifyAuthHTTP {
    /// Build `application/x-www-form-urlencoded` bodies from query items.
    static func formURLEncodedBody(from items: [URLQueryItem]) -> Data {
        var components = URLComponents()
        components.queryItems = items
        let query = components.percentEncodedQuery ?? ""
        return Data(query.utf8)
    }

    /// Common token decoding logic for all OAuth flows.
    static func decodeTokens(
        from data: Data,
        response: URLResponse,
        existingRefreshToken: String?
    ) throws -> SpotifyTokens {
        guard let http = response as? HTTPURLResponse else {
            throw SpotifyAuthError.unexpectedResponse
        }

        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            throw SpotifyAuthError.httpError(
                statusCode: http.statusCode,
                body: body
            )
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let dto = try decoder.decode(TokenResponseDTO.self, from: data)
        let expiresAt = Date().addingTimeInterval(TimeInterval(dto.expiresIn))

        return SpotifyTokens(
            accessToken: dto.accessToken,
            refreshToken: dto.refreshToken ?? existingRefreshToken,
            expiresAt: expiresAt,
            scope: dto.scope,
            tokenType: dto.tokenType
        )
    }

    /// Raw Spotify token response payload.
    /// Decoded with JSONDecoder.keyDecodingStrategy = .convertFromSnakeCase.
    private struct TokenResponseDTO: Codable {
        let accessToken: String
        let tokenType: String
        let scope: String?
        let expiresIn: Int
        let refreshToken: String?
    }
}
