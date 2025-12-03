import Foundation
import SpotifyKit

struct ConsoleUI: Sendable {
  func print(_ message: String, terminator: String = "\n") {
    Swift.print(message, terminator: terminator)
  }

  func printWelcome() {
    print("\n\(Color.cyan)\(String(repeating: "─", count: boxWidth))\(Color.reset)")
    print("  \(Color.bold)\(Color.green)Welcome to Spotify Playlist Formatter \(Color.reset) ")
    print("\(Color.cyan)\(String(repeating: "─", count: boxWidth))\(Color.reset)")
  }

  func printError(_ error: Error) {
    var stderr = StandardError()
    Swift.print("Error: \(error.localizedDescription)", to: &stderr)
  }

  func displayPlaylistList(_ playlists: [SimplifiedPlaylist]) {
    print("\n📋 Your Playlists:\n")
    for (index, playlist) in playlists.enumerated() {
      print(String(format: "  %3d. %@", index + 1, playlist.name))
    }
    print("")
  }

  func promptSelection(max: Int) -> Int? {
    Swift.print("Select a playlist (1-\(max)): ", terminator: "")
    guard let input = readLine(), let selection = Int(input), selection >= 1, selection <= max
    else {
      return nil
    }
    return selection
  }
}

struct StandardError: TextOutputStream {
  mutating func write(_ string: String) {
    FileHandle.standardError.write(Data(string.utf8))
  }
}
