import Testing
import ArgumentParser
@testable import SpotifyPlaylistFormatter

@Suite("CommandLineParser Tests")
struct CommandLineParserTests {
  
  @Test("Parse no arguments")
  func parseNoArguments() throws {
    let command = try SpotifyPlaylistFormatterCommand.parse([])
    
    #expect(command.playlistURL == nil)
    #expect(command.unformatted == false)
  }
  
  @Test("Parse playlist URL")
  func parsePlaylistURL() throws {
    let url = "https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M"
    let command = try SpotifyPlaylistFormatterCommand.parse([url])
    
    #expect(command.playlistURL == url)
    #expect(command.unformatted == false)
  }
  
  @Test("Parse unformatted flag short")
  func parseUnformattedShort() throws {
    let command = try SpotifyPlaylistFormatterCommand.parse(["-u"])
    
    #expect(command.playlistURL == nil)
    #expect(command.unformatted == true)
  }
  
  @Test("Parse unformatted flag long")
  func parseUnformattedLong() throws {
    let command = try SpotifyPlaylistFormatterCommand.parse(["--unformatted"])
    
    #expect(command.playlistURL == nil)
    #expect(command.unformatted == true)
  }
  
  @Test("Parse URL and unformatted flag")
  func parseURLAndFlag() throws {
    let url = "spotify:playlist:37i9dQZF1DXcBWIGoYBM5M"
    let command = try SpotifyPlaylistFormatterCommand.parse([url, "-u"])
    
    #expect(command.playlistURL == url)
    #expect(command.unformatted == true)
  }
  
  @Test("Parse URL and long flag")
  func parseURLAndLongFlag() throws {
    let url = "https://open.spotify.com/playlist/test"
    let command = try SpotifyPlaylistFormatterCommand.parse([url, "--unformatted"])
    
    #expect(command.playlistURL == url)
    #expect(command.unformatted == true)
  }
}
