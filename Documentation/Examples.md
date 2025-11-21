# Examples

This document provides practical examples for common use cases with the SpotifyWebAPI library.

## Table of Contents

1. [iOS App with SwiftUI](#ios-app-with-swiftui)
2. [macOS Menu Bar App](#macos-menu-bar-app)
3. [Command Line Tool](#command-line-tool)
4. [Server-Side Swift](#server-side-swift)
5. [Music Discovery App](#music-discovery-app)
6. [Playlist Manager](#playlist-manager)
7. [Audio Analysis Tool](#audio-analysis-tool)
8. [Testing Examples](#testing-examples)

## iOS App with SwiftUI

### Complete iOS Music Player App

```swift
import SwiftUI
import SpotifyWebAPI

@main
struct SpotifyPlayerApp: App {
    @StateObject private var spotifyService = SpotifyService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(spotifyService)
        }
    }
}

class SpotifyService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: CurrentUserProfile?
    @Published var playbackState: PlaybackState?
    @Published var userPlaylists: [SimplifiedPlaylist] = []
    
    private let authenticator: SpotifyPKCEAuthenticator
    private let client: SpotifyClient
    
    init() {
        self.authenticator = SpotifyPKCEAuthenticator(
            clientId: "your-client-id",
            redirectURI: URL(string: "your-app://callback")!,
            scopes: [
                .userReadPrivate,
                .userReadEmail,
                .playlistReadPrivate,
                .userReadPlaybackState,
                .userModifyPlaybackState,
                .userLibraryRead
            ]
        )
        
        self.client = SpotifyClient(authenticator: authenticator)
        
        // Check for existing tokens
        Task {
            if let _ = try? await authenticator.loadPersistedTokens() {
                await MainActor.run {
                    self.isAuthenticated = true
                }
                await loadUserData()
            }
        }
    }
    
    func authenticate() async throws {
        let pkcePair = try authenticator.generatePKCE()
        let authURL = authenticator.makeAuthorizationURL(
            scopes: authenticator.scopes,
            codeChallenge: pkcePair.codeChallenge,
            state: UUID().uuidString
        )
        
        // Open auth URL in Safari
        await MainActor.run {
            UIApplication.shared.open(authURL)
        }
        
        // Store PKCE pair for callback handling
        UserDefaults.standard.set(pkcePair.codeVerifier, forKey: "pkce_verifier")
    }
    
    func handleCallback(url: URL) async throws {
        guard let codeVerifier = UserDefaults.standard.string(forKey: "pkce_verifier") else {
            throw SpotifyAuthError.missingCode
        }
        
        try await authenticator.handleCallback(
            url: url,
            codeVerifier: codeVerifier,
            state: extractState(from: url)
        )
        
        await MainActor.run {
            self.isAuthenticated = true
        }
        
        await loadUserData()
        UserDefaults.standard.removeObject(forKey: "pkce_verifier")
    }
    
    private func loadUserData() async {
        do {
            let user = try await client.me()
            let playlists = try await client.myPlaylists(limit: 50)
            let playback = try await client.playbackState()
            
            await MainActor.run {
                self.currentUser = user
                self.userPlaylists = playlists.items
                self.playbackState = playback
            }
        } catch {
            print("Error loading user data: \(error)")
        }
    }
    
    func refreshPlaybackState() async {
        do {
            let playback = try await client.playbackState()
            await MainActor.run {
                self.playbackState = playback
            }
        } catch {
            print("Error refreshing playback state: \(error)")
        }
    }
    
    func play() async throws {
        try await client.play()
        await refreshPlaybackState()
    }
    
    func pause() async throws {
        try await client.pause()
        await refreshPlaybackState()
    }
    
    func skipToNext() async throws {
        try await client.skipToNext()
        await refreshPlaybackState()
    }
    
    func skipToPrevious() async throws {
        try await client.skipToPrevious()
        await refreshPlaybackState()
    }
    
    private func extractState(from url: URL) -> String {
        // Extract state parameter from callback URL
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let stateItem = components.queryItems?.first(where: { $0.name == "state" }),
              let state = stateItem.value else {
            return ""
        }
        return state
    }
}

struct ContentView: View {
    @EnvironmentObject var spotifyService: SpotifyService
    
    var body: some View {
        NavigationView {
            if spotifyService.isAuthenticated {
                MainView()
            } else {
                LoginView()
            }
        }
    }
}

struct LoginView: View {
    @EnvironmentObject var spotifyService: SpotifyService
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Welcome to Spotify Player")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Connect your Spotify account to get started")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Connect to Spotify") {
                Task {
                    try await spotifyService.authenticate()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}

struct MainView: View {
    @EnvironmentObject var spotifyService: SpotifyService
    
    var body: some View {
        TabView {
            PlayerView()
                .tabItem {
                    Image(systemName: "play.circle")
                    Text("Player")
                }
            
            PlaylistsView()
                .tabItem {
                    Image(systemName: "music.note.list")
                    Text("Playlists")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Profile")
                }
        }
    }
}

struct PlayerView: View {
    @EnvironmentObject var spotifyService: SpotifyService
    
    var body: some View {
        VStack(spacing: 20) {
            if let playback = spotifyService.playbackState,
               let track = playback.item {
                
                AsyncImage(url: track.album?.images?.first?.url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 250, height: 250)
                .cornerRadius(12)
                
                VStack(spacing: 8) {
                    Text(track.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    Text(track.artists?.map(\.name).joined(separator: ", ") ?? "")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 30) {
                    Button(action: {
                        Task { try await spotifyService.skipToPrevious() }
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.title)
                    }
                    
                    Button(action: {
                        Task {
                            if playback.isPlaying {
                                try await spotifyService.pause()
                            } else {
                                try await spotifyService.play()
                            }
                        }
                    }) {
                        Image(systemName: playback.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 60))
                    }
                    
                    Button(action: {
                        Task { try await spotifyService.skipToNext() }
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.title)
                    }
                }
                .foregroundColor(.green)
                
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "music.note")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No music playing")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Button("Refresh") {
                        Task {
                            await spotifyService.refreshPlaybackState()
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .navigationTitle("Now Playing")
        .onAppear {
            Task {
                await spotifyService.refreshPlaybackState()
            }
        }
    }
}

struct PlaylistsView: View {
    @EnvironmentObject var spotifyService: SpotifyService
    
    var body: some View {
        NavigationView {
            List(spotifyService.userPlaylists, id: \.id) { playlist in
                NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                    HStack {
                        AsyncImage(url: playlist.images?.first?.url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 50, height: 50)
                        .cornerRadius(8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(playlist.name)
                                .font(.headline)
                            
                            Text("\(playlist.tracks.total) tracks")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("My Playlists")
        }
    }
}

struct PlaylistDetailView: View {
    let playlist: SimplifiedPlaylist
    @EnvironmentObject var spotifyService: SpotifyService
    @State private var tracks: [PlaylistTrackItem] = []
    
    var body: some View {
        List(tracks, id: \.track?.id) { item in
            if let track = item.track {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(track.name)
                            .font(.headline)
                        
                        Text(track.artists?.map(\.name).joined(separator: ", ") ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        Task {
                            try await spotifyService.client.play(uris: [track.uri])
                        }
                    }) {
                        Image(systemName: "play.circle")
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .navigationTitle(playlist.name)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadTracks()
        }
    }
    
    private func loadTracks() async {
        do {
            let tracksPage = try await spotifyService.client.getPlaylistTracks(playlist.id)
            await MainActor.run {
                self.tracks = tracksPage.items
            }
        } catch {
            print("Error loading tracks: \(error)")
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var spotifyService: SpotifyService
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let user = spotifyService.currentUser {
                    AsyncImage(url: user.images.first?.url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    
                    VStack(spacing: 8) {
                        Text(user.displayName ?? "Unknown User")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("@\(user.id)")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        if let country = user.country {
                            Text(country)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Followers:")
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(user.followers.total)")
                        }
                        
                        if let product = user.product {
                            HStack {
                                Text("Subscription:")
                                    .fontWeight(.medium)
                                Spacer()
                                Text(product.capitalized)
                                    .foregroundColor(product == "premium" ? .green : .orange)
                            }
                        }
                        
                        if let email = user.email {
                            HStack {
                                Text("Email:")
                                    .fontWeight(.medium)
                                Spacer()
                                Text(email)
                                    .font(.caption)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Profile")
        }
    }
}
```

## macOS Menu Bar App

### Simple Menu Bar Player

```swift
import Cocoa
import SwiftUI
import SpotifyWebAPI

@main
struct MenuBarPlayerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private let spotifyService = SpotifyService()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupPopover()
        
        // Start periodic updates
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            Task {
                await self.spotifyService.refreshPlaybackState()
            }
        }
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "Spotify")
            button.action = #selector(togglePopover)
            button.target = self
        }
    }
    
    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarPlayerView()
                .environmentObject(spotifyService)
        )
    }
    
    @objc func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
}

struct MenuBarPlayerView: View {
    @EnvironmentObject var spotifyService: SpotifyService
    
    var body: some View {
        VStack(spacing: 16) {
            if let playback = spotifyService.playbackState,
               let track = playback.item {
                
                HStack {
                    AsyncImage(url: track.album?.images?.first?.url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(track.name)
                            .font(.headline)
                            .lineLimit(1)
                        
                        Text(track.artists?.map(\.name).joined(separator: ", ") ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                }
                
                HStack(spacing: 20) {
                    Button(action: {
                        Task { try await spotifyService.skipToPrevious() }
                    }) {
                        Image(systemName: "backward.fill")
                    }
                    
                    Button(action: {
                        Task {
                            if playback.isPlaying {
                                try await spotifyService.pause()
                            } else {
                                try await spotifyService.play()
                            }
                        }
                    }) {
                        Image(systemName: playback.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.title)
                    }
                    
                    Button(action: {
                        Task { try await spotifyService.skipToNext() }
                    }) {
                        Image(systemName: "forward.fill")
                    }
                }
                .buttonStyle(.plain)
                
                if let progress = playback.progressMs,
                   let duration = track.durationMs {
                    ProgressView(value: Double(progress), total: Double(duration))
                        .progressViewStyle(LinearProgressViewStyle())
                }
                
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "music.note")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("No music playing")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    if !spotifyService.isAuthenticated {
                        Button("Connect to Spotify") {
                            Task {
                                try await spotifyService.authenticate()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .foregroundColor(.red)
        }
        .padding()
        .frame(width: 280)
    }
}
```

## Command Line Tool

### Spotify CLI Tool

```swift
import Foundation
import ArgumentParser
import SpotifyWebAPI

@main
struct SpotifyCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "spotify-cli",
        abstract: "A command-line interface for Spotify",
        subcommands: [
            AuthCommand.self,
            PlayCommand.self,
            SearchCommand.self,
            PlaylistCommand.self,
            StatusCommand.self
        ]
    )
}

struct AuthCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "auth",
        abstract: "Authenticate with Spotify"
    )
    
    @Option(help: "Client ID")
    var clientId: String
    
    @Option(help: "Client Secret")
    var clientSecret: String
    
    func run() async throws {
        let authenticator = SpotifyClientCredentialsAuthenticator(
            clientId: clientId,
            clientSecret: clientSecret
        )
        
        let client = SpotifyClient(authenticator: authenticator)
        
        // Test authentication
        do {
            let _ = try await client.search(query: "test", types: [.track], limit: 1)
            print("✅ Authentication successful!")
            
            // Save credentials
            let credentials = ["clientId": clientId, "clientSecret": clientSecret]
            let data = try JSONSerialization.data(withJSONObject: credentials)
            let url = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".spotify-cli-credentials")
            try data.write(to: url)
            
        } catch {
            print("❌ Authentication failed: \(error)")
            throw ExitCode.failure
        }
    }
}

struct PlayCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "play",
        abstract: "Control playback"
    )
    
    @Argument(help: "Action: play, pause, next, previous")
    var action: String
    
    func run() async throws {
        let client = try await createAuthenticatedClient()
        
        switch action.lowercased() {
        case "play":
            try await client.play()
            print("▶️ Playing")
            
        case "pause":
            try await client.pause()
            print("⏸️ Paused")
            
        case "next":
            try await client.skipToNext()
            print("⏭️ Skipped to next")
            
        case "previous", "prev":
            try await client.skipToPrevious()
            print("⏮️ Skipped to previous")
            
        default:
            print("❌ Unknown action: \(action)")
            print("Available actions: play, pause, next, previous")
            throw ExitCode.failure
        }
    }
}

struct SearchCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "search",
        abstract: "Search for music"
    )
    
    @Argument(help: "Search query")
    var query: String
    
    @Option(help: "Search type: track, artist, album, playlist")
    var type: String = "track"
    
    @Option(help: "Number of results")
    var limit: Int = 10
    
    func run() async throws {
        let client = try await createAuthenticatedClient()
        
        let searchType: SearchType
        switch type.lowercased() {
        case "track": searchType = .track
        case "artist": searchType = .artist
        case "album": searchType = .album
        case "playlist": searchType = .playlist
        default:
            print("❌ Unknown search type: \(type)")
            throw ExitCode.failure
        }
        
        let results = try await client.search(
            query: query,
            types: [searchType],
            limit: limit
        )
        
        switch searchType {
        case .track:
            if let tracks = results.tracks?.items {
                print("🎵 Tracks:")
                for (index, track) in tracks.enumerated() {
                    let artists = track.artists.map(\.name).joined(separator: ", ")
                    print("\(index + 1). \(track.name) - \(artists)")
                }
            }
            
        case .artist:
            if let artists = results.artists?.items {
                print("👤 Artists:")
                for (index, artist) in artists.enumerated() {
                    print("\(index + 1). \(artist.name)")
                }
            }
            
        case .album:
            if let albums = results.albums?.items {
                print("💿 Albums:")
                for (index, album) in albums.enumerated() {
                    let artists = album.artists.map(\.name).joined(separator: ", ")
                    print("\(index + 1). \(album.name) - \(artists)")
                }
            }
            
        case .playlist:
            if let playlists = results.playlists?.items {
                print("📋 Playlists:")
                for (index, playlist) in playlists.enumerated() {
                    print("\(index + 1). \(playlist.name) - \(playlist.tracks.total) tracks")
                }
            }
            
        default:
            break
        }
    }
}

struct PlaylistCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "playlist",
        abstract: "Manage playlists",
        subcommands: [ListPlaylists.self, CreatePlaylist.self]
    )
}

struct ListPlaylists: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List user's playlists"
    )
    
    func run() async throws {
        let client = try await createUserAuthenticatedClient()
        
        let playlists = try await client.myPlaylists(limit: 50)
        
        print("📋 Your Playlists:")
        for (index, playlist) in playlists.items.enumerated() {
            let privacy = playlist.isPublic == true ? "Public" : "Private"
            print("\(index + 1). \(playlist.name) (\(privacy)) - \(playlist.tracks.total) tracks")
        }
    }
}

struct CreatePlaylist: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a new playlist"
    )
    
    @Argument(help: "Playlist name")
    var name: String
    
    @Option(help: "Playlist description")
    var description: String?
    
    @Flag(help: "Make playlist public")
    var isPublic: Bool = false
    
    func run() async throws {
        let client = try await createUserAuthenticatedClient()
        
        let playlist = try await client.createPlaylist(
            name: name,
            description: description,
            isPublic: isPublic
        )
        
        print("✅ Created playlist: \(playlist.name)")
        print("🔗 URL: \(playlist.externalUrls.spotify ?? "N/A")")
    }
}

struct StatusCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "status",
        abstract: "Show current playback status"
    )
    
    func run() async throws {
        let client = try await createUserAuthenticatedClient()
        
        if let playback = try await client.playbackState() {
            if let track = playback.item {
                let artists = track.artists?.map(\.name).joined(separator: ", ") ?? "Unknown"
                let status = playback.isPlaying ? "▶️ Playing" : "⏸️ Paused"
                
                print("\(status): \(track.name) - \(artists)")
                
                if let progress = playback.progressMs,
                   let duration = track.durationMs {
                    let progressSeconds = progress / 1000
                    let durationSeconds = duration / 1000
                    let progressMinutes = progressSeconds / 60
                    let durationMinutes = durationSeconds / 60
                    
                    print("⏱️ Progress: \(progressMinutes):\(String(format: "%02d", progressSeconds % 60)) / \(durationMinutes):\(String(format: "%02d", durationSeconds % 60))")
                }
                
                if let device = playback.device {
                    print("📱 Device: \(device.name) (\(device.type))")
                }
                
                print("🔀 Shuffle: \(playback.shuffleState ? "On" : "Off")")
                print("🔁 Repeat: \(playback.repeatState.rawValue)")
                
            } else {
                print("🎵 No track currently playing")
            }
        } else {
            print("❌ No active playback session")
        }
    }
}

// Helper functions
func createAuthenticatedClient() async throws -> SpotifyClient {
    let credentials = try loadCredentials()
    let authenticator = SpotifyClientCredentialsAuthenticator(
        clientId: credentials.clientId,
        clientSecret: credentials.clientSecret
    )
    return SpotifyClient(authenticator: authenticator)
}

func createUserAuthenticatedClient() async throws -> SpotifyClient {
    // This would require implementing user authentication flow
    // For CLI tools, you might want to use device authorization flow
    throw CLIError.userAuthRequired
}

func loadCredentials() throws -> (clientId: String, clientSecret: String) {
    let url = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".spotify-cli-credentials")
    
    guard let data = try? Data(contentsOf: url),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
          let clientId = json["clientId"],
          let clientSecret = json["clientSecret"] else {
        print("❌ No credentials found. Run 'spotify-cli auth' first.")
        throw CLIError.noCredentials
    }
    
    return (clientId, clientSecret)
}

enum CLIError: Error {
    case noCredentials
    case userAuthRequired
}
```

## Server-Side Swift

### Vapor Web Service

```swift
import Vapor
import SpotifyWebAPI

func routes(_ app: Application) throws {
    let spotifyService = SpotifyService()
    
    app.get("search") { req async throws -> SearchResponse in
        guard let query = req.query[String.self, at: "q"] else {
            throw Abort(.badRequest, reason: "Missing query parameter 'q'")
        }
        
        let type = req.query[String.self, at: "type"] ?? "track"
        let limit = req.query[Int.self, at: "limit"] ?? 20
        
        let searchType: SearchType
        switch type {
        case "track": searchType = .track
        case "artist": searchType = .artist
        case "album": searchType = .album
        default: searchType = .track
        }
        
        let results = try await spotifyService.search(
            query: query,
            type: searchType,
            limit: limit
        )
        
        return SearchResponse(results: results)
    }
    
    app.get("recommendations") { req async throws -> RecommendationsResponse in
        let seedArtists = req.query[String.self, at: "seed_artists"]?.components(separatedBy: ",") ?? []
        let seedTracks = req.query[String.self, at: "seed_tracks"]?.components(separatedBy: ",") ?? []
        let limit = req.query[Int.self, at: "limit"] ?? 20
        
        let recommendations = try await spotifyService.getRecommendations(
            seedArtists: seedArtists,
            seedTracks: seedTracks,
            limit: limit
        )
        
        return RecommendationsResponse(recommendations: recommendations)
    }
    
    app.get("audio-features", ":trackId") { req async throws -> AudioFeaturesResponse in
        guard let trackId = req.parameters.get("trackId") else {
            throw Abort(.badRequest, reason: "Missing track ID")
        }
        
        let features = try await spotifyService.getAudioFeatures(trackId)
        return AudioFeaturesResponse(features: features)
    }
}

class SpotifyService {
    private let client: SpotifyClient
    
    init() {
        let authenticator = SpotifyClientCredentialsAuthenticator(
            clientId: Environment.get("SPOTIFY_CLIENT_ID")!,
            clientSecret: Environment.get("SPOTIFY_CLIENT_SECRET")!
        )
        
        self.client = SpotifyClient(authenticator: authenticator)
    }
    
    func search(query: String, type: SearchType, limit: Int) async throws -> SearchResults {
        return try await client.search(
            query: query,
            types: [type],
            limit: limit
        )
    }
    
    func getRecommendations(seedArtists: [String], seedTracks: [String], limit: Int) async throws -> Recommendations {
        return try await client.getRecommendations(
            seedArtists: seedArtists,
            seedTracks: seedTracks,
            limit: limit
        )
    }
    
    func getAudioFeatures(_ trackId: String) async throws -> AudioFeatures {
        return try await client.getAudioFeatures(trackId)
    }
}

struct SearchResponse: Content {
    let results: SearchResults
}

struct RecommendationsResponse: Content {
    let recommendations: Recommendations
}

struct AudioFeaturesResponse: Content {
    let features: AudioFeatures
}
```

## Music Discovery App

### Advanced Music Discovery with ML

```swift
import SwiftUI
import SpotifyWebAPI
import CoreML

class MusicDiscoveryService: ObservableObject {
    @Published var recommendations: [Track] = []
    @Published var audioFeatures: [String: AudioFeatures] = [:]
    @Published var isLoading = false
    
    private let client: SpotifyClient
    private let mlModel: MusicRecommendationModel?
    
    init(client: SpotifyClient) {
        self.client = client
        self.mlModel = try? MusicRecommendationModel(configuration: MLModelConfiguration())
    }
    
    func discoverMusic(basedOn seedTracks: [String]) async {
        await MainActor.run { isLoading = true }
        
        do {
            // Get audio features for seed tracks
            let seedFeatures = try await client.getAudioFeatures(seedTracks)
            
            // Calculate average features
            let avgFeatures = calculateAverageFeatures(seedFeatures.compactMap { $0 })
            
            // Get Spotify recommendations
            let spotifyRecs = try await client.getRecommendations(
                seedTracks: Array(seedTracks.prefix(5)),
                limit: 50,
                targetDanceability: avgFeatures.danceability,
                targetEnergy: avgFeatures.energy,
                targetValence: avgFeatures.valence,
                targetAcousticness: avgFeatures.acousticness,
                targetInstrumentalness: avgFeatures.instrumentalness
            )
            
            // Get audio features for recommendations
            let recTrackIds = spotifyRecs.tracks.map(\.id)
            let recFeatures = try await client.getAudioFeatures(recTrackIds)
            
            // Create features dictionary
            var featuresDict: [String: AudioFeatures] = [:]
            for (index, features) in recFeatures.enumerated() {
                if let features = features {
                    featuresDict[recTrackIds[index]] = features
                }
            }
            
            // Apply ML filtering if available
            var filteredTracks = spotifyRecs.tracks
            if let model = mlModel {
                filteredTracks = await applyMLFiltering(tracks: spotifyRecs.tracks, features: featuresDict, model: model)
            }
            
            await MainActor.run {
                self.recommendations = filteredTracks
                self.audioFeatures = featuresDict
                self.isLoading = false
            }
            
        } catch {
            print("Error discovering music: \(error)")
            await MainActor.run { isLoading = false }
        }
    }
    
    private func calculateAverageFeatures(_ features: [AudioFeatures]) -> AudioFeatures {
        let count = Double(features.count)
        
        return AudioFeatures(
            acousticness: features.map(\.acousticness).reduce(0, +) / count,
            danceability: features.map(\.danceability).reduce(0, +) / count,
            energy: features.map(\.energy).reduce(0, +) / count,
            instrumentalness: features.map(\.instrumentalness).reduce(0, +) / count,
            liveness: features.map(\.liveness).reduce(0, +) / count,
            loudness: features.map(\.loudness).reduce(0, +) / count,
            speechiness: features.map(\.speechiness).reduce(0, +) / count,
            valence: features.map(\.valence).reduce(0, +) / count,
            tempo: features.map(\.tempo).reduce(0, +) / count,
            // ... other properties
        )
    }
    
    private func applyMLFiltering(tracks: [Track], features: [String: AudioFeatures], model: MusicRecommendationModel) async -> [Track] {
        var scoredTracks: [(track: Track, score: Double)] = []
        
        for track in tracks {
            guard let trackFeatures = features[track.id] else { continue }
            
            // Create ML input
            let input = MusicRecommendationModelInput(
                danceability: trackFeatures.danceability,
                energy: trackFeatures.energy,
                valence: trackFeatures.valence,
                acousticness: trackFeatures.acousticness,
                instrumentalness: trackFeatures.instrumentalness,
                tempo: trackFeatures.tempo,
                popularity: Double(track.popularity)
            )
            
            do {
                let prediction = try model.prediction(input: input)
                scoredTracks.append((track: track, score: prediction.recommendationScore))
            } catch {
                print("ML prediction error: \(error)")
                scoredTracks.append((track: track, score: 0.5)) // Default score
            }
        }
        
        // Sort by ML score and return top tracks
        return scoredTracks
            .sorted { $0.score > $1.score }
            .prefix(20)
            .map(\.track)
    }
}

struct MusicDiscoveryView: View {
    @StateObject private var discoveryService: MusicDiscoveryService
    @State private var seedTracks: [Track] = []
    @State private var searchText = ""
    @State private var searchResults: [Track] = []
    
    init(client: SpotifyClient) {
        self._discoveryService = StateObject(wrappedValue: MusicDiscoveryService(client: client))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Seed tracks section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Seed Tracks")
                        .font(.headline)
                    
                    if seedTracks.isEmpty {
                        Text("Add some tracks you like to get started")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(seedTracks, id: \.id) { track in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(track.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text(track.artists.map(\.name).joined(separator: ", "))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button("Remove") {
                                    seedTracks.removeAll { $0.id == track.id }
                                }
                                .font(.caption)
                                .foregroundColor(.red)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // Search section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Add Tracks")
                        .font(.headline)
                    
                    SearchBar(text: $searchText, onSearchButtonClicked: {
                        Task {
                            await searchTracks()
                        }
                    })
                    
                    if !searchResults.isEmpty {
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(searchResults, id: \.id) { track in
                                    TrackRow(track: track) {
                                        if !seedTracks.contains(where: { $0.id == track.id }) {
                                            seedTracks.append(track)
                                        }
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                    }
                }
                .padding()
                
                // Discover button
                Button("Discover Music") {
                    Task {
                        await discoveryService.discoverMusic(basedOn: seedTracks.map(\.id))
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(seedTracks.isEmpty || discoveryService.isLoading)
                
                // Recommendations
                if discoveryService.isLoading {
                    ProgressView("Discovering music...")
                        .padding()
                } else if !discoveryService.recommendations.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recommendations")
                            .font(.headline)
                        
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(discoveryService.recommendations, id: \.id) { track in
                                    RecommendationRow(
                                        track: track,
                                        features: discoveryService.audioFeatures[track.id]
                                    )
                                }
                            }
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
            .navigationTitle("Music Discovery")
        }
    }
    
    private func searchTracks() async {
        // Implementation for searching tracks
    }
}

struct RecommendationRow: View {
    let track: Track
    let features: AudioFeatures?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(track.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(track.artists.map(\.name).joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Popularity: \(track.popularity)")
                        .font(.caption2)
                    
                    if let features = features {
                        Text("Energy: \(String(format: "%.2f", features.energy))")
                            .font(.caption2)
                    }
                }
            }
            
            if let features = features {
                HStack(spacing: 16) {
                    FeatureBar(label: "Dance", value: features.danceability, color: .blue)
                    FeatureBar(label: "Energy", value: features.energy, color: .red)
                    FeatureBar(label: "Valence", value: features.valence, color: .green)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

struct FeatureBar: View {
    let label: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 4)
                
                Rectangle()
                    .fill(color)
                    .frame(width: 40 * value, height: 4)
            }
            .cornerRadius(2)
        }
    }
}
```

## Testing Examples

### Comprehensive Test Suite

```swift
import XCTest
@testable import SpotifyWebAPI

class SpotifyServiceTests: XCTestCase {
    var mockClient: MockSpotifyClient!
    var service: SpotifyService!
    
    override func setUp() {
        super.setUp()
        mockClient = MockSpotifyClient()
        service = SpotifyService(client: mockClient)
    }
    
    override func tearDown() {
        mockClient = nil
        service = nil
        super.tearDown()
    }
    
    func testLoadUserProfile() async throws {
        // Given
        let expectedProfile = CurrentUserProfile(
            id: "test-user",
            displayName: "Test User",
            email: "test@example.com",
            country: "US",
            product: "premium",
            href: URL(string: "https://api.spotify.com/v1/users/test-user")!,
            externalUrls: SpotifyExternalUrls(spotify: nil),
            images: [],
            followers: SpotifyFollowers(href: nil, total: 100),
            explicitContent: nil,
            type: .user,
            uri: "spotify:user:test-user"
        )
        mockClient.mockProfile = expectedProfile
        
        // When
        await service.loadUserProfile()
        
        // Then
        XCTAssertTrue(mockClient.getUsersCalled)
        XCTAssertEqual(service.currentUser?.id, "test-user")
        XCTAssertEqual(service.currentUser?.displayName, "Test User")
    }
    
    func testLoadUserProfileError() async throws {
        // Given
        mockClient.mockError = SpotifyAuthError.tokenExpired
        
        // When
        await service.loadUserProfile()
        
        // Then
        XCTAssertTrue(mockClient.getUsersCalled)
        XCTAssertNil(service.currentUser)
        XCTAssertEqual(service.errorMessage, "Token expired")
    }
    
    func testPlayTrack() async throws {
        // Given
        let track = createMockTrack()
        mockClient.mockTrack = track
        
        // When
        try await service.playTrack("test-track-id")
        
        // Then
        XCTAssertTrue(mockClient.getTrackCalled)
        XCTAssertTrue(mockClient.playCalled)
    }
    
    func testCreatePlaylist() async throws {
        // Given
        let expectedPlaylist = createMockPlaylist()
        mockClient.mockPlaylist = expectedPlaylist
        
        // When
        let playlist = try await service.createPlaylist(
            name: "Test Playlist",
            description: "Test Description"
        )
        
        // Then
        XCTAssertEqual(playlist.name, "Test Playlist")
        XCTAssertEqual(playlist.description, "Test Description")
    }
    
    func testSearchTracks() async throws {
        // Given
        let mockTracks = [createMockTrack(), createMockTrack()]
        // Note: This would require extending MockSpotifyClient to support search
        
        // When
        let results = try await service.searchTracks("test query")
        
        // Then
        XCTAssertEqual(results.count, 2)
    }
    
    // MARK: - Helper Methods
    
    private func createMockTrack() -> Track {
        return Track(
            album: SimplifiedAlbum(
                albumType: .album,
                totalTracks: 10,
                availableMarkets: ["US"],
                externalUrls: SpotifyExternalUrls(spotify: nil),
                href: URL(string: "https://api.spotify.com/v1/albums/test")!,
                id: "test-album",
                images: [],
                name: "Test Album",
                releaseDate: "2023-01-01",
                releaseDatePrecision: .day,
                restrictions: nil,
                type: .album,
                uri: "spotify:album:test-album",
                artists: []
            ),
            artists: [
                SimplifiedArtist(
                    externalUrls: SpotifyExternalUrls(spotify: nil),
                    href: URL(string: "https://api.spotify.com/v1/artists/test")!,
                    id: "test-artist",
                    name: "Test Artist",
                    type: .artist,
                    uri: "spotify:artist:test-artist"
                )
            ],
            availableMarkets: ["US"],
            discNumber: 1,
            durationMs: 180000,
            explicit: false,
            externalIds: SpotifyExternalIds(isrc: nil, ean: nil, upc: nil),
            externalUrls: SpotifyExternalUrls(spotify: nil),
            href: URL(string: "https://api.spotify.com/v1/tracks/test")!,
            id: "test-track",
            isPlayable: true,
            linkedFrom: nil,
            restrictions: nil,
            name: "Test Track",
            popularity: 75,
            previewUrl: nil,
            trackNumber: 1,
            type: .track,
            uri: "spotify:track:test-track",
            isLocal: false
        )
    }
    
    private func createMockPlaylist() -> Playlist {
        return Playlist(
            collaborative: false,
            description: "Test Description",
            externalUrls: SpotifyExternalUrls(spotify: nil),
            followers: SpotifyFollowers(href: nil, total: 0),
            href: URL(string: "https://api.spotify.com/v1/playlists/test")!,
            id: "test-playlist",
            images: [],
            name: "Test Playlist",
            owner: SpotifyPublicUser(
                displayName: "Test User",
                externalUrls: SpotifyExternalUrls(spotify: nil),
                followers: SpotifyFollowers(href: nil, total: 0),
                href: URL(string: "https://api.spotify.com/v1/users/test")!,
                id: "test-user",
                images: [],
                type: .user,
                uri: "spotify:user:test-user"
            ),
            isPublic: true,
            snapshotId: "test-snapshot",
            tracks: Page<PlaylistTrackItem>(
                href: URL(string: "https://api.spotify.com/v1/playlists/test/tracks")!,
                items: [],
                limit: 100,
                next: nil,
                offset: 0,
                previous: nil,
                total: 0
            ),
            type: .playlist,
            uri: "spotify:playlist:test-playlist"
        )
    }
}

// Integration Tests
class SpotifyIntegrationTests: XCTestCase {
    var client: SpotifyClient!
    
    override func setUp() {
        super.setUp()
        
        // Only run integration tests if credentials are available
        guard let clientId = ProcessInfo.processInfo.environment["SPOTIFY_CLIENT_ID"],
              let clientSecret = ProcessInfo.processInfo.environment["SPOTIFY_CLIENT_SECRET"] else {
            return
        }
        
        let authenticator = SpotifyClientCredentialsAuthenticator(
            clientId: clientId,
            clientSecret: clientSecret
        )
        
        client = SpotifyClient(authenticator: authenticator)
    }
    
    func testSearchIntegration() async throws {
        guard client != nil else {
            throw XCTSkip("Integration tests require Spotify credentials")
        }
        
        let results = try await client.search(
            query: "The Beatles",
            types: [.artist],
            limit: 1
        )
        
        XCTAssertNotNil(results.artists)
        XCTAssertFalse(results.artists!.items.isEmpty)
        
        let beatles = results.artists!.items.first!
        XCTAssertEqual(beatles.name, "The Beatles")
    }
    
    func testGetArtistIntegration() async throws {
        guard client != nil else {
            throw XCTSkip("Integration tests require Spotify credentials")
        }
        
        // The Beatles' Spotify ID
        let artist = try await client.getArtist("3WrFJ7ztbogyGnTHbHJFl2")
        
        XCTAssertEqual(artist.name, "The Beatles")
        XCTAssertFalse(artist.genres.isEmpty)
        XCTAssertGreaterThan(artist.popularity, 0)
    }
}

// Performance Tests
class SpotifyPerformanceTests: XCTestCase {
    var client: SpotifyClient!
    
    override func setUp() {
        super.setUp()
        
        guard let clientId = ProcessInfo.processInfo.environment["SPOTIFY_CLIENT_ID"],
              let clientSecret = ProcessInfo.processInfo.environment["SPOTIFY_CLIENT_SECRET"] else {
            return
        }
        
        let authenticator = SpotifyClientCredentialsAuthenticator(
            clientId: clientId,
            clientSecret: clientSecret
        )
        
        client = SpotifyClient(authenticator: authenticator)
    }
    
    func testSearchPerformance() async throws {
        guard client != nil else {
            throw XCTSkip("Performance tests require Spotify credentials")
        }
        
        measure {
            let expectation = XCTestExpectation(description: "Search completed")
            
            Task {
                do {
                    _ = try await client.search(
                        query: "rock",
                        types: [.track],
                        limit: 50
                    )
                    expectation.fulfill()
                } catch {
                    XCTFail("Search failed: \(error)")
                }
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    func testConcurrentRequests() async throws {
        guard client != nil else {
            throw XCTSkip("Performance tests require Spotify credentials")
        }
        
        let queries = ["rock", "pop", "jazz", "classical", "electronic"]
        
        measure {
            let expectation = XCTestExpectation(description: "All searches completed")
            expectation.expectedFulfillmentCount = queries.count
            
            for query in queries {
                Task {
                    do {
                        _ = try await client.search(
                            query: query,
                            types: [.track],
                            limit: 10
                        )
                        expectation.fulfill()
                    } catch {
                        XCTFail("Search failed for \(query): \(error)")
                    }
                }
            }
            
            wait(for: [expectation], timeout: 15.0)
        }
    }
}
```

These examples demonstrate the versatility and power of the SpotifyWebAPI library across different platforms and use cases. Each example includes proper error handling, modern Swift concurrency patterns, and best practices for working with the Spotify Web API.