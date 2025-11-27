# Network Security & TLS Customization

Some deployments must enforce certificate pinning, custom trust stores, or stricter TLS protocol settings than the system defaults. The SpotifyKit package keeps the transport stack swappable so you can inject those policies without forking the library.

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
- The `sessionFactory` closure exposes the `URLSessionConfiguration` that SpotifyKit already tunes (ephemeral cache policy, timeouts). You can further adjust TLS-only knobs before creating the session.
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

Inject that client into every `SpotifyClient` you create. This keeps all certificate logic inside your own networking stack while the rest of SpotifyKit remains unchanged.

### Pinning on Linux/Windows (No `Security` Framework)

Platforms such as Linux do not expose `Security`/`SecTrust`, so `URLSessionHTTPClient.makePinnedSession` is unavailable. Instead, pin at the TLS-engine layer and expose it via a custom ``HTTPClient``:

```swift
#if canImport(NIOSSL)
import NIO
import NIOHTTP1
import NIOSSL
#endif

struct NIOPinnedHTTPClient: HTTPClient {
    private let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    private let pinnedFingerprints: Set<String>

    init(pemFiles: [String]) throws {
        pinnedFingerprints = try Set(pemFiles.map { path in
            let cert = try NIOSSLCertificate(file: path, format: .pem)
            return SHA256.hash(data: Data(cert.toDERBytes())).hexString
        })
    }

    func data(for request: URLRequest) async throws -> HTTPResponse {
        let bootstrap = ClientBootstrap(group: eventLoopGroup)
            .channelInitializer { channel in
                let sslContext = try! NIOSSLContext(configuration: .makeClientConfiguration())
                let handler = try! NIOSSLClientHandler(context: sslContext, serverHostname: request.url?.host)
                return channel.pipeline.addHandler(handler).flatMap {
                    channel.pipeline.addHandler(PinnedCertificateHandler(pins: pinnedFingerprints))
                }
            }
        // Issue request using swift-nio + HTTP1 handlers (omitted for brevity)
        fatalError("Implement request/response bridging here")
    }
}

final class PinnedCertificateHandler: ChannelInboundHandler {
    typealias InboundIn = NIOAny
    private let pins: Set<String>

    init(pins: Set<String>) { self.pins = pins }

    func userInboundEventTriggered(context: ChannelHandlerContext, event: Any) {
        if case let tlsEvent as TLSUserEvent = event,
           case let .handshakeCompleted(negotiatedProtocol, peerCertificate, _, _) = tlsEvent {
            let fingerprint = SHA256.hash(data: Data(peerCertificate.toDERBytes())).hexString
            guard pins.contains(fingerprint) else {
                context.close(promise: nil)
                return
            }
        }
        context.fireUserInboundEventTriggered(event)
    }
}
```

Key takeaways:
- Perform pin validation inside your networking stack (swift-nio shown here) and fail the connection before any HTTP bytes flow if the cert/fingerprint is not trusted.
- Use certificate DER hashes or public-key hashes and ship multiple pins for rotation.
- Wrap the custom client in the ``HTTPClient`` protocol so `SpotifyClient` can continue operating without changes.

## Operational Guidance

- Re-run your TLS tests whenever you upgrade SpotifyKit, since HTTP defaults (timeouts, cache policy) may evolve.
