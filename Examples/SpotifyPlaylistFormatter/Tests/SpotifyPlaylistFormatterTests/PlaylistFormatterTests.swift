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
    #expect(output.contains("/me now playing..."))
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
    #expect(output.contains("0 tracks"))
  }
  
  @Test("Format playlist contains ANSI colors")
  func formatPlaylistColors() {
    let playlist = createMockPlaylist(name: "Colorful", trackCount: 1)
    let tracks = createMockTracks(count: 1)
    
    let output = formatter.formatPlaylist(playlist, tracks: tracks)
    
    #expect(output.contains(Color.cyan))
    #expect(output.contains(Color.green))
    #expect(output.contains(Color.yellow))
    #expect(output.contains(Color.reset))
  }
  
  @Test("Format playlist shows track count")
  func formatPlaylistTrackCount() {
    let playlist = createMockPlaylist(name: "Test", trackCount: 5)
    let tracks = createMockTracks(count: 5)
    
    let output = formatter.formatPlaylist(playlist, tracks: tracks)
    
    #expect(output.contains("5 tracks"))
  }
  
  @Test("Format duration zero seconds")
  func formatDurationZero() {
    let playlist = createMockPlaylist(name: "Test", trackCount: 0)
    let output = formatter.formatPlaylist(playlist, tracks: [])
    
    #expect(!output.contains("⏱️"))
  }
  
  @Test("Format duration only seconds")
  func formatDurationSeconds() {
    let playlist = createMockPlaylist(name: "Test", trackCount: 1)
    let tracks = createMockTracks(count: 1, durationMs: 45000)
    
    let output = formatter.formatPlaylist(playlist, tracks: tracks)
    
    #expect(output.contains("45 sec"))
  }
  
  @Test("Format duration minutes and seconds")
  func formatDurationMinutesSeconds() {
    let playlist = createMockPlaylist(name: "Test", trackCount: 1)
    let tracks = createMockTracks(count: 1, durationMs: 125000)
    
    let output = formatter.formatPlaylist(playlist, tracks: tracks)
    
    #expect(output.contains("2 min, 5 sec"))
  }
  
  @Test("Format duration hours minutes seconds")
  func formatDurationHoursMinutesSeconds() {
    let playlist = createMockPlaylist(name: "Test", trackCount: 1)
    let tracks = createMockTracks(count: 1, durationMs: 3665000)
    
    let output = formatter.formatPlaylist(playlist, tracks: tracks)
    
    #expect(output.contains("1 hr, 1 min, 5 sec"))
  }
  
  @Test("Format duration exact hours")
  func formatDurationExactHours() {
    let playlist = createMockPlaylist(name: "Test", trackCount: 1)
    let tracks = createMockTracks(count: 1, durationMs: 7200000)
    
    let output = formatter.formatPlaylist(playlist, tracks: tracks)
    
    #expect(output.contains("2 hr"))
  }
  
  @Test("PlaylistFormatter is Sendable")
  func playlistFormatterIsSendable() {
    Task {
      let _ = formatter
    }
  }
}
