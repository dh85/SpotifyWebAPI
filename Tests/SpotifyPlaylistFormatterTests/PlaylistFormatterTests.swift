import Testing
import Foundation
@testable import SpotifyPlaylistFormatter
@testable import SpotifyKit

@Suite("PlaylistFormatter Tests")
struct PlaylistFormatterTests {
  let formatter = PlaylistFormatter()
  
  @Test("Format playlist with tracks")
  func formatPlaylist() {
    let playlist = createMockPlaylist(name: "Test Playlist", trackCount: 2)
    let tracks = createMockTracks(count: 2)
    
    let output = formatter.formatPlaylist(playlist, tracks: tracks)
    
    #expect(output.contains("Test Playlist"))
    #expect(output.contains("Track 1"))
    #expect(output.contains("Artist 1"))
    #expect(output.contains("Track 2"))
  }
  
  @Test("Format playlist unformatted")
  func formatPlaylistUnformatted() {
    let playlist = createMockPlaylist(name: "Test Playlist", trackCount: 2)
    let tracks = createMockTracks(count: 2)
    
    let output = formatter.formatPlaylistUnformatted(playlist, tracks: tracks)
    
    #expect(output.contains("Test Playlist"))
    #expect(output.contains("1. Track 1 - Artist 1"))
    #expect(output.contains("2. Track 2 - Artist 2"))
  }
  
  @Test("Format empty playlist")
  func formatEmptyPlaylist() {
    let playlist = createMockPlaylist(name: "Empty", trackCount: 0)
    let tracks: [PlaylistTrackItem] = []
    
    let output = formatter.formatPlaylist(playlist, tracks: tracks)
    
    #expect(output.contains("Empty"))
    #expect(output.contains("Total Tracks: 0"))
  }
}
