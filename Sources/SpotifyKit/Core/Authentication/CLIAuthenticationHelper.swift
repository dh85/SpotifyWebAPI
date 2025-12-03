import Foundation

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

extension UserSpotifyClient {
  /// Authenticate interactively for CLI applications with built-in browser opening and callback prompting.
  ///
  /// This convenience method handles the common CLI authentication flow:
  /// 1. Prints the authorization URL
  /// 2. Attempts to open the URL in the default browser
  /// 3. Prompts the user to paste the callback URL
  ///
  /// - Parameters:
  ///   - clientID: Your Spotify application client ID
  ///   - redirectURI: The redirect URI configured in your Spotify app settings
  ///   - scopes: Array of authorization scopes required by your application
  /// - Returns: An authenticated UserSpotifyClient
  /// - Throws: Authentication errors or invalid callback URL
  ///
  /// Example:
  /// ```swift
  /// let client = try await UserSpotifyClient.authenticateCLI(
  ///   clientID: "your-client-id",
  ///   redirectURI: URL(string: "your-app://callback")!,
  ///   scopes: [.userReadPrivate, .playlistReadPrivate]
  /// )
  /// ```
  public static func authenticateCLI(
    clientID: String,
    redirectURI: URL,
    scopes: [SpotifyScope]
  ) async throws -> UserSpotifyClient {
    let callbacks = InteractiveAuthCallbacks(
      onAuthURL: { url in
        print("\n🔐 Authorization Required")
        print("\nPlease open this URL in your browser:\n")
        print("\u{001B}[36m\(url)\u{001B}[0m\n")
        
        openBrowser(url: url)
      },
      onPromptCallback: {
        print("Paste the callback URL here:")
        guard let input = readLine(), let url = URL(string: input) else {
          throw CLIAuthError.invalidCallbackURL
        }
        return url
      }
    )
    
    return try await authenticateInteractive(
      clientID: clientID,
      redirectURI: redirectURI,
      scopes: Set(scopes),
      callbacks: callbacks
    )
  }
  
  private static func openBrowser(url: URL) {
    #if os(macOS)
      _ = try? Process.run(
        URL(fileURLWithPath: "/usr/bin/open"),
        arguments: [url.absoluteString]
      )
    #elseif os(Linux)
      if FileManager.default.fileExists(atPath: "/usr/bin/wslview") {
        _ = try? Process.run(
          URL(fileURLWithPath: "/usr/bin/wslview"),
          arguments: [url.absoluteString]
        )
      } else if FileManager.default.fileExists(atPath: "/usr/bin/xdg-open") {
        _ = try? Process.run(
          URL(fileURLWithPath: "/usr/bin/xdg-open"),
          arguments: [url.absoluteString]
        )
      }
    #endif
  }
}

public enum CLIAuthError: Error, LocalizedError {
  case invalidCallbackURL
  
  public var errorDescription: String? {
    switch self {
    case .invalidCallbackURL:
      return "Invalid callback URL provided"
    }
  }
}
