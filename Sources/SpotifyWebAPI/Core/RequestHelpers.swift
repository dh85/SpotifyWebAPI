import Foundation

extension SpotifyClient {

    // MARK: - URL building

    func apiURL(path: String, queryItems: [URLQueryItem]? = nil) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.spotify.com"
        components.path = "/v1" + path
        components.queryItems = queryItems
        return components.url!
    }

    private func executeRequest(
        _ request: URLRequest,
        retryCount: Int = 1
    ) async throws -> (Data, URLResponse) {

        let (data, response) = try await httpClient.data(for: request)

        // Check for 429
        if let http = response as? HTTPURLResponse,
            http.statusCode == 429,
            retryCount > 0
        {
            // Get the 'Retry-After' header (in seconds)
            let retryAfter: UInt64 =
                http.value(forHTTPHeaderField: "Retry-After")
                .flatMap(UInt64.init) ?? 5  // Default to 5s if missing

            // Sleep for the required duration
            try await Task.sleep(for: .seconds(retryAfter))

            // Retry the request (and pass 0 so it doesn't retry again)
            return try await executeRequest(request, retryCount: 0)
        }

        return (data, response)
    }

    // MARK: - Low-level authorized request
    
    func authorizedRequest(
        url: URL,
        method: String = "GET",
        body: Data? = nil,
        contentType: String? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        // 1. Get a token using the active auth backend.
        var token = try await accessToken()
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        if let contentType {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }

        // --- MODIFICATION ---
        // Call our new helper instead of httpClient.data
        let (data, response) = try await executeRequest(request)
        // --- END MODIFICATION ---

        guard let http = response as? HTTPURLResponse else {
            throw SpotifyAuthError.unexpectedResponse
        }

        // 2. If we got a 401, try once more with a fresh token.
        guard http.statusCode == 401 else {
            return (data, http)
        }

        token = try await accessToken(invalidatingPrevious: true)
        var retry = request
        retry.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        // --- MODIFICATION ---
        // Also call our new helper here
        let (data2, response2) = try await executeRequest(retry)
        // --- END MODIFICATION ---

        guard let http2 = response2 as? HTTPURLResponse else {
            throw SpotifyAuthError.unexpectedResponse
        }
        return (data2, http2)
    }

    // MARK: - JSON decoding

    func decodeJSON<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }

    func requestJSON<T: Decodable>(
        _ type: T.Type,
        url: URL,
        method: String = "GET",
        body: Data? = nil
    ) async throws -> T {
        let (data, response) = try await authorizedRequest(
            url: url,
            method: method,
            body: body,
            contentType: body != nil ? "application/json" : nil
        )

        guard (200..<300).contains(response.statusCode) else {
            let bodyString =
                String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            throw SpotifyAuthError.httpError(
                statusCode: response.statusCode,
                body: bodyString
            )
        }

        return try decodeJSON(T.self, from: data)
    }
}
