import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// A closure that can inspect, modify, or cancel a request before it's sent.
///
/// Use interceptors for logging, analytics, or request modification:
///
/// ```swift
/// client.addInterceptor { request in
///     print("📤 \(request.httpMethod ?? "GET") \(request.url?.path ?? "")")
///     return request
/// }
/// ```
public typealias RequestInterceptor = @Sendable (URLRequest) async throws -> URLRequest
