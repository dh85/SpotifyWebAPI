#if canImport(Combine)
    import Combine
    import Foundation

    /// Generic publisher generator that reduces boilerplate for creating Combine publishers
    /// from async/await service methods.
    ///
    /// This provides a simpler alternative to manually creating publisher methods by using
    /// Swift's type inference and closure capturing.
    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    extension SpotifyCombineService {

        /// Create a publisher from any async throwing operation with no parameters.
        ///
        /// Example usage:
        /// ```swift
        /// public func devicesPublisher(priority: TaskPriority? = nil) -> AnyPublisher<[SpotifyDevice], Error> {
        ///     makePublisher(priority: priority, operation: devices)
        /// }
        /// ```
        public func makePublisher<Output: Sendable>(
            priority: TaskPriority? = nil,
            operation: @escaping @Sendable (Self) async throws -> Output
        ) -> AnyPublisher<Output, Error> {
            publisher(priority: priority, operation: operation)
        }

        /// Create a publisher from an async operation with one parameter.
        ///
        /// Example usage:
        /// ```swift
        /// public func getPublisher(_ id: String, priority: TaskPriority? = nil) -> AnyPublisher<Album, Error> {
        ///     makePublisher(id, priority: priority, operation: Self.get)
        /// }
        /// ```
        public func makePublisher<P1: Sendable, Output: Sendable>(
            _ p1: P1,
            priority: TaskPriority? = nil,
            operation: @escaping @Sendable (Self) -> (P1) async throws -> Output
        ) -> AnyPublisher<Output, Error> {
            publisher(priority: priority) { service in
                try await operation(service)(p1)
            }
        }

        /// Create a publisher from an async operation with two parameters.
        public func makePublisher<P1: Sendable, P2: Sendable, Output: Sendable>(
            _ p1: P1,
            _ p2: P2,
            priority: TaskPriority? = nil,
            operation: @escaping @Sendable (Self) -> (P1, P2) async throws -> Output
        ) -> AnyPublisher<Output, Error> {
            publisher(priority: priority) { service in
                try await operation(service)(p1, p2)
            }
        }

        /// Create a publisher from an async operation with three parameters.
        public func makePublisher<P1: Sendable, P2: Sendable, P3: Sendable, Output: Sendable>(
            _ p1: P1,
            _ p2: P2,
            _ p3: P3,
            priority: TaskPriority? = nil,
            operation: @escaping @Sendable (Self) -> (P1, P2, P3) async throws -> Output
        ) -> AnyPublisher<Output, Error> {
            publisher(priority: priority) { service in
                try await operation(service)(p1, p2, p3)
            }
        }

        /// Create a publisher from an async operation with four parameters.
        public func makePublisher<
            P1: Sendable, P2: Sendable, P3: Sendable, P4: Sendable, Output: Sendable
        >(
            _ p1: P1,
            _ p2: P2,
            _ p3: P3,
            _ p4: P4,
            priority: TaskPriority? = nil,
            operation: @escaping @Sendable (Self) -> (P1, P2, P3, P4) async throws -> Output
        ) -> AnyPublisher<Output, Error> {
            publisher(priority: priority) { service in
                try await operation(service)(p1, p2, p3, p4)
            }
        }
    }

#endif
