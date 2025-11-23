import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

private struct PreparedRequest<Response: Decodable>: @unchecked Sendable {
    let request: SpotifyRequest<Response>
    let urlRequest: URLRequest
    let bodyData: Data?
}

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

    private func prepare<RequestType: Decodable>(
        _ request: SpotifyRequest<RequestType>
    ) throws -> PreparedRequest<RequestType> {
        let bodyData: Data?
        if let body = request.body {
            bodyData = try JSONEncoder().encode(body)
        } else {
            bodyData = nil
        }

        let url = apiURL(path: request.path, queryItems: request.query)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method
        urlRequest.httpBody = bodyData
        if bodyData != nil {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        return PreparedRequest(request: request, urlRequest: urlRequest, bodyData: bodyData)
    }

    private func executeRequest(
        _ request: URLRequest,
        retryCount: Int? = nil
    ) async throws -> HTTPResponse {
        return try await networkRecovery.executeWithRecovery {
            try await self.performSingleRequest(request, retryCount: retryCount)
        }
    }

    private func performSingleRequest(
        _ request: URLRequest,
        retryCount: Int? = nil
    ) async throws -> HTTPResponse {
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

        let response = try await httpClient.data(for: mutableRequest)
        let data = response.data

        // Check for retryable HTTP errors
        if let http = response.httpURLResponse,
            configuration.networkRecovery.retryableStatusCodes.contains(http.statusCode)
        {
            let bodyString = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            throw SpotifyClientError.httpError(statusCode: http.statusCode, body: bodyString)
        }

        // Check for 429 (rate limiting) - handle separately from network recovery
        if let http = response.httpURLResponse, http.statusCode == 429 {
            let remainingRetries = retryCount ?? configuration.maxRateLimitRetries
            guard remainingRetries > 0 else {
                return response
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

        return response
    }

    // MARK: - Low-level authorized request

    func authorizedRequest(_ baseRequest: URLRequest) async throws -> (Data, HTTPURLResponse) {
        var request = baseRequest
        var token = try await accessToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let response = try await executeRequest(request)
        guard let http = response.httpURLResponse else {
            throw SpotifyAuthError.unexpectedResponse
        }

        guard http.statusCode == 401 else {
            return (response.data, http)
        }

        token = try await accessToken(invalidatingPrevious: true)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let retryResponse = try await executeRequest(request)
        guard let retryHTTP = retryResponse.httpURLResponse else {
            throw SpotifyAuthError.unexpectedResponse
        }

        return (retryResponse.data, retryHTTP)
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
    func perform<T: Decodable & Sendable>(_ request: SpotifyRequest<T>) async throws -> T {
        let prepared = try prepare(request)
        let requestKey = generateRequestKey(prepared)

        // Check for ongoing request
        if let ongoingTask = ongoingRequests[requestKey] {
            return try await ongoingTask.value as! T
        }

        // Create new task
        let task = Task<(any Sendable), Error> {
            try await self.performInternal(prepared)
        }

        ongoingRequests[requestKey] = task

        do {
            let result = try await task.value as! T
            ongoingRequests.removeValue(forKey: requestKey)
            return result
        } catch {
            ongoingRequests.removeValue(forKey: requestKey)
            throw error
        }
    }

    private func performInternal<T: Decodable>(_ prepared: PreparedRequest<T>) async throws -> T {
        #if DEBUG
            let logger =
                ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
                ? DebugLogger.testInstance : DebugLogger.shared
        #else
            let logger = DebugLogger.shared
        #endif

        let measurement = PerformanceMeasurement(
            "\(prepared.request.method) \(prepared.request.path)", logger: logger)

        await logger.logRequest(prepared.urlRequest)

        let (data, response) = try await self.authorizedRequest(prepared.urlRequest)

        await logger.logResponse(response, data: data, error: nil)

        // Handle 204 No Content
        if response.statusCode == 204 {
            if T.self == EmptyResponse.self {
                await measurement.finish()
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

        // If we expect an EmptyResponse and data is empty (e.g., 200 OK w/ no body),
        // return a new instance immediately without decoding.
        if T.self == EmptyResponse.self && data.isEmpty {
            await measurement.finish()
            return EmptyResponse() as! T
        }
        // --- END FIX ---

        // Decode the data into the expected type T
        let result = try self.decodeJSON(T.self, from: data)
        await measurement.finish()
        return result
    }

    private func generateRequestKey<T: Decodable>(_ prepared: PreparedRequest<T>) -> String {
        var components = [prepared.request.method, prepared.request.path]

        if !prepared.request.query.isEmpty {
            let queryString = prepared.request.query.map { "\($0.name)=\($0.value ?? "")" }.joined(
                separator: "&")
            components.append(queryString)
        }

        if let bodyData = prepared.bodyData,
            let bodyString = String(data: bodyData, encoding: .utf8)
        {
            components.append(bodyString)
        }

        return components.joined(separator: "|")
    }

    /// Helper for requests that might return 204 No Content (returning nil)
    /// or a JSON object (returning T).
    func requestOptionalJSON<T: Decodable>(
        _ type: T.Type,
        request: SpotifyRequest<T>
    ) async throws -> T? {
        let prepared = try prepare(request)

        #if DEBUG
            let logger =
                ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
                ? DebugLogger.testInstance : DebugLogger.shared
        #else
            let logger = DebugLogger.shared
        #endif

        let measurement = PerformanceMeasurement(
            "\(prepared.request.method) \(prepared.request.path)", logger: logger)

        await logger.logRequest(prepared.urlRequest)

        let (data, response) = try await self.authorizedRequest(prepared.urlRequest)

        await logger.logResponse(response, data: data, error: nil)

        if response.statusCode == 204 || data.isEmpty {
            await measurement.finish()
            return nil
        }

        guard (200..<300).contains(response.statusCode) else {
            let bodyString =
                String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            throw SpotifyAuthError.httpError(
                statusCode: response.statusCode,
                body: bodyString
            )
        }

        let decoded = try self.decodeJSON(T.self, from: data)
        await measurement.finish()
        return decoded
    }
}
