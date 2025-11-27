import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

/// Build shared authorization query parameters.
func buildAuthorizationQueryItems(
    config: SpotifyAuthConfig,
    state: String,
    additionalItems: [URLQueryItem] = []
) -> [URLQueryItem] {
    var items: [URLQueryItem] = [
        URLQueryItem(name: "client_id", value: config.clientID),
        URLQueryItem(name: "response_type", value: "code"),
        URLQueryItem(name: "redirect_uri", value: config.redirectURI.absoluteString),
        URLQueryItem(name: "state", value: state),
    ]

    if !config.scopes.isEmpty {
        items.append(
            URLQueryItem(
                name: "scope",
                value: config.scopes.spotifyQueryValue
            )
        )
    }

    if config.showDialog {
        items.append(URLQueryItem(name: "show_dialog", value: "true"))
    }

    items.append(contentsOf: additionalItems)
    return items
}

/// Parse the callback URL returned from Spotify authorization flows.
func parseAuthorizationCallback(
    _ url: URL,
    componentsBuilder: (URL) -> URLComponents?
) throws -> (code: String, state: String) {
    guard let components = componentsBuilder(url) else {
        throw SpotifyAuthError.missingCode
    }

    let items = components.queryItems ?? []

    func value(_ name: String) -> String? {
        items.first(where: { $0.name == name })?.value
    }

    guard let code = value("code") else {
        throw SpotifyAuthError.missingCode
    }
    guard let state = value("state") else {
        throw SpotifyAuthError.missingState
    }

    return (code, state)
}

/// Construct a POST request for Spotify's token endpoint.
func makeTokenRequest(
    endpoint: URL,
    bodyItems: [URLQueryItem],
    basicAuthCredentials: (clientID: String, clientSecret: String)? = nil
) -> URLRequest {
    var request = URLRequest(url: endpoint)
    request.httpMethod = "POST"
    request.setValue(
        "application/x-www-form-urlencoded",
        forHTTPHeaderField: "Content-Type"
    )

    if let credentials = basicAuthCredentials {
        let raw = "\(credentials.clientID):\(credentials.clientSecret)"
        if let data = raw.data(using: .utf8) {
            let base64Credentials = data.base64EncodedString()
            request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        }
    }

    request.httpBody = SpotifyAuthHTTP.formURLEncodedBody(from: bodyItems)
    return request
}

/// Generate a random state string for CSRF protection.
func generateState() -> String {
    UUID().uuidString.replacingOccurrences(of: "-", with: "")
}

#if DEBUG
    /// Test helper to expose form URL encoding logic.
    func __test_formURLEncodedBody(items: [URLQueryItem]) -> Data {
        SpotifyAuthHTTP.formURLEncodedBody(from: items)
    }
#endif
