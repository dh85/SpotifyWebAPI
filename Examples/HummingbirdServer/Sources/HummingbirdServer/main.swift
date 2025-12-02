import Foundation
import Hummingbird
import NIOCore
import SpotifyKit

/// Build and configure the application
func buildApplication() async throws -> some ApplicationProtocol {
  // Configure the Spotify client using the builder pattern
  let clientID = ProcessInfo.processInfo.environment["SPOTIFY_CLIENT_ID"] ?? "your-client-id"
  let clientSecret =
    ProcessInfo.processInfo.environment["SPOTIFY_CLIENT_SECRET"] ?? "your-client-secret"
  let redirectURI = URL(string: "http://localhost:8080/callback")!

  let spotifyClient = UserSpotifyClient.authorizationCode(
    clientID: clientID,
    clientSecret: clientSecret,
    redirectURI: redirectURI,
    scopes: [
      .userReadPrivate,
      .userReadEmail,
      .playlistReadPrivate,
      .userLibraryRead,
      .userTopRead,
      .userReadRecentlyPlayed,
    ]
  )

  // Build the router using the controller
  let controller = SpotifyController(client: spotifyClient)
  let router = Router(context: BasicRequestContext.self)
  router.addRoutes(controller.endpoints)

  // Create and configure the application
  let app = Application(
    router: router,
    configuration: .init(
      address: .hostname("127.0.0.1", port: 8080),
      serverName: "SpotifyKit-Hummingbird-Example"
    )
  )

  print("🎵 Starting Spotify Web API Server on http://localhost:8080")
  print("📝 Visit http://localhost:8080/ to get started")
  print("⚠️  Note: OAuth flow requires manual token setup for this example")

  return app
}

// Main entry point
let app = try await buildApplication()
try await app.runService()
