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

  func run(command: SpotifyPlaylistFormatterCommand) async {
    do {
      let config = try AppConfig.load()

      ui.printWelcome()

      let client = try await UserSpotifyClient.authenticateCLI(
        clientID: config.clientID,
        redirectURI: config.redirectURI,
        scopes: [.playlistReadPrivate, .playlistReadCollaborative, .userLibraryRead]
      )

      ui.print("\n✓ Authentication successful\n")

      if let playlistURL = command.playlistURL {
        let playlistID = try extractPlaylistID(from: playlistURL)
        try await formatPlaylist(
          client: client, playlistID: playlistID, formatted: !command.unformatted)
      } else {
        try await interactiveMode(client: client, formatted: !command.unformatted)
      }
    } catch {
      ui.printError(error)
      exit(1)
    }
  }

  private func interactiveMode(client: UserSpotifyClient, formatted: Bool) async throws {
    let user = try await client.users.me()
    ui.print("Logged in as: \(user.displayName ?? user.id)")

    ui.print("Fetching your playlists...")
    let playlists = try await client.playlists.getAllMyPlaylists()

    guard !playlists.isEmpty else {
      ui.print("No playlists found.")
      return
    }

    let sortedPlaylists = playlists.sorted {
      $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
    }
    ui.displayPlaylistList(sortedPlaylists)

    guard let selection = ui.promptSelection(max: sortedPlaylists.count) else {
      ui.print("Invalid selection")
      return
    }

    try await formatPlaylist(client: client, playlistID: sortedPlaylists[selection - 1].id, formatted: formatted)
  }

  private func formatPlaylist(client: UserSpotifyClient, playlistID: String, formatted: Bool)
    async throws
  {
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
    let uri = try SpotifyURI(validating: url, expectedType: .playlist)
    return uri.id
  }

}


