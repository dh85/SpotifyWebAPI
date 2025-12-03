# Spotify Playlist Formatter

A command-line tool to format and display Spotify playlists using SpotifyKit.

## Setup

1. Set environment variables:
   ```bash
   export SPOTIFY_CLIENT_ID="your_client_id"
   export SPOTIFY_REDIRECT_URI="your_redirect_uri"
   ```

2. Build and run:
   ```bash
   swift run SpotifyPlaylistFormatter <playlist-url>
   ```

## Usage

```bash
# Format a playlist
swift run SpotifyPlaylistFormatter https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M

# Unformatted output
swift run SpotifyPlaylistFormatter --unformatted https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M

# Show help
swift run SpotifyPlaylistFormatter --help
```

## Dependencies

- [SpotifyKit](../../) - Swift SDK for the Spotify Web API
