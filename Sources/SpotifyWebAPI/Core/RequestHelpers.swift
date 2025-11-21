import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

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
        retryCount: Int? = nil
    ) async throws -> (Data, URLResponse) {
        return try await networkRecovery.executeWithRecovery {
            try await self.performSingleRequest(request, retryCount: retryCount)
        }
    }
    
    private func performSingleRequest(
        _ request: URLRequest,
        retryCount: Int? = nil
    ) async throws -> (Data, URLResponse) {
        var mutableRequest = request

        // Apply timeout
        mutableRequest.timeoutInterval = configuration.requestTimeout

        // Apply custom headers
        for (key, value) in configuration.customHeaders {
            mutableRequest.setValue(value, forHTTPHeaderField: key)
        }

        // Apply interceptors
        for interceptor in interceptors {
            mutableRequest = try await interceptor(mutableRequest)
        }

        let (data, response) = try await httpClient.data(for: mutableRequest)
        
        // Check for retryable HTTP errors
        if let http = response as? HTTPURLResponse,
           configuration.networkRecovery.retryableStatusCodes.contains(http.statusCode) {
            let bodyString = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            throw SpotifyClientError.httpError(statusCode: http.statusCode, body: bodyString)
        }
        
        // Check for 429 (rate limiting) - handle separately from network recovery
        if let http = response as? HTTPURLResponse, http.statusCode == 429 {
            let remainingRetries = retryCount ?? configuration.maxRateLimitRetries
            guard remainingRetries > 0 else {
                return (data, response)
            }

            // Get the 'Retry-After' header (in seconds)
            let retryAfter: UInt64 =
                http.value(forHTTPHeaderField: "Retry-After")
                .flatMap(UInt64.init) ?? 5  // Default to 5s if missing

            // Sleep for the required duration
            try await Task.sleep(for: .seconds(retryAfter))

            // Retry the request
            return try await executeRequest(request, retryCount: remainingRetries - 1)
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

    /// Executes a request and decodes the response into the specified type.
    /// This method replaces requestJSON, requestVoid, and requestOptionalJSON.
    @discardableResult
    func perform<T: Decodable>(_ request: SpotifyRequest<T>) async throws -> T {

        let httpBody: Data?
        if let body = request.body {
            httpBody = try JSONEncoder().encode(body)
        } else {
            httpBody = nil
        }

        let url = self.apiURL(path: request.path, queryItems: request.query)

        let (data, response) = try await self.authorizedRequest(
            url: url,
            method: request.method,
            body: httpBody,
            contentType: httpBody != nil ? "application/json" : nil
        )

        // Handle 204 No Content
        if response.statusCode == 204 {
            if T.self == EmptyResponse.self {
                return EmptyResponse() as! T  // Success for Void (EmptyResponse)
            }
            // If T is optional (e.g., PlaybackState?), requestOptionalJSON should be used.
            // If T is non-optional, we must throw, as 204 is unexpected.
            throw SpotifyAuthError.unexpectedResponse
        }

        // Check for general 2xx success status
        guard (200..<300).contains(response.statusCode) else {
            let bodyString =
                String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            throw SpotifyAuthError.httpError(
                statusCode: response.statusCode,
                body: bodyString
            )
        }

        // --- THIS IS THE FIX ---
        // If we expect an EmptyResponse and data is empty (e.g., 200 OK w/ no body),
        // return a new instance immediately without decoding.
        if T.self == EmptyResponse.self && data.isEmpty {
            return EmptyResponse() as! T
        }
        // --- END FIX ---

        // Decode the data into the expected type T
        return try self.decodeJSON(T.self, from: data)
    }

    /// Helper for requests that might return 204 No Content (returning nil)
    /// or a JSON object (returning T).
    func requestOptionalJSON<T: Decodable>(
        _ type: T.Type,
        request: SpotifyRequest<T>
    ) async throws -> T? {

        let httpBody: Data?
        if let body = request.body {
            httpBody = try JSONEncoder().encode(body)
        } else {
            httpBody = nil
        }

        let url = self.apiURL(path: request.path, queryItems: request.query)

        let (data, response) = try await self.authorizedRequest(
            url: url,
            method: request.method,
            body: httpBody,
            contentType: httpBody != nil ? "application/json" : nil
        )

        // 1. Handle "No Content" explicitly (returns nil)
        if response.statusCode == 204 {
            return nil
        }

        // 2. Handle Errors
        guard (200..<300).contains(response.statusCode) else {
            let bodyString =
                String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            throw SpotifyAuthError.httpError(
                statusCode: response.statusCode,
                body: bodyString
            )
        }

        // 3. Handle Empty Data (e.g. 200 OK w/ no body)
        // If we get empty data but expected an optional type, return nil.
        if data.isEmpty {
            return nil
        }

        // 4. Decode
        return try self.decodeJSON(T.self, from: data)
    }
}
