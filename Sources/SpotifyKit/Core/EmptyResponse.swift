import Foundation

/// A type used to fulfill the 'Decodable' requirement for API calls that
/// succeed with a 200 OK or 204 No Content and have no JSON body.
public struct EmptyResponse: Decodable, Sendable {
    // This struct intentionally has no properties.
}
