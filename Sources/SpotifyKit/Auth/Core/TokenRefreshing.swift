import Foundation

/// Defines a `TokenPersisting` actor that can also refresh user tokens.
protocol TokenRefreshing: TokenPersisting {
  /// The main refresh logic, unique to each flow.
  func refreshAccessToken(refreshToken: String) async throws -> SpotifyTokens

  /// The shared logic for checking if a refresh is needed.
  func refreshAccessTokenIfNeeded(invalidatingPrevious: Bool) async throws
    -> SpotifyTokens

  /// The current refresh task, if any, to prevent duplicate refresh requests.
  var refreshTask: Task<SpotifyTokens, Error>? { get set }
}

// Provide a default implementation for the checking logic.
extension TokenRefreshing {
  public func refreshAccessTokenIfNeeded(invalidatingPrevious: Bool = false)
    async throws -> SpotifyTokens
  {
    // 1. Cached, not expired, AND not invalidating
    if let cachedTokens, !cachedTokens.isExpired, !invalidatingPrevious {
      return cachedTokens
    }

    // Check if a refresh is already in progress
    if let refreshTask {
      return try await refreshTask.value
    }

    // 2. Cached, (expired OR invalidating), has refresh token
    if let cachedTokens, let refresh = cachedTokens.refreshToken {
      return try await performRefresh(refreshToken: refresh)
    }

    // 3 + 4. Load once from store
    if let stored = try await tokenStore.load() {
      // 3a. Stored, not expired, AND not invalidating
      if !stored.isExpired, !invalidatingPrevious {
        cachedTokens = stored
        return stored
      }
      // 3b. Stored, (expired OR invalidating), has refresh
      if let refresh = stored.refreshToken {
        return try await performRefresh(refreshToken: refresh)
      }
    }

    // 5. Nothing usable
    throw SpotifyAuthError.missingRefreshToken
  }

  private func performRefresh(refreshToken: String) async throws -> SpotifyTokens {
    let task = Task { () -> SpotifyTokens in
      let newTokens = try await self.refreshAccessToken(refreshToken: refreshToken)
      try await self.persist(newTokens)
      return newTokens
    }
    refreshTask = task
    defer { refreshTask = nil }
    return try await task.value
  }
}
