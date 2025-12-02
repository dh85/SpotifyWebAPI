import ArgumentParser
import Foundation
import SpotifyKit

@main
struct SpotifyCLI: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "spotify-cli",
    abstract: "A command-line interface for the Spotify Web API",
    version: "1.0.0",
    subcommands: [
      Profile.self,
      Search.self,
      Playlists.self,
      TopItems.self,
      Player.self,
      Album.self,
      Artist.self,
      Track.self,
    ]
  )
}

// MARK: - Shared Client

/// Shared Spotify client instance
@MainActor
class SpotifyClientHolder {
  static let shared = SpotifyClientHolder()

  var client: SpotifyClient<UserAuthCapability>?

  private init() {}

  func getClient() throws -> SpotifyClient<UserAuthCapability> {
    if let client = client {
      return client
    }

    // Load credentials from environment
    guard let clientID = ProcessInfo.processInfo.environment["SPOTIFY_CLIENT_ID"] else {
      throw ValidationError("SPOTIFY_CLIENT_ID environment variable not set")
    }

    guard let clientSecret = ProcessInfo.processInfo.environment["SPOTIFY_CLIENT_SECRET"] else {
      throw ValidationError("SPOTIFY_CLIENT_SECRET environment variable not set")
    }

    guard let redirectURIString = ProcessInfo.processInfo.environment["SPOTIFY_REDIRECT_URI"],
      let redirectURI = URL(string: redirectURIString)
    else {
      throw ValidationError("SPOTIFY_REDIRECT_URI environment variable not set or invalid")
    }

    let newClient = UserSpotifyClient.authorizationCode(
      clientID: clientID,
      clientSecret: clientSecret,
      redirectURI: redirectURI,
      scopes: [
        .userReadPrivate,
        .userReadEmail,
        .playlistReadPrivate,
        .playlistReadCollaborative,
        .userLibraryRead,
        .userTopRead,
        .userReadRecentlyPlayed,
        .userReadPlaybackState,
        .userModifyPlaybackState,
      ]
    )

    self.client = newClient
    return newClient
  }
}

// MARK: - Profile Command

struct Profile: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Get the current user's profile information"
  )

  func run() async throws {
    let client = try await SpotifyClientHolder.shared.getClient()
    let profile = try await client.users.me()

    print("🎵 Spotify Profile")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("ID:           \(profile.id)")
    print("Display Name: \(profile.displayName ?? "N/A")")
    print("Email:        \(profile.email ?? "N/A")")
    print("Country:      \(profile.country ?? "N/A")")
    print("Product:      \(profile.product ?? "N/A")")
    print("Followers:    \(profile.followers.total)")
    print("URI:          \(profile.uri)")
  }
}

// MARK: - Search Command

struct Search: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Search for tracks, artists, albums, or playlists"
  )

  @Argument(help: "Search query")
  var query: String

  @Option(name: .shortAndLong, help: "Type to search (track, artist, album, playlist)")
  var type: String = "track"

  @Option(name: .shortAndLong, help: "Maximum number of results")
  var limit: Int = 10

  func run() async throws {
    let client = try await SpotifyClientHolder.shared.getClient()

    let searchType: SearchType
    switch type.lowercased() {
    case "track": searchType = .track
    case "artist": searchType = .artist
    case "album": searchType = .album
    case "playlist": searchType = .playlist
    default:
      throw ValidationError("Invalid type. Use: track, artist, album, or playlist")
    }

    let results = try await client.search
      .query(query)
      .forTypes([searchType])
      .withLimit(limit)
      .execute()

    print("🔍 Search Results: '\(query)'")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

    if let tracks = results.tracks?.items {
      print("\n📀 Tracks:")
      for (index, track) in tracks.enumerated() {
        let artists = track.artists?.map { $0.name }.joined(separator: ", ") ?? "Unknown"
        print("\(index + 1). \(track.name) - \(artists)")
        if let album = track.album?.name {
          print("   Album: \(album)")
        }
      }
    }

    if let artists = results.artists?.items {
      print("\n👤 Artists:")
      for (index, artist) in artists.enumerated() {
        print("\(index + 1). \(artist.name)")
        if let genres = artist.genres, !genres.isEmpty {
          print("   Genres: \(genres.joined(separator: ", "))")
        }
        if let popularity = artist.popularity {
          print("   Popularity: \(popularity)/100")
        }
      }
    }

    if let albums = results.albums?.items {
      print("\n💿 Albums:")
      for (index, album) in albums.enumerated() {
        let artists = album.artists?.map { $0.name }.joined(separator: ", ") ?? "Unknown"
        print("\(index + 1). \(album.name) - \(artists)")
        if let date = album.releaseDate {
          print("   Released: \(date)")
        }
      }
    }

    if let playlists = results.playlists?.items {
      print("\n📝 Playlists:")
      for (index, playlist) in playlists.enumerated() {
        print("\(index + 1). \(playlist.name)")
        if let owner = playlist.owner?.displayName {
          print("   By: \(owner)")
        }
        if let total = playlist.tracks?.total {
          print("   Tracks: \(total)")
        }
      }
    }
  }
}

