enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
    case head = "HEAD"
    case options = "OPTIONS"

    /// Returns true if the method technically supports an HTTP body.
    var allowsBody: Bool {
        switch self {
        case .get, .head:
            return false
        default:
            return true
        }
    }
}
