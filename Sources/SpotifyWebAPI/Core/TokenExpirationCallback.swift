import Foundation

/// A closure called when token expiration is checked.
///
/// Use this to monitor token lifecycle or implement custom refresh logic:
///
/// ```swift
/// client.onTokenExpiring { expiresIn in
///     if expiresIn < 300 {
///         print("⚠️ Token expires in \(expiresIn) seconds")
///     }
/// }
/// ```
public typealias TokenExpirationCallback = @Sendable (TimeInterval) -> Void