// MARK: - Playlists Command

struct Playlists: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "List the current user's playlists"
  )

  @Option(name: .shortAndLong, help: "Maximum number of playlists to fetch")
  var limit: Int = 20

  func run() async throws {
    let client = try await SpotifyClientHolder.shared.getClient()
    let page = try await client.playlists.myPlaylists(limit: limit)

    print("📝 Your Playlists (\(page.items.count) of \(page.total))")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

    for (index, playlist) in page.items.enumerated() {
      print("\n\(index + 1). \(playlist.name)")
      print("   ID: \(playlist.id)")
      if let description = playlist.description, !description.isEmpty {
        print("   Description: \(description)")
      }
      if let owner = playlist.owner?.displayName {
        print("   Owner: \(owner)")
      }
      if let total = playlist.tracks?.total {
        print("   Tracks: \(total)")
      }
      print("   Public: \(playlist.isPublic ?? false ? "Yes" : "No")")
    }
  }
}

// MARK: - Top Items Command

struct TopItems: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Get your top artists or tracks"
  )

  @Option(name: .shortAndLong, help: "Type (artists or tracks)")
  var type: String = "tracks"

  @Option(name: .shortAndLong, help: "Time range (short, medium, long)")
  var timeRange: String = "medium"

  @Option(name: .shortAndLong, help: "Maximum number of items")
  var limit: Int = 10

  func run() async throws {
    let client = try await SpotifyClientHolder.shared.getClient()

    let range: TimeRange
    switch timeRange.lowercased() {
    case "short": range = .shortTerm
    case "medium": range = .mediumTerm
    case "long": range = .longTerm
    default:
      throw ValidationError("Invalid time range. Use: short, medium, or long")
    }

    if type.lowercased() == "artists" {
      let page = try await client.users.topArtists(timeRange: range, limit: limit)

      print("🌟 Your Top Artists (\(timeRangeName(range)))")
      print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

      for (index, artist) in page.items.enumerated() {
        print("\n\(index + 1). \(artist.name)")
        if let genres = artist.genres, !genres.isEmpty {
          print("   Genres: \(genres.prefix(3).joined(separator: ", "))")
        }
        if let popularity = artist.popularity {
          print("   Popularity: \(popularity)/100")
        }
        if let followers = artist.followers?.total {
          print("   Followers: \(followers.formatted())")
        }
      }
    } else {
      let page = try await client.users.topTracks(timeRange: range, limit: limit)

      print("🎵 Your Top Tracks (\(timeRangeName(range)))")
      print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

      for (index, track) in page.items.enumerated() {
        let artists = track.artists?.map { $0.name }.joined(separator: ", ") ?? "Unknown"
        print("\n\(index + 1). \(track.name)")
        print("   Artist: \(artists)")
        if let album = track.album?.name {
          print("   Album: \(album)")
        }
        if let duration = track.durationMs {
          let minutes = duration / 60000
          let seconds = (duration % 60000) / 1000
          print("   Duration: \(minutes):\(String(format: "%02d", seconds))")
        }
      }
    }
  }

  private func timeRangeName(_ range: TimeRange) -> String {
    switch range {
    case .shortTerm: return "Last 4 weeks"
    case .mediumTerm: return "Last 6 months"
    case .longTerm: return "All time"
    }
  }
}

// MARK: - Player Command

