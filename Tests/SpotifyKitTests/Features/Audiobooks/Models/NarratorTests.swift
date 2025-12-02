import Foundation
import Testing

@testable import SpotifyKit

@Suite struct NarratorTests {

  @Test
  func supportsCodableRoundTrip() throws {
    let narrator = Narrator(name: "Sample Narrator")
    try expectCodableRoundTrip(narrator)
  }
}
