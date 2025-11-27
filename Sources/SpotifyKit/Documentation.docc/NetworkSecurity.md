# Network Security & TLS Customization

Some deployments must enforce certificate pinning, custom trust stores, or stricter TLS protocol settings than the system defaults. The SpotifyKit package keeps the transport stack swappable so you can inject those policies without forking the library.

## Default Transport

- The built-in ``URLSessionHTTPClient`` uses an ephemeral `URLSession` (no shared caches/cookies) with the platform's default trust evaluation.
- All `SpotifyClient` factory helpers (`pkce`, `authorizationCode`, `clientCredentials`) accept an `httpClient:` argument. If you do not pass one, `URLSessionHTTPClient()` is created for you.
- Provide your own `HTTPClient` to take complete control over TLS behaviour.

## Pinning With URLSession

You can keep using the provided HTTP client while swapping in a custom `URLSession` that performs certificate pinning via a delegate.

```swift
import Foundation
#if canImport(Security)
import Security
#endif
import SpotifyKit

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

// Usage
let sessionConfig = URLSessionConfiguration.ephemeral
let delegate = PinnedCertificatesDelegate(resourceNames: ["spotify-cert"])
let session = URLSession(configuration: sessionConfig, delegate: delegate, delegateQueue: nil)

let client = SpotifyClient(
    configuration: .init(
        clientID: "...",
        clientSecret: "...",
        httpClient: URLSessionHTTPClient(session: session)
    )
)
```

## Custom HTTP Client

For more advanced scenarios (e.g., using a different networking library like AsyncHTTPClient), implement the `HTTPClient` protocol:

```swift
public struct MyCustomClient: HTTPClient {
    public func send(
        _ request: HTTPRequest,
        deadline: DispatchTime?
    ) async throws -> HTTPResponse {
        // Your implementation here
    }
}
```
