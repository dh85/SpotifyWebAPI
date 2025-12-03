import Foundation

/// Callbacks for interactive authentication flow
public struct InteractiveAuthCallbacks: Sendable {
  /// Called when the authorization URL is ready. Default prints to stdout.
  public let onAuthURL: @Sendable (URL) -> Void
  
  /// Called to prompt user for callback URL. Default reads from stdin.
  public let onPromptCallback: @Sendable () async throws -> URL
  
  public init(
    onAuthURL: @escaping @Sendable (URL) -> Void = { url in
      print("Open this URL in your browser to authorize:")
      print(url.absoluteString)
    },
    onPromptCallback: @escaping @Sendable () async throws -> URL = {
      print("\nPaste the callback URL here:")
      guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines),
            let url = URL(string: input) else {
        throw SpotifyAuthError.invalidCallback
      }
      return url
    }
  ) {
    self.onAuthURL = onAuthURL
    self.onPromptCallback = onPromptCallback
  }
}

extension SpotifyClient where Capability == UserAuthCapability {
  /// Perform interactive PKCE authentication for CLI applications.
  ///
  /// This method simplifies the authentication flow by:
  /// 1. Generating the authorization URL
  /// 2. Calling `onAuthURL` to display it (default: prints to stdout)
  /// 3. Calling `onPromptCallback` to get the callback URL (default: reads from stdin)
  /// 4. Exchanging the code for tokens
  /// 5. Creating and returning an authenticated client
  ///
  /// ## Example
  /// ```swift
  /// let client = try await UserSpotifyClient.authenticateInteractive(
  ///   clientID: "your-client-id",
  ///   redirectURI: URL(string: "myapp://callback")!,
  ///   scopes: [.playlistReadPrivate, .userReadPrivate]
  /// )
  ///
  /// // Client is ready to use
  /// let playlists = try await client.playlists.myPlaylists()
  /// ```
  ///
  /// ## Custom Callbacks
  /// ```swift
  /// let callbacks = InteractiveAuthCallbacks(
  ///   onAuthURL: { url in
  ///     // Open browser automatically
  ///     NSWorkspace.shared.open(url)
  ///   },
  ///   onPromptCallback: {
  ///     // Custom input method
  ///     return try await getCallbackFromWebServer()
  ///   }
  /// )
  ///
  /// let client = try await UserSpotifyClient.authenticateInteractive(
  ///   clientID: "your-client-id",
  ///   redirectURI: URL(string: "myapp://callback")!,
  ///   scopes: [.playlistReadPrivate],
  ///   callbacks: callbacks
  /// )
  /// ```
  ///
  /// - Parameters:
  ///   - clientID: Your Spotify application client ID
  ///   - redirectURI: The redirect URI registered in your Spotify app
  ///   - scopes: The authorization scopes to request
  ///   - tokenStore: Optional token store for caching. Defaults to platform-specific secure storage.
  ///   - callbacks: Callbacks for displaying auth URL and prompting for callback. Defaults to stdout/stdin.
  /// - Returns: An authenticated `UserSpotifyClient` ready to make API calls
  /// - Throws: `SpotifyAuthError` if authentication fails
  public static func authenticateInteractive(
    clientID: String,
    redirectURI: URL,
    scopes: Set<SpotifyScope>,
    tokenStore: TokenStore? = nil,
    callbacks: InteractiveAuthCallbacks = InteractiveAuthCallbacks()
  ) async throws -> UserSpotifyClient {
    let store = tokenStore ?? TokenStoreFactory.defaultStore()
    
    // Check if we already have valid tokens
    if let existingTokens = try await store.load() {
      // Try to create client with existing tokens
      let client: UserSpotifyClient = .pkce(
        clientID: clientID,
        redirectURI: redirectURI,
        scopes: scopes,
        tokenStore: store
      )
      
      // Verify tokens are still valid by making a test request
      do {
        _ = try await client.me()
        return client
      } catch {
        // Tokens invalid, continue with fresh auth
      }
    }
    
    // Perform fresh authentication
    let authenticator = SpotifyPKCEAuthenticator(
      config: .pkce(
        clientID: clientID,
        redirectURI: redirectURI,
        scopes: scopes
      ),
      tokenStore: store
    )
    
    let authURL = try await authenticator.makeAuthorizationURL()
    callbacks.onAuthURL(authURL)
    
    let callbackURL = try await callbacks.onPromptCallback()
    _ = try await authenticator.handleCallback(callbackURL)
    
    return .pkce(
      clientID: clientID,
      redirectURI: redirectURI,
      scopes: scopes,
      tokenStore: store
    )
  }
}

extension SpotifyAuthError {
  /// Invalid callback URL provided during interactive authentication
  public static var invalidCallback: SpotifyAuthError {
    .httpError(statusCode: 400, body: "Invalid callback URL format")
  }
}
