public struct SpotifyCopyright: Codable, Sendable, Equatable {
    public enum CopyrightType: String, Codable, Equatable, Sendable {
        case copyright = "C"
        case performance = "P"
    }

    public let text: String
    public let type: CopyrightType
}
