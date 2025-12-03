@main
struct SpotifyPlaylistFormatter {
  static func main() async {
    let app = PlaylistFormatterApp()
    await app.run()
  }
}
