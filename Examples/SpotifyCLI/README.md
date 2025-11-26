# Spotify CLI Example

A comprehensive command-line interface demonstrating the SpotifyWebAPI library features.

## Features

This CLI application demonstrates:

- **User Profile**: View your Spotify profile information
- **Search**: Search for tracks, artists, albums, and playlists
- **Playlists**: List your playlists
- **Top Items**: View your top artists and tracks (short/medium/long term)
- **Player Control**: View playback state, control playback, see recently played tracks
- **Album/Artist/Track Info**: Get detailed information about specific items

## Setup

### 1. Set Environment Variables

Create a `.env` file or export these variables:

```bash
export SPOTIFY_CLIENT_ID="your_client_id_here"
export SPOTIFY_CLIENT_SECRET="your_client_secret_here"
export SPOTIFY_REDIRECT_URI="http://localhost:8080/callback"
```

### 2. Build the CLI

```bash
swift build
```

### 3. Run the CLI

```bash
swift run spotify-cli --help
```

Or after building:

```bash
.build/debug/SpotifyCLI --help
```

## Usage

### View Profile

```bash
swift run spotify-cli profile
```

Output:
```
🎵 Spotify Profile
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ID:           your_user_id
Display Name: Your Name
Email:        your@email.com
Country:      US
Product:      premium
Followers:    42
```

### Search

Search for tracks:
```bash
swift run spotify-cli search "Bohemian Rhapsody" --type track --limit 5
```

Search for artists:
```bash
swift run spotify-cli search "Queen" --type artist --limit 10
```

Search for albums:
```bash
swift run spotify-cli search "A Night at the Opera" --type album
```

Search for playlists:
```bash
swift run spotify-cli search "Rock Classics" --type playlist
```

### List Your Playlists

```bash
swift run spotify-cli playlists --limit 20
```

Output:
```
📝 Your Playlists (20 of 47)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. My Awesome Playlist
   ID: 3cEYpjA9oz9GiPac4AsH4n
   Description: The best songs ever
   Owner: Your Name
   Tracks: 150
   Public: Yes

2. Chill Vibes
   ...
```

### Top Artists and Tracks

View your top artists (short term = last 4 weeks):
```bash
swift run spotify-cli top-items --type artists --time-range short --limit 10
```

View your top tracks (medium term = last 6 months):
```bash
swift run spotify-cli top-items --type tracks --time-range medium --limit 20
```

View your all-time top artists:
```bash
swift run spotify-cli top-items --type artists --time-range long
```

Output:
```
🌟 Your Top Artists (Last 6 months)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Queen
   Genres: rock, classic rock, glam rock
   Popularity: 87/100
   Followers: 45,678,901

2. The Beatles
   Genres: rock, psychedelic rock, british invasion
   Popularity: 89/100
   Followers: 52,345,678
```

### Player Control

View current playback:
```bash
swift run spotify-cli player status
```

Output:
```
🎵 Now Playing
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Track: Bohemian Rhapsody
Artist: Queen
Album: A Night at the Opera

Status: ▶️  Playing
Device: Desktop
Shuffle: Off
Repeat: off
Progress: 2:34 / 5:55
```

View recently played tracks:
```bash
swift run spotify-cli player recent --limit 10
```

Pause playback:
```bash
swift run spotify-cli player pause
```

Resume playback:
```bash
swift run spotify-cli player resume
```

### Album Information

```bash
swift run spotify-cli album 6DEjYFkNZh67HP7R9PSZvv
```

Output:
```
💿 Album Information
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Name:         A Night at the Opera
Artists:      Queen
Released:     1975-11-21
Label:        Hollywood Records
Popularity:   73/100
Total Tracks: 12

Tracks:
  1. Death on Two Legs
  2. Lazing on a Sunday Afternoon
  3. I'm in Love with My Car
  ...
```

### Artist Information

```bash
swift run spotify-cli artist 1dfeR4HaWDbWqFHLkxsg1d
```

Output:
```
👤 Artist Information
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Name:       Queen
Genres:     rock, classic rock, glam rock
Popularity: 87/100
Followers:  45,678,901
URI:        spotify:artist:1dfeR4HaWDbWqFHLkxsg1d
```

### Track Information

```bash
swift run spotify-cli track 3z8h0TU7ReDPLIbEnYhWZb
```

Output:
```
🎵 Track Information
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Name:       Bohemian Rhapsody
Artists:    Queen
Album:      A Night at the Opera
Duration:   5:55
Popularity: 89/100
Explicit:   No
URI:        spotify:track:3z8h0TU7ReDPLIbEnYhWZb
```

## Available Commands

| Command | Description |
|---------|-------------|
| `profile` | View your Spotify profile |
| `search <query>` | Search Spotify catalog |
| `playlists` | List your playlists |
| `top-items` | View your top artists or tracks |
| `player status` | View current playback state |
| `player recent` | View recently played tracks |
| `player pause` | Pause playback |
| `player resume` | Resume playback |
| `album <id>` | Get album information |
| `artist <id>` | Get artist information |
| `track <id>` | Get track information |

## Command Options

Most commands support options:

- `--limit, -l`: Limit the number of results (default varies by command)
- `--type, -t`: Specify the type to search for
- `--time-range, -r`: Time range for top items (short/medium/long)

Use `--help` with any command for detailed information:

```bash
swift run spotify-cli search --help
swift run spotify-cli top-items --help
```

## Authentication Note

⚠️ **Important**: This example requires manual OAuth token setup. In a production application, you would implement the full OAuth flow to obtain access tokens. 

For testing, you can:
1. Use the SpotifyWebAPI library's built-in auth flows
2. Manually obtain tokens through Spotify's developer console
3. Implement a web-based OAuth callback handler

## Architecture

The CLI demonstrates:

- **ArgumentParser**: Command-line argument parsing with subcommands
- **Async/Await**: Modern Swift concurrency for API calls
- **Error Handling**: Proper validation and error messages
- **Formatted Output**: Clean, readable terminal output with emojis
- **Shared Client**: Singleton pattern for Spotify client management

## Dependencies

- **swift-argument-parser**: Apple's official CLI framework
- **SpotifyWebAPI**: The library being demonstrated

## Building for Release

```bash
swift build -c release
```

The optimized binary will be in `.build/release/SpotifyCLI`.

## Installing Globally

```bash
# Build release version
swift build -c release

# Copy to local bin
sudo cp .build/release/SpotifyCLI /usr/local/bin/spotify-cli

# Now you can use it anywhere
spotify-cli profile
```

## Examples in Action

### Search and play workflow:

```bash
# Find a track
spotify-cli search "your favorite song" --type track --limit 5

# Get detailed track info
spotify-cli track <track_id_from_search>

# (In a full implementation, you could add a 'play' command)
```

### Discover your music taste:

```bash
# See what you've been listening to
spotify-cli top-items --type artists --time-range short

# See your all-time favorite tracks
spotify-cli top-items --type tracks --time-range long --limit 50

# Check your recent history
spotify-cli player recent --limit 20
```

## Contributing

This is an example application demonstrating the SpotifyWebAPI library. Feel free to extend it with additional commands and features!

## License

Same as the parent SpotifyWebAPI library.
