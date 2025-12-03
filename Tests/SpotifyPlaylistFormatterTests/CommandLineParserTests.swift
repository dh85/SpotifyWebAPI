import Testing
@testable import SpotifyPlaylistFormatter

@Suite("CommandLineParser Tests")
struct CommandLineParserTests {
  
  @Test("Parse no arguments")
  func parseNoArguments() {
    let args = CommandLineParser.parse(["program"])
    
    #expect(args.playlistURL == nil)
    #expect(args.unformatted == false)
  }
  
  @Test("Parse unformatted flag short")
  func parseUnformattedShort() {
    let args = CommandLineParser.parse(["program", "-u"])
    
    #expect(args.unformatted == true)
  }
  
  @Test("Parse unformatted flag long")
  func parseUnformattedLong() {
    let args = CommandLineParser.parse(["program", "--unformatted"])
    
    #expect(args.unformatted == true)
  }
  
  @Test("Parse playlist URL")
  func parsePlaylistURL() {
    let url = "https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M"
    let args = CommandLineParser.parse(["program", url])
    
    #expect(args.playlistURL == url)
  }
  
  @Test("Parse playlist URI")
  func parsePlaylistURI() {
    let uri = "spotify:playlist:37i9dQZF1DXcBWIGoYBM5M"
    let args = CommandLineParser.parse(["program", uri])
    
    #expect(args.playlistURL == uri)
  }
  
  @Test("Parse URL and unformatted flag")
  func parseURLAndFlag() {
    let url = "https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M"
    let args = CommandLineParser.parse(["program", url, "-u"])
    
    #expect(args.playlistURL == url)
    #expect(args.unformatted == true)
  }
}
