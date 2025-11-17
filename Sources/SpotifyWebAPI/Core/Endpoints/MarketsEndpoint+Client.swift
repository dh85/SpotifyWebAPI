import Foundation

extension SpotifyClient where Capability: PublicSpotifyCapability {

    /// Get the list of markets where Spotify is available.
    ///
    /// Corresponds to: `GET /v1/markets`
    ///
    /// - Returns: A list of ISO 3166-1 alpha-2 country codes.
    public func availableMarkets() async throws -> [String] {

        let endpoint = MarketsEndpoint.availableMarkets()
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        // Decode the wrapper object
        let response = try await requestJSON(
            AvailableMarketsResponse.self,
            url: url
        )

        // Return the unwrapped array of market strings
        return response.markets
    }
}
