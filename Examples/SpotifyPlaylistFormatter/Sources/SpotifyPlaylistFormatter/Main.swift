import ArgumentParser

@main
struct SpotifyPlaylistFormatter {
  static func main() async {
    let command = SpotifyPlaylistFormatterCommand.parseOrExit()
    let app = PlaylistFormatterApp()
    await app.run(command: command)
  }
}
