import Foundation
import Testing

@testable import SpotifyKit

@Suite struct ExternalContentTests {

  @Test
  func decodesFromRawValue() throws {
    #expect(ExternalContent(rawValue: "audio") == .audio)
    #expect(ExternalContent(rawValue: "invalid") == nil)
  }
}
