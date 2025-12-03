import Testing
import Foundation
@testable import SpotifyPlaylistFormatter
@testable import SpotifyKit

@Suite("Integration Tests", .tags(.integration))
struct IntegrationTests {
  
  @Test("Full pipeline: parse command, format playlist")
  func fullPipelineFormatting() throws {
    let playlist = createMockPlaylist(name: "Integration Test", trackCount: 3)
    let tracks = createMockTracks(count: 3)
    let formatter = PlaylistFormatter()
    
    let output = formatter.formatPlaylist(playlist, tracks: tracks)
    
    #expect(output.contains("Integration Test"))
    #expect(output.contains("3 tracks"))
    #expect(output.contains("/me now playing..."))
    #expect(output.contains("Track 1"))
    #expect(output.contains("Track 2"))
    #expect(output.contains("Track 3"))
  }
  
  @Test("Full pipeline: unformatted output")
  func fullPipelineUnformatted() throws {
    let playlist = createMockPlaylist(name: "Test", trackCount: 2)
    let tracks = createMockTracks(count: 2)
    let formatter = PlaylistFormatter()
    
    let output = formatter.formatPlaylistUnformatted(playlist, tracks: tracks)
    
    #expect(output.contains("Test"))
    #expect(output.contains("1. Track 1 - Artist 1"))
    #expect(output.contains("2. Track 2 - Artist 2"))
  }
  
  @Test("Command parsing to formatting")
  func commandParsingToFormatting() throws {
    let command = try SpotifyPlaylistFormatterCommand.parse(["https://open.spotify.com/playlist/test"])
    
    #expect(command.playlistURL == "https://open.spotify.com/playlist/test")
    #expect(command.unformatted == false)
    
    let playlist = createMockPlaylist(name: "Test", trackCount: 1)
    let tracks = createMockTracks(count: 1)
    let formatter = PlaylistFormatter()
    
    let output = formatter.formatPlaylist(playlist, tracks: tracks)
    #expect(output.contains("Test"))
  }
  
  @Test("Config loading and validation")
  func configLoadingValidation() throws {
    setenv("SPOTIFY_CLIENT_ID", "integration_test_id", 1)
    setenv("SPOTIFY_REDIRECT_URI", "https://example.com/callback", 1)
    
    let config = try AppConfig.load()
    
    #expect(config.clientID == "integration_test_id")
    #expect(config.redirectURI.absoluteString == "https://example.com/callback")
  }
  
  @Test("Error handling: invalid playlist URL")
  func errorHandlingInvalidURL() {
    let error = SpotifyURIError.invalidFormat("bad-url")
    
    #expect(error.errorDescription?.contains("Invalid Spotify URI") == true)
    #expect(error.errorDescription?.contains("bad-url") == true)
  }
  
  @Test("Playlist sorting integration")
  func playlistSortingIntegration() {
    let playlists = [
      createMockSimplifiedPlaylist(name: "Zebra"),
      createMockSimplifiedPlaylist(name: "Apple"),
      createMockSimplifiedPlaylist(name: "Banana")
    ]
    
    let sorted = playlists.sorted {
      $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
    }
    
    #expect(sorted[0].name == "Apple")
    #expect(sorted[1].name == "Banana")
    #expect(sorted[2].name == "Zebra")
  }
  
  @Test("Duration calculation integration")
  func durationCalculationIntegration() {
    let tracks = createMockTracks(count: 3, durationMs: 60000)
    
    let totalMs = tracks.totalDurationMs
    
    #expect(totalMs == 180000)
  }
  
  @Test("Track extraction from PlaylistTrackItem")
  func trackExtractionIntegration() {
    let tracks = createMockTracks(count: 2)
    
    for track in tracks {
      #expect(track.asTrack != nil)
      #expect(track.asEpisode == nil)
    }
  }
}

extension Tag {
  @Tag static var integration: Self
}
