func validateLimit(
    _ limit: Int,
    withinRange range: ClosedRange<Int> = 1...50
) throws {
    guard range.contains(limit) else {
        throw SpotifyClientError.invalidRequest(
            reason:
                "Limit must be between \(range.lowerBound) and \(range.upperBound). You provided \(limit)."
        )
    }
}

func validateMaxIdCount<C: Collection>(
    _ maximum: Int,
    for ids: C
) throws where C.Element == String {
    guard ids.count <= maximum else {
        throw SpotifyClientError.invalidRequest(
            reason:
                "Maximum of \(maximum) IDs allowed per request. You provided \(ids.count)."
        )
    }
}
