import CryptoKit
import Foundation
import Security

/// A PKCE verifier/challenge + CSRF state value.
public struct PKCEPair: Sendable, Equatable {
    public let verifier: String
    public let challenge: String
    public let state: String
}

/// Protocol for types that can generate PKCE verifier/challenge pairs.
public protocol PKCEProvider: Sendable {
    func generatePKCE() throws -> PKCEPair
}

/// Errors that can occur during PKCE generation.
public enum PKCEError: Error, Sendable {
    case randomFailure
}

/// Default PKCE provider using secure random bytes and SHA-256.
public struct DefaultPKCEProvider: PKCEProvider {
    public init() {}

    public func generatePKCE() throws -> PKCEPair {
        let verifier = try Self.randomString(length: 64)
        let challenge = Self.makeCodeChallenge(for: verifier)
        let state = try Self.randomString(length: 32)
        return PKCEPair(verifier: verifier, challenge: challenge, state: state)
    }

    // MARK: - Internal helpers

    private static func randomString(length: Int) throws -> String {
        let allowed = Array(
            "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"
        )
        var bytes = [UInt8](repeating: 0, count: length)

        let status = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        guard status == errSecSuccess else {
            throw PKCEError.randomFailure
        }

        let chars = bytes.map { allowed[Int($0) % allowed.count] }
        return String(chars)
    }

    static func makeCodeChallenge(for verifier: String) -> String {
        let data = Data(verifier.utf8)
        let hash = SHA256.hash(data: data)
        let hashData = Data(hash)

        let base64 = hashData.base64EncodedString()
        return
            base64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

#if DEBUG
    extension DefaultPKCEProvider {
        /// Exposed for tests to verify against RFC 7636 example vectors.
        public static func codeChallenge(forTestingVerifier verifier: String)
            -> String
        {
            makeCodeChallenge(for: verifier)
        }
    }
#endif
