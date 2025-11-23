# Network Security & TLS Customization

Some deployments must enforce certificate pinning, custom trust stores, or stricter TLS protocol settings than the system defaults. The SpotifyWebAPI package keeps the transport stack swappable so you can inject those policies without forking the library.

## Default Transport

- The built-in ``URLSessionHTTPClient`` uses an ephemeral `URLSession` (no shared caches/cookies) with the platform's default trust evaluation.
- All `SpotifyClient` factory helpers (`pkce`, `authorizationCode`, `clientCredentials`) accept an `httpClient:` argument. If you do not pass one, `URLSessionHTTPClient()` is created for you.
- Provide your own `HTTPClient` to take complete control over TLS behavior.

## Pinning With URLSession

You can keep using the provided HTTP client while swapping in a custom `URLSession` that performs certificate pinning via a delegate.

```swift
import Foundation
#if canImport(Security)
import Security
#endif
import SpotifyWebAPI

final class PinnedCertificatesDelegate: NSObject, URLSessionDelegate {
    private let pinnedCertificates: Set<Data>

    init(resourceNames: [String]) {
        self.pinnedCertificates = Set(resourceNames.compactMap { name in
            guard
                let url = Bundle.main.url(forResource: name, withExtension: "cer"),
                let data = try? Data(contentsOf: url)
            else { return nil }
            return data
        })
        super.init()
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust,
              let serverCert = SecTrustGetCertificateAtIndex(serverTrust, 0)
        else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        let serverData = SecCertificateCopyData(serverCert) as Data
        if pinnedCertificates.contains(serverData) {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}

let delegate = PinnedCertificatesDelegate(resourceNames: ["spotify-prod"])
var config = URLSessionHTTPClientConfiguration()
config.timeoutIntervalForRequest = 20

let pinnedClient = URLSessionHTTPClient(
    configuration: config,
    sessionFactory: { configuration, queue in
        #if canImport(Security)
        if #available(iOS 13, macOS 10.15, *) {
            configuration.tlsMinimumSupportedProtocolVersion = .TLSv12
        }
        #endif
        return URLSession(configuration: configuration, delegate: delegate, delegateQueue: queue)
    }
)

let client = SpotifyClient.authorizationCode(
    clientID: "...",
    clientSecret: "...",
    redirectURI: URL(string: "myapp://callback")!,
    scopes: [.playlistModifyPublic],
    httpClient: pinnedClient
)
```

Key points:
- The `sessionFactory` closure exposes the `URLSessionConfiguration` that SpotifyWebAPI already tunes (ephemeral cache policy, timeouts). You can further adjust TLS-only knobs before creating the session.
- Keep the delegate out of `URLSessionHTTPClient` so reused Spotify clients share the same pin set.
- Consider shipping multiple pins (primary + backups) to avoid downtime when Spotify rotates certificates.

## Custom Trust Stores or Engines

If you rely on a TLS stack other than URLSession (for example, a `swift-nio` based client, Network.framework's `NWConnection`, or corporate proxies that terminate TLS) you can implement ``HTTPClient`` yourself:

```swift
struct MyHTTPClient: HTTPClient {
    func data(for request: URLRequest) async throws -> HTTPResponse {
        let response = try await tlsEngine.send(request)
        return HTTPResponse(data: response.body, response: response.urlResponse, metrics: nil)
    }
}
```

Inject that client into every `SpotifyClient` you create. This keeps all certificate logic inside your own networking stack while the rest of SpotifyWebAPI remains unchanged.

## Operational Guidance

- Automate monitoring so you know when Spotify's certificates change and whether new pins are required.
- Keep fallback logic ready: if all pins fail, surface a clear error instead of silently retrying.
- Re-run your TLS tests whenever you upgrade SpotifyWebAPI, since HTTP defaults (timeouts, cache policy) may evolve.
