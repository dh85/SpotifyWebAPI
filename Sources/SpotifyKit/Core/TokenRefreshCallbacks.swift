import Foundation

/// Information about a token refresh event.
///
/// Contains metadata about the refresh operation including the reason
/// for refresh and token expiration details.
public struct TokenRefreshInfo: Sendable, Equatable {
  /// The reason the token refresh was triggered.
  public let reason: RefreshReason

  /// The time remaining (in seconds) before the old token expires.
  /// Negative values indicate the token has already expired.
  public let secondsUntilExpiration: TimeInterval

  /// Whether this is an automatic refresh (due to expiration) or manual (forced).
  public enum RefreshReason: Sendable, Equatable {
    /// Token is expired or about to expire - automatic refresh.
    case automatic

    /// Refresh was explicitly requested via `invalidatingPrevious: true`.
    case manual
  }

  public init(reason: RefreshReason, secondsUntilExpiration: TimeInterval) {
    self.reason = reason
    self.secondsUntilExpiration = secondsUntilExpiration
  }
}

/// A closure called before attempting to refresh access tokens.
///
/// Use this to show loading indicators or prepare your app for a token refresh:
///
/// ```swift
/// client.events.onTokenRefreshWillStart { info in
///     if info.reason == .automatic {
///         print("🔄 Auto-refreshing expired token...")
///     } else {
///         print("🔄 Manual token refresh requested")
///     }
/// }
/// ```
public typealias TokenRefreshWillStartCallback = @Sendable (TokenRefreshInfo) -> Void

/// A closure called after successfully refreshing access tokens.
///
/// Use this to update UI, persist new tokens, or send analytics:
///
/// ```swift
/// client.events.onTokenRefreshDidSucceed { newTokens in
///     print("✅ Token refreshed, expires at \(newTokens.expiresAt)")
///
///     // Persist to secure storage
///     await keychain.save(newTokens)
///
///     // Update UI
///     Task { @MainActor in
///         statusLabel.text = "Connected"
///     }
/// }
/// ```
public typealias TokenRefreshDidSucceedCallback = @Sendable (SpotifyTokens) -> Void

/// A closure called when token refresh fails.
///
/// Use this to handle authentication failures, show login screens, or retry logic:
///
/// ```swift
/// client.events.onTokenRefreshDidFail { error in
///     print("❌ Token refresh failed: \(error)")
///
///     if case SpotifyAuthError.missingRefreshToken = error {
///         // Show login screen - user needs to re-authenticate
///         Task { @MainActor in
///             showLoginScreen()
///         }
///     }
/// }
/// ```
public typealias TokenRefreshDidFailCallback = @Sendable (Error) -> Void
