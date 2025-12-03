import Foundation
import SpotifyKit

struct PlaylistFormatter: Sendable {
  func formatPlaylist(_ playlist: Playlist, tracks: [PlaylistTrackItem]) -> String {
    var output = """
    ╔══════════════════════════════════════════════════════════════════════╗
    ║  \(centerPad(playlist.name, width: 66))  ║
    ╠══════════════════════════════════════════════════════════════════════╣
    
    """
    
    if let description = playlist.description, !description.isEmpty {
      output += "  \(description)\n\n"
    }
    
    output += "  Total Tracks: \(tracks.count)\n"
    if let owner = playlist.owner {
      output += "  Owner: \(owner.displayName ?? owner.id)\n\n"
    }
    output += "╠══════════════════════════════════════════════════════════════════════╣\n\n"
    
    for (index, item) in tracks.enumerated() {
      guard let playlistTrack = item.track,
            case .track(let track) = playlistTrack else { continue }
      
      let number = String(format: "%3d", index + 1)
      let artists = track.artistNames ?? "Unknown Artist"
      let duration = track.durationFormatted ?? "0:00"
      
      output += "  \(number). \(track.name)\n"
      output += "       \(artists) • \(duration)\n"
      
      if let album = track.album?.name {
        output += "       Album: \(album)\n"
      }
      
      output += "\n"
    }
    
    output += "╚══════════════════════════════════════════════════════════════════════╝"
    return output
  }
  
  func formatPlaylistUnformatted(_ playlist: Playlist, tracks: [PlaylistTrackItem]) -> String {
    var output = "\(playlist.name)\n"
    
    for (index, item) in tracks.enumerated() {
      guard let playlistTrack = item.track,
            case .track(let track) = playlistTrack else { continue }
      output += "\(index + 1). \(track.name) - \(track.artistNames ?? "Unknown Artist")\n"
    }
    
    return output
  }
  
  private func centerPad(_ text: String, width: Int) -> String {
    let padding = max(0, width - text.count)
    let leftPad = padding / 2
    let rightPad = padding - leftPad
    return String(repeating: " ", count: leftPad) + text + String(repeating: " ", count: rightPad)
  }
}
