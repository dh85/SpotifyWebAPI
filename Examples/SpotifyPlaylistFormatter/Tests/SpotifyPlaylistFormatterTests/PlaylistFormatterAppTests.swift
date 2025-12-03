import Testing
import Foundation
@testable import SpotifyPlaylistFormatter
@testable import SpotifyKit

@Suite("PlaylistFormatterApp Tests")
struct PlaylistFormatterAppTests {
  
  @Test("SpotifyURIError invalidFormat description")
  func spotifyURIErrorInvalidFormat() {
    let error = SpotifyURIError.invalidFormat("bad-url")
    
    #expect(error.errorDescription?.contains("Invalid Spotify URI") == true)
    #expect(error.errorDescription?.contains("bad-url") == true)
  }
  
  @Test("SpotifyURIError wrongType description")
  func spotifyURIErrorWrongType() {
    let error = SpotifyURIError.wrongType(expected: .playlist, actual: .track)
    
    #expect(error.errorDescription?.contains("Expected playlist") == true)
    #expect(error.errorDescription?.contains("got track") == true)
  }
}
