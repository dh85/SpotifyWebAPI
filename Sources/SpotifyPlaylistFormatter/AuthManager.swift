import Foundation
import SpotifyKit

actor AuthManager {
  private let config: AppConfig
  private var client: UserSpotifyClient?

  init(config: AppConfig) {
    self.config = config
  }

  func getClient() async throws -> UserSpotifyClient {
    if let client = client {
      return client
    }

    let callbacks = InteractiveAuthCallbacks(
      onAuthURL: { url in
        print("Opening browser for authorization...")
        print("URL: \(url)")

        #if os(macOS)
          _ = try? Process.run(
            URL(fileURLWithPath: "/usr/bin/open"), arguments: [url.absoluteString])
        #elseif os(Linux)
          _ = try? Process.run(
            URL(fileURLWithPath: "/usr/bin/xdg-open"), arguments: [url.absoluteString])
        #endif
      },
      onPromptCallback: {
        print("\nPaste the callback URL here:")
        guard let input = readLine(), let url = URL(string: input) else {
          throw AppError.invalidCallbackURL
        }
        return url
      }
    )

    let client = try await UserSpotifyClient.authenticateInteractive(
      clientID: config.clientID,
      redirectURI: config.redirectURI,
      scopes: [.playlistReadPrivate, .playlistReadCollaborative],
      callbacks: callbacks
    )

    print("✓ Authentication successful\n")

    self.client = client
    return client
  }
}

extension AppError {
  static let invalidCallbackURL = AppError.invalidPlaylistURL("Invalid callback URL")
}
