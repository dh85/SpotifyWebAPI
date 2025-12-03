import ArgumentParser
import Foundation

struct SpotifyPlaylistFormatterCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "spotify-playlist-formatter",
    abstract: "Format and display Spotify playlists"
  )
  
  @Argument(
    help: "Spotify playlist URL or URI (optional - will prompt for selection if not provided)"
  )
  var playlistURL: String?
  
  @Flag(name: .shortAndLong, help: "Display unformatted output")
  var unformatted = false
}
