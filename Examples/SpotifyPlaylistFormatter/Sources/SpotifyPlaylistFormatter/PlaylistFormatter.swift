import Foundation
import SpotifyKit

enum Color {
  static let green = "\u{001B}[32m"
  static let cyan = "\u{001B}[36m"
  static let yellow = "\u{001B}[33m"
  static let magenta = "\u{001B}[35m"
  static let bold = "\u{001B}[1m"
  static let reset = "\u{001B}[0m"
}

let boxWidth = 70

struct PlaylistFormatter: Sendable {
  func formatPlaylist(_ playlist: Playlist, tracks: [PlaylistTrackItem]) -> String {
    var output = ""

    // Header

    output += "\n\(Color.cyan)\(String(repeating: "─", count: boxWidth))\(Color.reset)\n"

    let titleLine = "\(Color.bold)\(Color.green)\(playlist.name)\(Color.reset)"

    output +=
      "\(Color.cyan)\(Color.reset) \(titleLine)\(Color.reset)\n"

    let totalMs = tracks.totalDurationMs
    var metaLine = "\(Color.yellow)📊 \(tracks.count) tracks\(Color.reset)"
    var metaPlainLength = "📊 \(tracks.count) tracks".count

    if totalMs > 0 {
      let duration = formatDuration(totalMs)
      metaLine += " \(Color.yellow)⏱️  \(duration)\(Color.reset)"
      metaPlainLength += " ⏱️  \(duration)".count
    }

    output +=
      "\(Color.cyan)\(Color.reset) \(metaLine)\(Color.reset)\n"
    output += "\(Color.cyan)\(String(repeating: "─", count: boxWidth))\(Color.reset)\n\n"

    // Track list
    for item in tracks {
      guard let track = item.asTrack else { continue }
      let artists = track.artistNames ?? "Unknown Artist"
      output += "/me now playing... \(artists) - \(track.name)\n"
    }
    return output
  }

  func formatPlaylistUnformatted(_ playlist: Playlist, tracks: [PlaylistTrackItem]) -> String {
    var output = "\(playlist.name)\n"

    for (index, item) in tracks.enumerated() {
      guard let track = item.asTrack else { continue }
      output += "\(index + 1). \(track.name) - \(track.artistNames ?? "Unknown Artist")\n"
    }

    return output
  }

  private func formatDuration(_ milliseconds: Int) -> String {
    let totalSeconds = milliseconds / 1000
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    let seconds = totalSeconds % 60

    var parts: [String] = []
    if hours > 0 {
      parts.append("\(hours) hr")
    }
    if minutes > 0 {
      parts.append("\(minutes) min")
    }
    if seconds > 0 || parts.isEmpty {
      parts.append("\(seconds) sec")
    }

    return parts.joined(separator: ", ")
  }
}
