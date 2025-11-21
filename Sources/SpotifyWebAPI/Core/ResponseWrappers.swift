import Foundation

/// Generic wrapper for API responses that return an array under a single key.
struct ArrayWrapper<T: Decodable & Sendable>: Decodable, Sendable {
    let items: [T]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicKey.self)
        guard let key = container.allKeys.first else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected a single key in wrapper"
                )
            )
        }
        self.items = try container.decode([T].self, forKey: key)
    }
    
    private struct DynamicKey: CodingKey {
        var stringValue: String
        var intValue: Int?
        
        init?(stringValue: String) {
            self.stringValue = stringValue
            self.intValue = nil
        }
        
        init?(intValue: Int) {
            self.stringValue = String(intValue)
            self.intValue = intValue
        }
    }
}
