#if canImport(Combine)
  import Combine
  import Foundation

  /// Combine publishers that mirror the async PKCE authenticator entry points.
  ///
  /// ## Async Counterparts
  /// Call ``SpotifyPKCEAuthenticator/handleCallback(_:)``, ``SpotifyPKCEAuthenticator/refreshAccessToken(refreshToken:)``,
  /// or ``SpotifyPKCEAuthenticator/refreshAccessTokenIfNeeded(invalidatingPrevious:)`` when you adopt async/await. These publishers
  /// simply forward to the same implementations so validation, persistence, and instrumentation stay consistent.
  @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
  extension SpotifyPKCEAuthenticator {

    /// Handle the authorization callback and exchange the code for tokens.
    ///
    /// - Parameters:
    ///   - url: The callback URL containing the authorization code.
    ///   - priority: The priority of the task.
    /// - Returns: A publisher that emits the access and refresh tokens.
    public nonisolated func handleCallbackPublisher(
      _ url: URL,
      priority: TaskPriority? = nil
    ) -> AnyPublisher<SpotifyTokens, Error> {
      CombineTaskPublisher.make(priority: priority) {
        try await self.handleCallback(url)
      }
    }

    /// Refresh the access token using the provided refresh token.
    ///
    /// - Parameters:
    ///   - refreshToken: The refresh token.
    ///   - priority: The priority of the task.
    /// - Returns: A publisher that emits the new access and refresh tokens.
    public nonisolated func refreshAccessTokenPublisher(
      refreshToken: String,
      priority: TaskPriority? = nil
    ) -> AnyPublisher<SpotifyTokens, Error> {
      CombineTaskPublisher.make(priority: priority) {
        try await self.refreshAccessToken(refreshToken: refreshToken)
      }
    }

    /// Refresh the access token if needed.
    ///
    /// - Parameters:
    ///   - invalidatingPrevious: If true, forces a refresh even if the current token is valid.
    ///   - priority: The priority of the task.
    /// - Returns: A publisher that emits the valid access and refresh tokens.
    public nonisolated func refreshAccessTokenIfNeededPublisher(
      invalidatingPrevious: Bool = false,
      priority: TaskPriority? = nil
    ) -> AnyPublisher<SpotifyTokens, Error> {
      CombineTaskPublisher.make(priority: priority) {
        try await self.refreshAccessTokenIfNeeded(
          invalidatingPrevious: invalidatingPrevious)
      }
    }
  }

  /// Combine publishers that mirror the async Authorization Code authenticator entry points.
  ///
  /// ## Async Counterparts
  /// Prefer ``SpotifyAuthorizationCodeAuthenticator/handleCallback(_:)``, ``SpotifyAuthorizationCodeAuthenticator/refreshAccessToken(refreshToken:)``,
  /// and ``SpotifyAuthorizationCodeAuthenticator/refreshAccessTokenIfNeeded(invalidatingPrevious:)`` when using async/await—the publishers call into the same
  /// implementations so you can swap paradigms without touching auth logic.
  @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
  extension SpotifyAuthorizationCodeAuthenticator {

    /// Handle the authorization callback and exchange the code for tokens.
    ///
    /// - Parameters:
    ///   - url: The callback URL containing the authorization code.
    ///   - priority: The priority of the task.
    /// - Returns: A publisher that emits the access and refresh tokens.
    public nonisolated func handleCallbackPublisher(
      _ url: URL,
      priority: TaskPriority? = nil
    ) -> AnyPublisher<SpotifyTokens, Error> {
      CombineTaskPublisher.make(priority: priority) {
        try await self.handleCallback(url)
      }
    }

    /// Refresh the access token using the provided refresh token.
    ///
    /// - Parameters:
    ///   - refreshToken: The refresh token.
    ///   - priority: The priority of the task.
    /// - Returns: A publisher that emits the new access and refresh tokens.
    public nonisolated func refreshAccessTokenPublisher(
      refreshToken: String,
      priority: TaskPriority? = nil
    ) -> AnyPublisher<SpotifyTokens, Error> {
      CombineTaskPublisher.make(priority: priority) {
        try await self.refreshAccessToken(refreshToken: refreshToken)
      }
    }

    /// Refresh the access token if needed.
    ///
    /// - Parameters:
    ///   - invalidatingPrevious: If true, forces a refresh even if the current token is valid.
    ///   - priority: The priority of the task.
    /// - Returns: A publisher that emits the valid access and refresh tokens.
    public nonisolated func refreshAccessTokenIfNeededPublisher(
      invalidatingPrevious: Bool = false,
      priority: TaskPriority? = nil
    ) -> AnyPublisher<SpotifyTokens, Error> {
      CombineTaskPublisher.make(priority: priority) {
        try await self.refreshAccessTokenIfNeeded(
          invalidatingPrevious: invalidatingPrevious)
      }
    }
  }

  /// Combine publishers that mirror the async Client Credentials authenticator entry points.
  ///
  /// ## Async Counterparts
  /// Use ``SpotifyClientCredentialsAuthenticator/appAccessToken(invalidatingPrevious:)`` and ``SpotifyClientCredentialsAuthenticator/loadPersistedTokens()``
  /// for async/await code. These publishers call into the same implementations so cache/persistence behavior remains identical.
  @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
  extension SpotifyClientCredentialsAuthenticator {

    /// Get an app-only access token.
    ///
    /// - Parameters:
    ///   - invalidatingPrevious: If true, forces a new token request even if cached tokens are valid.
    ///   - priority: The priority of the task.
    /// - Returns: A publisher that emits valid access tokens.
    public nonisolated func appAccessTokenPublisher(
      invalidatingPrevious: Bool = false,
      priority: TaskPriority? = nil
    ) -> AnyPublisher<SpotifyTokens, Error> {
      CombineTaskPublisher.make(priority: priority) {
        try await self.appAccessToken(invalidatingPrevious: invalidatingPrevious)
      }
    }

    /// Load tokens from persistent storage if available.
    ///
    /// - Parameter priority: The priority of the task.
    /// - Returns: A publisher that emits the stored tokens, or nil if no token store is configured or no tokens exist.
    public nonisolated func loadPersistedTokensPublisher(
      priority: TaskPriority? = nil
    ) -> AnyPublisher<SpotifyTokens?, Error> {
      CombineTaskPublisher.make(priority: priority) {
        try await self.loadPersistedTokens()
      }
    }
  }

#endif
