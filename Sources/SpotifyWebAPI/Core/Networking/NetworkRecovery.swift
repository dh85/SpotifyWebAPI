import Foundation

public enum NetworkRecoveryConfigurationError: Error, CustomStringConvertible {
    case negativeRetryCount(Int)
    case nonPositiveBaseDelay(TimeInterval)
    case invalidMaxDelay(base: TimeInterval, max: TimeInterval)

    public var description: String {
        switch self {
        case .negativeRetryCount(let value):
            return "maxNetworkRetries must be >= 0 (received \(value))"
        case .nonPositiveBaseDelay(let value):
            return "baseRetryDelay must be > 0 (received \(value))"
        case .invalidMaxDelay(let base, let max):
            return "maxRetryDelay (\(max)) must be >= baseRetryDelay (\(base))"
        }
    }
}

/// Configuration for network failure recovery.
public struct NetworkRecoveryConfiguration: Sendable {
    /// Maximum number of retry attempts for network failures.
    public let maxNetworkRetries: Int
    
    /// Delay between retry attempts (exponential backoff).
    public let baseRetryDelay: TimeInterval
    
    /// Maximum delay between retries.
    public let maxRetryDelay: TimeInterval
    
    /// Network error codes that should trigger retries.
    public let retryableNetworkErrors: Set<URLError.Code>
    
    /// HTTP status codes that should trigger retries.
    public let retryableStatusCodes: Set<Int>
    
    public init(
        maxNetworkRetries: Int = 3,
        baseRetryDelay: TimeInterval = 1.0,
        maxRetryDelay: TimeInterval = 30.0,
        retryableNetworkErrors: Set<URLError.Code> = [
            .timedOut,
            .cannotConnectToHost,
            .networkConnectionLost,
            .dnsLookupFailed,
            .notConnectedToInternet
        ],
        retryableStatusCodes: Set<Int> = [500, 502, 503, 504]
    ) {
        self.maxNetworkRetries = maxNetworkRetries
        self.baseRetryDelay = baseRetryDelay
        self.maxRetryDelay = maxRetryDelay
        self.retryableNetworkErrors = retryableNetworkErrors
        self.retryableStatusCodes = retryableStatusCodes
    }
    
    /// Default recovery configuration.
    public static let `default` = NetworkRecoveryConfiguration()
    
    /// Disabled recovery configuration.
    public static let disabled = NetworkRecoveryConfiguration(maxNetworkRetries: 0)
}

public extension NetworkRecoveryConfiguration {
    func validate() throws {
        if maxNetworkRetries < 0 {
            throw NetworkRecoveryConfigurationError.negativeRetryCount(maxNetworkRetries)
        }

        if baseRetryDelay <= 0 {
            throw NetworkRecoveryConfigurationError.nonPositiveBaseDelay(baseRetryDelay)
        }

        if maxRetryDelay < baseRetryDelay {
            throw NetworkRecoveryConfigurationError.invalidMaxDelay(
                base: baseRetryDelay,
                max: maxRetryDelay
            )
        }
    }
}

/// Handles network failure recovery with exponential backoff.
actor NetworkRecoveryHandler {
    private let configuration: NetworkRecoveryConfiguration
    
    init(configuration: NetworkRecoveryConfiguration) {
        self.configuration = configuration
    }
    
    /// Executes a network operation with automatic retry on failure.
    func executeWithRecovery<T>(
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 0...configuration.maxNetworkRetries {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                // Don't retry on the last attempt
                if attempt == configuration.maxNetworkRetries {
                    break
                }
                
                // Check if error is retryable
                if !isRetryableError(error) {
                    throw error
                }
                
                // Calculate delay with exponential backoff
                let delay = calculateDelay(for: attempt)
                try await Task.sleep(for: .seconds(delay))
            }
        }
        
        throw lastError ?? SpotifyClientError.networkFailure("Max retries exceeded")
    }
    
    private func isRetryableError(_ error: Error) -> Bool {
        if let urlError = error as? URLError {
            return configuration.retryableNetworkErrors.contains(urlError.code)
        }
        
        if let authError = error as? SpotifyAuthError,
           case .httpError(let statusCode, _) = authError {
            return configuration.retryableStatusCodes.contains(statusCode)
        }
        
        if let clientError = error as? SpotifyClientError,
           case .httpError(let statusCode, _) = clientError {
            return configuration.retryableStatusCodes.contains(statusCode)
        }
        
        return false
    }
    
    private func calculateDelay(for attempt: Int) -> TimeInterval {
        let exponentialDelay = configuration.baseRetryDelay * pow(2.0, Double(attempt))
        return min(exponentialDelay, configuration.maxRetryDelay)
    }
}