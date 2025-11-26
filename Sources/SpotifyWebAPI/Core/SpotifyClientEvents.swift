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
    public func onTokenExpiring(_ callback: @escaping TokenExpirationCallback) {
        tokenExpirationCallback = callback
    }
    
    /// Set a callback to be notified before a token refresh begins.
    public func onTokenRefreshWillStart(_ callback: @escaping TokenRefreshWillStartCallback) {
        tokenRefreshWillStartCallback = callback
    }
    
    /// Set a callback to be notified when a token refresh succeeds.
    public func onTokenRefreshDidSucceed(_ callback: @escaping TokenRefreshDidSucceedCallback) {
        tokenRefreshDidSucceedCallback = callback
    }
    
    /// Set a callback to be notified when a token refresh fails.
    public func onTokenRefreshDidFail(_ callback: @escaping TokenRefreshDidFailCallback) {
        tokenRefreshDidFailCallback = callback
    }
    
    /// Set a callback to receive rate limit information from API responses.
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
