import Foundation

/// A generic structure for sending a list of IDs in a request body.
/// Used for `{"ids": ["..."]}` payloads.
struct IDsBody: Encodable {
    let ids: [String]
}
