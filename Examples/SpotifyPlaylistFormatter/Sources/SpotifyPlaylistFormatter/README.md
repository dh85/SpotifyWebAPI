# SpotifyPlaylistFormatter

A command-line tool to format and display Spotify playlists using SpotifyKit.

## Features

- 🔐 PKCE authentication with automatic token caching
- 📋 Interactive playlist selection from your library
- 🔗 Direct playlist URL/URI support
- 🎨 Formatted output with track details
- 📝 Plain text unformatted mode
- ✅ Fully testable architecture

## Setup

1. Create a Spotify app at https://developer.spotify.com/dashboard
2. Set redirect URI to: `spotifyplaylistformatter://callback` (or your custom URI)
3. Export environment variables:
   ```bash
   export SPOTIFY_CLIENT_ID="your_client_id_here"
   
   # Optional: Override default redirect URI
   export SPOTIFY_REDIRECT_URI="myapp://callback"
   ```

## Usage

### Interactive Mode

List all your playlists and select one:

```bash
swift run SpotifyPlaylistFormatter
```

### Direct URL Mode

Format a specific playlist by URL:

```bash
swift run SpotifyPlaylistFormatter https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M
```

Or by URI:

```bash
swift run SpotifyPlaylistFormatter spotify:playlist:37i9dQZF1DXcBWIGoYBM5M
```

### Unformatted Output

Use `-u` or `--unformatted` for plain text:

```bash
swift run SpotifyPlaylistFormatter -u
swift run SpotifyPlaylistFormatter https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M --unformatted
```

## First Run

On first run, the app will:
1. Open your browser for Spotify authorization
2. Prompt you to paste the callback URL
3. Cache tokens securely (Keychain on macOS, `~/.config/SpotifyKit/` on Linux)

Subsequent runs use cached tokens automatically.

## Architecture

Built with testability in mind:

- **Actor-based**: Thread-safe concurrent operations
- **Dependency injection**: All components are mockable
- **Pure functions**: Formatters have no side effects
- **Isolated I/O**: Console and auth operations are separate

## Testing

Run tests:

```bash
swift test --filter SpotifyPlaylistFormatterTests
```

## Example Output

### Formatted Mode
```
╔══════════════════════════════════════════════════════════════════════╗
║                          My Awesome Playlist                         ║
╠══════════════════════════════════════════════════════════════════════╣

  Total Tracks: 25
  Owner: username

╠══════════════════════════════════════════════════════════════════════╣

    1. Bohemian Rhapsody
       Queen • 5:55
       Album: A Night at the Opera

    2. Stairway to Heaven
       Led Zeppelin • 8:02
       Album: Led Zeppelin IV
```

### Unformatted Mode
```
My Awesome Playlist
1. Bohemian Rhapsody - Queen
2. Stairway to Heaven - Led Zeppelin
```