struct Player: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Control playback and view player state",
    subcommands: [
      Status.self,
      Recent.self,
      Pause.self,
      Resume.self,
    ]
  )

  struct Status: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      abstract: "Get current playback state"
    )

    func run() async throws {
      let client = try await SpotifyClientHolder.shared.getClient()

      guard let state = try await client.player.state() else {
        print("⏸️  No active playback")
        return
      }

      print("🎵 Now Playing")
      print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

      if let item = state.item {
        switch item {
        case .track(let track):
          print("Track: \(track.name)")
          if let artists = track.artists?.map({ $0.name }).joined(separator: ", ") {
            print("Artist: \(artists)")
          }
          if let album = track.album?.name {
            print("Album: \(album)")
          }
        case .episode(let episode):
          print("Podcast: \(episode.name ?? "Unknown")")
          print("Show: \(episode.show?.name ?? "Unknown")")
        }
      }

      print("\nStatus: \(state.isPlaying ? "▶️  Playing" : "⏸️  Paused")")
      print("Device: \(state.device.name)")
      print("Shuffle: \(state.shuffleState ? "On" : "Off")")
      print("Repeat: \(state.repeatState.rawValue)")

      if let progress = state.progressMs, let item = state.item {
        let duration: Int?
        switch item {
        case .track(let track): duration = track.durationMs
        case .episode(let episode): duration = episode.durationMs
        }

        if let duration = duration {
          let progressSec = progress / 1000
          let durationSec = duration / 1000
          print("Progress: \(formatTime(progressSec)) / \(formatTime(durationSec))")
        }
      }
    }

    private func formatTime(_ seconds: Int) -> String {
      let mins = seconds / 60
      let secs = seconds % 60
      return "\(mins):\(String(format: "%02d", secs))"
    }
  }

  struct Recent: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      abstract: "Show recently played tracks"
    )

    @Option(name: .shortAndLong, help: "Number of tracks to show")
    var limit: Int = 10

    func run() async throws {
      let client = try await SpotifyClientHolder.shared.getClient()
      let page = try await client.player.recentlyPlayed(limit: limit)

      print("⏮️  Recently Played")
      print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

      let formatter = DateFormatter()
      formatter.dateStyle = .short
      formatter.timeStyle = .short

      for (index, item) in page.items.enumerated() {
        let artists =
          item.track.artists?.map { $0.name }.joined(separator: ", ") ?? "Unknown"
        print("\n\(index + 1). \(item.track.name) - \(artists)")
        print("   Played at: \(formatter.string(from: item.playedAt))")
      }
    }
  }

  struct Pause: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      abstract: "Pause playback"
    )

    func run() async throws {
      let client = try await SpotifyClientHolder.shared.getClient()
      try await client.player.pause()
      print("⏸️  Playback paused")
    }
  }

  struct Resume: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      abstract: "Resume playback"
    )

    func run() async throws {
      let client = try await SpotifyClientHolder.shared.getClient()
      try await client.player.resume()
      print("▶️  Playback resumed")
    }
  }
}

// MARK: - Album Command

struct Album: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Get album information"
  )

  @Argument(help: "Album ID")
  var id: String

  func run() async throws {
    let client = try await SpotifyClientHolder.shared.getClient()
    let album = try await client.albums.get(id)

    print("💿 Album Information")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("Name:         \(album.name)")

    if let artists = album.artists?.map({ $0.name }).joined(separator: ", ") {
      print("Artists:      \(artists)")
    }

    if let releaseDate = album.releaseDate {
      print("Released:     \(releaseDate)")
    }

    if let label = album.label {
      print("Label:        \(label)")
    }

    if let popularity = album.popularity {
      print("Popularity:   \(popularity)/100")
    }

    if let total = album.totalTracks {
      print("Total Tracks: \(total)")
    }

    if let tracks = album.tracks?.items {
      print("\nTracks:")
      for track in tracks {
        let number = track.trackNumber ?? 0
        print("  \(number). \(track.name)")
      }
    }
  }
}

// MARK: - Artist Command

struct Artist: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Get artist information"
  )

  @Argument(help: "Artist ID")
  var id: String

  func run() async throws {
    let client = try await SpotifyClientHolder.shared.getClient()
    let artist = try await client.artists.get(id)

    print("👤 Artist Information")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("Name:       \(artist.name)")

    if let genres = artist.genres, !genres.isEmpty {
      print("Genres:     \(genres.joined(separator: ", "))")
    }

    if let popularity = artist.popularity {
      print("Popularity: \(popularity)/100")
    }

    if let followers = artist.followers?.total {
      print("Followers:  \(followers.formatted())")
    }

    if let uri = artist.uri {
      print("URI:        \(uri)")
    }
  }
}

// MARK: - Track Command

struct Track: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Get track information"
  )

  @Argument(help: "Track ID")
  var id: String

  func run() async throws {
    let client = try await SpotifyClientHolder.shared.getClient()
    let track = try await client.tracks.get(id)

    print("🎵 Track Information")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("Name:       \(track.name)")

    if let artists = track.artists?.map({ $0.name }).joined(separator: ", ") {
      print("Artists:    \(artists)")
    }

    if let album = track.album?.name {
      print("Album:      \(album)")
    }

    if let duration = track.durationMs {
      let minutes = duration / 60000
      let seconds = (duration % 60000) / 1000
      print("Duration:   \(minutes):\(String(format: "%02d", seconds))")
    }

    if let popularity = track.popularity {
      print("Popularity: \(popularity)/100")
    }

    print("Explicit:   \(track.explicit ? "Yes" : "No")")

    if let uri = track.uri {
      print("URI:        \(uri)")
    }
  }
}
