import Foundation

/// The time period for calculating top items.
public enum TimeRange: String, Sendable, CaseIterable {
  /// Approximately last 4 weeks.
  case shortTerm = "short_term"

  /// Approximately last 6 months.
  case mediumTerm = "medium_term"

  /// Calculated from several years of data and including all new data as it becomes available.
  case longTerm = "long_term"
}
