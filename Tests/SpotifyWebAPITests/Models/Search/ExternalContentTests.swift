import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct ExternalContentTests {

    @Test
    func hasCorrectRawValue() {
        #expect(ExternalContent.audio.rawValue == "audio")
    }

    @Test
    func equatableWorksCorrectly() {
        #expect(ExternalContent.audio == ExternalContent.audio)
    }

    @Test
    func decodesFromRawValue() throws {
        #expect(ExternalContent(rawValue: "audio") == .audio)
        #expect(ExternalContent(rawValue: "invalid") == nil)
    }
}
