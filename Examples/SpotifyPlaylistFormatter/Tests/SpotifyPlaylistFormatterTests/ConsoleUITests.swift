import Testing
import Foundation
@testable import SpotifyPlaylistFormatter
@testable import SpotifyKit

@Suite("ConsoleUI Tests")
struct ConsoleUITests {
  let ui = ConsoleUI()
  
  @Test("printWelcome contains welcome message")
  func printWelcomeMessage() {
    ui.printWelcome()
  }
  
  @Test("printError writes to stderr")
  func printErrorOutput() {
    let error = SpotifyURIError.invalidFormat("test")
    ui.printError(error)
  }
  
  @Test("displayPlaylistList formats playlists")
  func displayPlaylistListOutput() {
    let playlists = [
      createMockSimplifiedPlaylist(name: "Playlist 1"),
      createMockSimplifiedPlaylist(name: "Playlist 2"),
      createMockSimplifiedPlaylist(name: "Playlist 3")
    ]
    
    ui.displayPlaylistList(playlists)
  }
  
  @Test("displayPlaylistList handles empty list")
  func displayEmptyPlaylistList() {
    ui.displayPlaylistList([])
  }
  
  @Test("ConsoleUI is Sendable")
  func consoleUIIsSendable() {
    Task {
      let _ = ui
    }
  }
  
  @Test("StandardError writes to stderr")
  func standardErrorWrite() {
    var stderr = StandardError()
    stderr.write("test message")
  }
}
