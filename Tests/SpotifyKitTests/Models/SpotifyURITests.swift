import Foundation
import Testing
@testable import SpotifyKit

@Suite("SpotifyURI Tests")
struct SpotifyURITests {
  
  @Test("Parse track URI")
  func parseTrackURI() {
    let uri = SpotifyURI(string: "spotify:track:6rqhFgbbKwnb9MLmUQDhG6")
    
    #expect(uri?.type == .track)
    #expect(uri?.id == "6rqhFgbbKwnb9MLmUQDhG6")
    #expect(uri?.uri == "spotify:track:6rqhFgbbKwnb9MLmUQDhG6")
  }
  
  @Test("Parse playlist URI")
  func parsePlaylistURI() {
    let uri = SpotifyURI(string: "spotify:playlist:37i9dQZF1DXcBWIGoYBM5M")
    
    #expect(uri?.type == .playlist)
    #expect(uri?.id == "37i9dQZF1DXcBWIGoYBM5M")
  }
  
  @Test("Parse album URI")
  func parseAlbumURI() {
    let uri = SpotifyURI(string: "spotify:album:4aawyAB9vmqN3uQ7FjRGTy")
    
    #expect(uri?.type == .album)
    #expect(uri?.id == "4aawyAB9vmqN3uQ7FjRGTy")
  }
  
  @Test("Parse artist URI")
  func parseArtistURI() {
    let uri = SpotifyURI(string: "spotify:artist:0OdUWJ0sBjDrqHygGUXeCF")
    
    #expect(uri?.type == .artist)
    #expect(uri?.id == "0OdUWJ0sBjDrqHygGUXeCF")
  }
  
  @Test("Parse track URL")
  func parseTrackURL() {
    let uri = SpotifyURI(string: "https://open.spotify.com/track/6rqhFgbbKwnb9MLmUQDhG6")
    
    #expect(uri?.type == .track)
    #expect(uri?.id == "6rqhFgbbKwnb9MLmUQDhG6")
  }
  
  @Test("Parse playlist URL")
  func parsePlaylistURL() {
    let uri = SpotifyURI(string: "https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M")
    
    #expect(uri?.type == .playlist)
    #expect(uri?.id == "37i9dQZF1DXcBWIGoYBM5M")
  }
  
  @Test("Parse URL with query parameters")
  func parseURLWithQueryParams() {
    let uri = SpotifyURI(string: "https://open.spotify.com/track/6rqhFgbbKwnb9MLmUQDhG6?si=abc123")
    
    #expect(uri?.type == .track)
    #expect(uri?.id == "6rqhFgbbKwnb9MLmUQDhG6")
  }
  
  @Test("Parse URL without https")
  func parseURLWithoutHTTPS() {
    let uri = SpotifyURI(string: "http://open.spotify.com/track/6rqhFgbbKwnb9MLmUQDhG6")
    
    #expect(uri?.type == .track)
    #expect(uri?.id == "6rqhFgbbKwnb9MLmUQDhG6")
  }
  
  @Test("Parse URL with spotify.com domain")
  func parseSpotifyComDomain() {
    let uri = SpotifyURI(string: "https://spotify.com/track/6rqhFgbbKwnb9MLmUQDhG6")
    
    #expect(uri?.type == .track)
    #expect(uri?.id == "6rqhFgbbKwnb9MLmUQDhG6")
  }
  
  @Test("Parse with whitespace")
  func parseWithWhitespace() {
    let uri = SpotifyURI(string: "  spotify:track:6rqhFgbbKwnb9MLmUQDhG6  ")
    
    #expect(uri?.type == .track)
    #expect(uri?.id == "6rqhFgbbKwnb9MLmUQDhG6")
  }
  
  @Test("Invalid URI returns nil")
  func invalidURIReturnsNil() {
    #expect(SpotifyURI(string: "invalid") == nil)
    #expect(SpotifyURI(string: "spotify:invalid:123") == nil)
    #expect(SpotifyURI(string: "https://google.com/track/123") == nil)
    #expect(SpotifyURI(string: "") == nil)
  }
  
  @Test("Expected type validation")
  func expectedTypeValidation() {
    // Valid type matches
    #expect(SpotifyURI(string: "spotify:track:abc123", expectedType: .track) != nil)
    #expect(SpotifyURI(string: "https://open.spotify.com/playlist/xyz789", expectedType: .playlist) != nil)
    
    // Type mismatch returns nil
    #expect(SpotifyURI(string: "spotify:track:abc123", expectedType: .playlist) == nil)
    #expect(SpotifyURI(string: "https://open.spotify.com/album/xyz789", expectedType: .track) == nil)
    
    // No expected type accepts any valid URI
    #expect(SpotifyURI(string: "spotify:track:abc123", expectedType: nil) != nil)
    #expect(SpotifyURI(string: "spotify:album:xyz789") != nil)
  }
  
  @Test("Convert to URI string")
  func convertToURIString() {
    let uri = SpotifyURI(string: "https://open.spotify.com/track/6rqhFgbbKwnb9MLmUQDhG6")
    
    #expect(uri?.uri == "spotify:track:6rqhFgbbKwnb9MLmUQDhG6")
  }
  
  @Test("Convert to URL")
  func convertToURL() {
    let uri = SpotifyURI(string: "spotify:track:6rqhFgbbKwnb9MLmUQDhG6")
    
    #expect(uri?.url.absoluteString == "https://open.spotify.com/track/6rqhFgbbKwnb9MLmUQDhG6")
  }
  
  @Test("Equatable works")
  func equatableWorks() {
    let uri1 = SpotifyURI(string: "spotify:track:abc123")
    let uri2 = SpotifyURI(string: "https://open.spotify.com/track/abc123")
    let uri3 = SpotifyURI(string: "spotify:track:xyz789")
    
    #expect(uri1 == uri2)
    #expect(uri1 != uri3)
  }
  
  @Test("Hashable works")
  func hashableWorks() {
    let uri1 = SpotifyURI(string: "spotify:track:abc123")
    let uri2 = SpotifyURI(string: "https://open.spotify.com/track/abc123")
    
    var set = Set<SpotifyURI>()
    set.insert(uri1!)
    set.insert(uri2!)
    
    #expect(set.count == 1)
  }
  
  @Test("CustomStringConvertible")
  func customStringConvertible() {
    let uri = SpotifyURI(string: "https://open.spotify.com/track/abc123")
    
    #expect(uri?.description == "spotify:track:abc123")
  }
  
  @Test("Codable encoding")
  func codableEncoding() throws {
    let uri = SpotifyURI(string: "spotify:track:abc123")!
    let encoded = try JSONEncoder().encode(uri)
    let decoded = try JSONDecoder().decode(SpotifyURI.self, from: encoded)
    
    #expect(decoded == uri)
  }
  
  @Test("Codable decoding invalid throws")
  func codableDecodingInvalidThrows() {
    let json = "\"invalid-uri\"".data(using: .utf8)!
    
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(SpotifyURI.self, from: json)
    }
  }
}
