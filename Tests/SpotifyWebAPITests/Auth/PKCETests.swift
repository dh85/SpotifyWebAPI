import Foundation
import Testing

@testable import SpotifyWebAPI

// MARK: - Test-only PKCEProvider implementation

private struct DummyPKCEProvider: PKCEProvider {
    let pair: PKCEPair

    func generatePKCE() throws -> PKCEPair {
        pair
    }

    /// Convenience helper so the test reads nicely.
    static func forTests() -> (expected: PKCEPair, provider: PKCEProvider) {
        let expected = PKCEPair(
            verifier: "v",
            challenge: "c",
            state: "s"
        )
        let provider: PKCEProvider = DummyPKCEProvider(pair: expected)
        return (expected, provider)
    }
}

@Suite
struct PKCETests {

    // MARK: - makeCodeChallenge / RFC 7636

    @Test
    func codeChallengeMatchesRFC7636Vector() throws {
        let verifier = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"

        let challenge = DefaultPKCEProvider.codeChallenge(
            forTestingVerifier: verifier
        )

        #expect(challenge == "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM")
    }

    // MARK: - generatePKCE()

    @Test
    func generatePKCEProducesValidLengthsAndCharacters() throws {
        let provider = DefaultPKCEProvider()
        let pkce = try provider.generatePKCE()

        #expect(pkce.verifier.count == 64)
        #expect(pkce.state.count == 32)

        let allowedVerifierChars = CharacterSet(
            charactersIn:
                "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"
        )
        #expect(
            pkce.verifier.unicodeScalars.allSatisfy {
                allowedVerifierChars.contains($0)
            }
        )

        let allowedChallengeChars = CharacterSet(
            charactersIn:
                "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_"
        )
        #expect(pkce.challenge.count > 0)
        #expect(
            pkce.challenge.unicodeScalars.allSatisfy {
                allowedChallengeChars.contains($0)
            }
        )
    }

    @Test
    func generatePKCEProducesDifferentValuesEachTime() throws {
        let provider = DefaultPKCEProvider()

        let first = try provider.generatePKCE()
        let second = try provider.generatePKCE()

        #expect(first != second)
    }

    // MARK: - PKCEPair Equatable

    @Test
    func pkcePairEquatableConformance() {
        let a = PKCEPair(
            verifier: "verifier",
            challenge: "challenge",
            state: "state"
        )
        let b = PKCEPair(
            verifier: "verifier",
            challenge: "challenge",
            state: "state"
        )
        let c = PKCEPair(
            verifier: "other-verifier",
            challenge: "challenge",
            state: "state"
        )

        #expect(a == b)
        #expect(a != c)
    }

    // MARK: - PKCEProvider protocol

    @Test
    func pkceProviderProtocolIsUsableWithCustomImplementation() throws {
        let (expected, provider) = DummyPKCEProvider.forTests()
        let result = try provider.generatePKCE()
        #expect(result == expected)
    }

    // MARK: - PKCEError

    @Test
    func pkceErrorEquatable() {
        let error1 = PKCEError.randomFailure
        let error2 = PKCEError.randomFailure
        #expect(error1 == error2)
    }
}
