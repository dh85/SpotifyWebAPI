import Foundation

/// Wrapper for endpoints that return a new snapshot ID.
struct SnapshotResponse: Codable, Sendable, Equatable {
    let snapshotId: String
}
