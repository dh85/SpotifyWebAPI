import Foundation
import SpotifyKit

actor PlaylistFormatterApp {
  private let formatter: PlaylistFormatter
  private let ui: ConsoleUI
  
  init(
    formatter: PlaylistFormatter = .init(),
    ui: ConsoleUI = .init()
  ) {
    self.formatter = formatter
    self.ui = ui
  }
  
  func run() async {
    do {
      let config = try AppConfig.load()
      let auth = AuthManager(config: config)
      
      let args = CommandLineParser.parse(CommandLine.arguments)
      let client = try await auth.getClient()
      
      if let playlistURL = args.playlistURL {
        let playlistID = try extractPlaylistID(from: playlistURL)
        try await formatPlaylist(client: client, playlistID: playlistID, formatted: !args.unformatted)
      } else {
        try await interactiveMode(client: client, formatted: !args.unformatted)
      }
    } catch {
      ui.printError(error)
      exit(1)
    }
  }
  
  private func interactiveMode(client: UserSpotifyClient, formatted: Bool) async throws {
    ui.print("Fetching your playlists...")
    
    var playlists: [SimplifiedPlaylist] = []
    for try await playlist in client.playlists.streamMyPlaylists() {
      playlists.append(playlist)
    }
    
    let grouped = groupPlaylists(playlists)
    ui.displayPlaylistList(grouped)
    
    guard let selection = ui.promptSelection(max: playlists.count) else {
      ui.print("Invalid selection")
      return
    }
    
    let selectedPlaylist = playlists[selection - 1]
    try await formatPlaylist(client: client, playlistID: selectedPlaylist.id, formatted: formatted)
  }
  
  private func formatPlaylist(client: UserSpotifyClient, playlistID: String, formatted: Bool) async throws {
    let playlist = try await client.playlists.get(playlistID)
    
    var tracks: [PlaylistTrackItem] = []
    for try await item in client.playlists.streamItems(playlistID) {
      tracks.append(item)
    }
    
    if formatted {
      ui.print(formatter.formatPlaylist(playlist, tracks: tracks))
    } else {
      ui.print(formatter.formatPlaylistUnformatted(playlist, tracks: tracks))
    }
  }
  
  private func extractPlaylistID(from url: String) throws -> String {
    guard let uri = SpotifyURI(string: url, expectedType: .playlist) else {
      throw AppError.invalidPlaylistURL(url)
    }
    return uri.id
  }
  
  private func groupPlaylists(_ playlists: [SimplifiedPlaylist]) -> [PlaylistGroup] {
    let sorted = playlists.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    return [PlaylistGroup(name: nil, playlists: sorted)]
  }
}

struct PlaylistGroup {
  let name: String?
  let playlists: [SimplifiedPlaylist]
}

enum AppError: LocalizedError {
  case invalidPlaylistURL(String)
  
  var errorDescription: String? {
    switch self {
    case .invalidPlaylistURL(let url):
      return "Invalid playlist URL: \(url)"
    }
  }
}
