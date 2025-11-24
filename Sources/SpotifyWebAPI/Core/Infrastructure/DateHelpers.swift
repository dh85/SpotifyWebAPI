import Foundation

// MARK: - Date Helpers

/// Convert Date to Unix timestamp in milliseconds.
func dateToUnixMilliseconds(_ date: Date) -> Int64 {
    Int64(date.timeIntervalSince1970 * 1000)
}

/// Convert Unix timestamp in milliseconds to Date.
func dateFromUnixMilliseconds(_ milliseconds: Int64) -> Date {
    Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000.0)
}
