import Foundation

/// Manages lifecycle and instrumentation events for the SpotifyClient.
///
/// This actor provides a centralized place to register callbacks for token lifecycle,
/// rate limiting, and other client events.
public actor SpotifyClientEvents {

  // MARK: - Callbacks

  private var tokenExpirationCallback: TokenExpirationCallback?
  private var rateLimitInfoCallback: RateLimitInfoCallback?
  private var tokenRefreshWillStartCallback: TokenRefreshWillStartCallback?
  private var tokenRefreshDidSucceedCallback: TokenRefreshDidSucceedCallback?
  private var tokenRefreshDidFailCallback: TokenRefreshDidFailCallback?

  public init() {}

  // MARK: - Registration Methods

  /// Set a callback to be notified of token expiration.
  ///
  /// The callback receives the number of seconds until expiration.
  ///
  /// - Parameter callback: The closure to invoke when the token is expiring.
  public func onTokenExpiring(_ callback: @escaping TokenExpirationCallback) {
    tokenExpirationCallback = callback
  }

  /// Set a callback to be notified before a token refresh begins.
  ///
  /// - Parameter callback: The closure to invoke before a token refresh starts.
  public func onTokenRefreshWillStart(_ callback: @escaping TokenRefreshWillStartCallback) {
    tokenRefreshWillStartCallback = callback
  }

  /// Set a callback to be notified when a token refresh succeeds.
  ///
  /// - Parameter callback: The closure to invoke after a successful token refresh.
  public func onTokenRefreshDidSucceed(_ callback: @escaping TokenRefreshDidSucceedCallback) {
    tokenRefreshDidSucceedCallback = callback
  }

  /// Set a callback to be notified when a token refresh fails.
  ///
  /// - Parameter callback: The closure to invoke after a failed token refresh.
  public func onTokenRefreshDidFail(_ callback: @escaping TokenRefreshDidFailCallback) {
    tokenRefreshDidFailCallback = callback
  }

  /// Set a callback to receive rate limit information from API responses.
  ///
  /// - Parameter callback: The closure to invoke with rate limit information.
  public func onRateLimitInfo(_ callback: @escaping RateLimitInfoCallback) {
    rateLimitInfoCallback = callback
  }

  // MARK: - Invocation Methods

  func invokeTokenExpiring(_ expiresIn: TimeInterval) {
    tokenExpirationCallback?(expiresIn)
  }

  func invokeTokenRefreshWillStart(_ info: TokenRefreshInfo) {
    tokenRefreshWillStartCallback?(info)
  }

  func invokeTokenRefreshDidSucceed(_ tokens: SpotifyTokens) {
    tokenRefreshDidSucceedCallback?(tokens)
  }

  func invokeTokenRefreshDidFail(_ error: Error) {
    tokenRefreshDidFailCallback?(error)
  }

  func invokeRateLimitInfo(_ info: RateLimitInfo) {
    rateLimitInfoCallback?(info)
  }
}
