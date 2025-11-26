import Foundation

/// A fluent builder for constructing and executing Spotify API requests.
///
/// ## Overview
///
/// `RequestBuilder` provides a chainable, type-safe API for building HTTP requests
/// to the Spotify Web API. It simplifies request construction by allowing you to
/// incrementally add query parameters, body content, and pagination settings.
///
/// ## Examples
///
/// ### Simple GET Request
/// ```swift
/// let album = try await client
///     .request(method: .get, path: "/albums/\(id)")
///     .query("market", "US")
///     .decode(Album.self)
/// ```
///
/// ### POST with Body
/// ```swift
/// try await client
///     .request(method: .post, path: "/playlists/\(id)/tracks")
///     .body(["uris": trackURIs])
///     .execute()
/// ```
///
/// ### Pagination with Multiple Query Parameters
/// ```swift
/// let page = try await client
///     .request(method: .get, path: "/me/albums")
///     .query("limit", 50)
///     .query("offset", 100)
///     .query("market", "GB")
///     .decode(Page<SavedAlbum>.self)
/// ```
public struct RequestBuilder<Capability: Sendable>: Sendable {
    private let client: SpotifyClient<Capability>
    private let method: HTTPMethod
    private let path: String
    private var queryItems: [URLQueryItem] = []
    private var body: (any Encodable & Sendable)? = nil

    init(client: SpotifyClient<Capability>, method: HTTPMethod, path: String) {
        self.client = client
        self.method = method
        self.path = path
    }

    /// Adds a query parameter to the request.
    /// - Parameters:
    ///   - name: The name of the query parameter.
    ///   - value: The value of the query parameter. If nil, the parameter is omitted.
    /// - Returns: A modified builder with the new query parameter.
    public func query(_ name: String, _ value: CustomStringConvertible?) -> Self {
        guard let value else { return self }
        var copy = self
        copy.queryItems.append(URLQueryItem(name: name, value: value.description))
        return copy
    }

    /// Adds multiple query parameters to the request.
    /// - Parameter items: A dictionary of query parameters.
    /// - Returns: A modified builder with the new query parameters.
    public func query(_ items: [String: CustomStringConvertible?]) -> Self {
        var copy = self
        for (key, value) in items {
            if let value {
                copy.queryItems.append(URLQueryItem(name: key, value: value.description))
            }
        }
        return copy
    }
    
    /// Adds pagination query parameters (limit and offset).
    /// - Parameters:
    ///   - limit: The maximum number of items to return.
    ///   - offset: The index of the first item to return.
    /// - Returns: A modified builder with pagination parameters.
    public func paginate(limit: Int, offset: Int) -> Self {
        var copy = self
        copy.queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        copy.queryItems.append(URLQueryItem(name: "offset", value: String(offset)))
        return copy
    }
    
    /// Adds a market query parameter if the value is not nil.
    /// - Parameter market: ISO 3166-1 alpha-2 country code.
    /// - Returns: A modified builder with the market parameter if provided.
    public func market(_ market: String?) -> Self {
        query("market", market)
    }

    /// Sets the request body.
    /// - Parameter body: The encodable body content.
    /// - Returns: A modified builder with the set body.
    public func body(_ body: any Encodable & Sendable) -> Self {
        var copy = self
        copy.body = body
        return copy
    }

    /// Executes the request and decodes the response into the specified type.
    /// - Parameter type: The type to decode the response into.
    /// - Returns: The decoded response.
    public func decode<T: Decodable & Sendable>(_ type: T.Type) async throws -> T {
        let request = SpotifyRequest<T>(
            method: method,
            path: path,
            query: queryItems,
            body: body
        )
        return try await client.perform(request)
    }
    
    /// Executes the request and decodes the response into the specified optional type.
    /// Returns nil if the server responds with 204 No Content.
    /// - Parameter type: The type to decode the response into.
    /// - Returns: The decoded response or nil.
    public func decodeOptional<T: Decodable & Sendable>(_ type: T.Type) async throws -> T? {
        let request = SpotifyRequest<T>(
            method: method,
            path: path,
            query: queryItems,
            body: body
        )
        return try await client.requestOptionalJSON(type, request: request)
    }

    /// Executes the request and expects an empty response (Void).
    public func execute() async throws {
        let request = SpotifyRequest<EmptyResponse>(
            method: method,
            path: path,
            query: queryItems,
            body: body
        )
        _ = try await client.perform(request)
    }
}

extension SpotifyClient {
    /// Creates a fluent request builder for the specified method and path.
    /// - Parameters:
    ///   - method: The HTTP method (GET, POST, PUT, DELETE).
    ///   - path: The API endpoint path.
    /// - Returns: A `RequestBuilder` instance.
    nonisolated public func request(method: HTTPMethod, path: String) -> RequestBuilder<Capability> {
        RequestBuilder(client: self, method: method, path: path)
    }
    
    /// Creates a fluent GET request builder.
    /// - Parameter path: The API endpoint path.
    /// - Returns: A `RequestBuilder` configured for GET.
    nonisolated public func get(_ path: String) -> RequestBuilder<Capability> {
        request(method: .get, path: path)
    }
    
    /// Creates a fluent POST request builder.
    /// - Parameter path: The API endpoint path.
    /// - Returns: A `RequestBuilder` configured for POST.
    nonisolated public func post(_ path: String) -> RequestBuilder<Capability> {
        request(method: .post, path: path)
    }
    
    /// Creates a fluent PUT request builder.
    /// - Parameter path: The API endpoint path.
    /// - Returns: A `RequestBuilder` configured for PUT.
    nonisolated public func put(_ path: String) -> RequestBuilder<Capability> {
        request(method: .put, path: path)
    }
    
    /// Creates a fluent DELETE request builder.
    /// - Parameter path: The API endpoint path.
    /// - Returns: A `RequestBuilder` configured for DELETE.
    nonisolated public func delete(_ path: String) -> RequestBuilder<Capability> {
        request(method: .delete, path: path)
    }
}
