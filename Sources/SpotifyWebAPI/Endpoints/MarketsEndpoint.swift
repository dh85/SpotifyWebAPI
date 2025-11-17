import Foundation

enum MarketsEndpoint {

    /// GET /v1/markets
    static func availableMarkets() -> (path: String, query: [URLQueryItem]) {
        let path = "/markets"
        return (path, [])
    }
}
