import Foundation

/// Protocol for services that validate ID batch sizes.
protocol ServiceIDValidating {
  /// The maximum number of IDs allowed in a single batch request.
  static var maxBatchSize: Int { get }
}

extension ServiceIDValidating {
  /// Validate that the provided IDs don't exceed the service's batch size limit.
  func validateIDs(_ ids: Set<String>) throws {
    try validateMaxIdCount(Self.maxBatchSize, for: ids)
  }

  /// Validate that the provided IDs (as array) don't exceed the service's batch size limit.
  func validateIDs(_ ids: [String]) throws {
    try validateMaxIdCount(Self.maxBatchSize, for: Set(ids))
  }
}
