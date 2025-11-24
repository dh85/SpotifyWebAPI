import Foundation

/// Rate limit information from Spotify API response headers.
///
/// Spotify includes rate limit headers in responses to help consumers
/// throttle requests proactively and avoid hitting limits.
///
/// ## Usage
///
/// ```swift
/// client.onRateLimitInfo { info in
///     print("Remaining: \(info.remaining ?? -1)")
///     print("Resets at: \(info.resetDate?.description ?? "unknown")")
///     
///     if let remaining = info.remaining, remaining < 10 {
///         print("⚠️ Approaching rate limit!")
///     }
/// }
/// ```
public struct RateLimitInfo: Sendable, Equatable {
    /// Number of requests remaining in the current rate limit window.
    /// `nil` if the header was not present in the response.
    public let remaining: Int?
    
    /// When the rate limit window resets (UTC).
    /// `nil` if the header was not present in the response.
    public let resetDate: Date?
    
    /// Total rate limit for the current window.
    /// `nil` if the header was not present in the response.
    public let limit: Int?
    
    /// The HTTP response that contained these headers.
    /// Useful for debugging or logging the full context.
    public let statusCode: Int
    
    /// The endpoint path that generated this rate limit info.
    public let path: String
    
    public init(
        remaining: Int?,
        resetDate: Date?,
        limit: Int?,
        statusCode: Int,
        path: String
    ) {
        self.remaining = remaining
        self.resetDate = resetDate
        self.limit = limit
        self.statusCode = statusCode
        self.path = path
    }
    
    /// Parse rate limit information from HTTP response headers.
    ///
    /// Spotify uses the following headers:
    /// - `X-RateLimit-Remaining`: Requests remaining
    /// - `X-RateLimit-Reset`: Unix timestamp when limit resets
    /// - `X-RateLimit-Limit`: Total requests allowed in window
    ///
    /// - Parameters:
    ///   - response: The HTTP response.
    ///   - path: The request path.
    /// - Returns: Rate limit info, or `nil` if no headers present.
    public static func parse(from response: HTTPURLResponse, path: String) -> RateLimitInfo? {
        let remaining = response.value(forHTTPHeaderField: "X-RateLimit-Remaining")
            .flatMap(Int.init)
        let resetTimestamp = response.value(forHTTPHeaderField: "X-RateLimit-Reset")
            .flatMap(TimeInterval.init)
            .map { Date(timeIntervalSince1970: $0) }
        let limit = response.value(forHTTPHeaderField: "X-RateLimit-Limit")
            .flatMap(Int.init)
        
        // Only create info if at least one header is present
        guard remaining != nil || resetTimestamp != nil || limit != nil else {
            return nil
        }
        
        return RateLimitInfo(
            remaining: remaining,
            resetDate: resetTimestamp,
            limit: limit,
            statusCode: response.statusCode,
            path: path
        )
    }
}

/// A closure called when rate limit information is received from the API.
///
/// Use this to monitor API usage and implement proactive throttling:
///
/// ```swift
/// client.onRateLimitInfo { info in
///     if let remaining = info.remaining, remaining < 5 {
///         print("⚠️ Only \(remaining) requests remaining!")
///         // Implement backoff strategy
///     }
///     
///     if let resetDate = info.resetDate {
///         let secondsUntilReset = resetDate.timeIntervalSinceNow
///         print("Rate limit resets in \(Int(secondsUntilReset))s")
///     }
/// }
/// ```
public typealias RateLimitInfoCallback = @Sendable (RateLimitInfo) -> Void
