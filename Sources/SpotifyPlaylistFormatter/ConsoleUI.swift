import Foundation
import SpotifyKit

struct ConsoleUI: Sendable {
  func print(_ message: String) {
    Swift.print(message)
  }
  
  func printError(_ error: Error) {
    var stderr = StandardError()
    Swift.print("Error: \(error.localizedDescription)", to: &stderr)
  }
  
  func displayPlaylistList(_ groups: [PlaylistGroup]) {
    print("\n📋 Your Playlists:\n")
    
    var index = 1
    for group in groups {
      if let groupName = group.name {
        print("  \(groupName)")
        print("  " + String(repeating: "─", count: groupName.count))
      }
      
      for playlist in group.playlists {
        let trackCount = playlist.tracks?.total ?? 0
        print(String(format: "  %3d. %-50s (%d tracks)", index, playlist.name, trackCount))
        index += 1
      }
      print("")
    }
  }
  
  func promptSelection(max: Int) -> Int? {
    Swift.print("Select a playlist (1-\(max)): ", terminator: "")
    guard let input = readLine(), let selection = Int(input), selection >= 1, selection <= max else {
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
