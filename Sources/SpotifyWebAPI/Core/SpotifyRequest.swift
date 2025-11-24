import Foundation

/// A description of an API request and its expected response type.
public struct SpotifyRequest<Response: Decodable>: Sendable {
    public let method: HTTPMethod
    public let path: String
    public let query: [URLQueryItem]
    public let body: (any Encodable & Sendable)?
    public let requiresAuth: Bool  // Implied: all Spotify API calls require auth

    public init(
        method: HTTPMethod,
        path: String,
        query: [URLQueryItem],
        body: (any Encodable & Sendable)?
    ) {
        self.method = method
        self.path = path
        self.query = query
        self.body = body
        self.requiresAuth = true
    }

    // MARK: - Factory Methods

    /// Creates a GET request.
    public static func get(_ path: String, query: [URLQueryItem] = []) -> Self {
        Self(method: .get, path: path, query: query, body: nil)
    }

    /// Creates a PUT request.
    public static func put(
        _ path: String,
        query: [URLQueryItem] = [],
        body: (any Encodable & Sendable)? = nil
    ) -> Self {
        Self(method: .put, path: path, query: query, body: body)
    }

    /// Creates a POST request.
    public static func post(
        _ path: String,
        query: [URLQueryItem] = [],
        body: (any Encodable & Sendable)? = nil
    ) -> Self {
        Self(method: .post, path: path, query: query, body: body)
    }

    /// Creates a DELETE request.
    public static func delete(
        _ path: String,
        query: [URLQueryItem] = [],
        body: (any Encodable & Sendable)? = nil
    ) -> Self {
        Self(method: .delete, path: path, query: query, body: body)
    }
}
