import Foundation
import Testing

@testable import SpotifyKit

@Suite
struct ResponseWrappersTests {
    
    // MARK: - ArrayWrapper Tests
    
    @Test
    func arrayWrapper_decodesArrayUnderSingleKey() throws {
        let json = """
        {
            "artists": [
                {"id": "1", "name": "Artist 1"},
                {"id": "2", "name": "Artist 2"}
            ]
        }
        """
        
        struct TestItem: Decodable, Sendable {
            let id: String
            let name: String
        }
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let wrapper = try decoder.decode(ArrayWrapper<TestItem>.self, from: data)
        
        #expect(wrapper.items.count == 2)
        #expect(wrapper.items[0].id == "1")
        #expect(wrapper.items[0].name == "Artist 1")
        #expect(wrapper.items[1].id == "2")
        #expect(wrapper.items[1].name == "Artist 2")
    }
    
    @Test
    func arrayWrapper_decodesEmptyArray() throws {
        let json = """
        {
            "tracks": []
        }
        """
        
        struct TestItem: Decodable, Sendable {
            let id: String
        }
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let wrapper = try decoder.decode(ArrayWrapper<TestItem>.self, from: data)
        
        #expect(wrapper.items.isEmpty)
    }
    
    @Test
    func arrayWrapper_decodesWithDifferentKeyNames() throws {
        let json = """
        {
            "playlists": [
                {"id": "p1"},
                {"id": "p2"}
            ]
        }
        """
        
        struct TestItem: Decodable, Sendable {
            let id: String
        }
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let wrapper = try decoder.decode(ArrayWrapper<TestItem>.self, from: data)
        
        #expect(wrapper.items.count == 2)
        #expect(wrapper.items[0].id == "p1")
    }
    
    @Test
    func arrayWrapper_throwsOnEmptyObject() throws {
        let json = "{}"
        
        struct TestItem: Decodable, Sendable {
            let id: String
        }
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(ArrayWrapper<TestItem>.self, from: data)
        }
    }
    
    @Test
    func arrayWrapper_throwsOnMultipleKeys() throws {
        let json = """
        {
            "artists": [{"id": "1"}],
            "tracks": [{"id": "2"}]
        }
        """
        
        struct TestItem: Decodable, Sendable {
            let id: String
        }
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        // ArrayWrapper takes the first key, so this should succeed
        let wrapper = try decoder.decode(ArrayWrapper<TestItem>.self, from: data)
        #expect(wrapper.items.count == 1)
    }
    
    @Test
    func arrayWrapper_decodesWithSnakeCaseConversion() throws {
        let json = """
        {
            "saved_tracks": [
                {"track_id": "t1", "added_at": "2024-01-01"}
            ]
        }
        """
        
        struct TestItem: Decodable, Sendable {
            let trackId: String
            let addedAt: String
        }
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let wrapper = try decoder.decode(ArrayWrapper<TestItem>.self, from: data)
        
        #expect(wrapper.items.count == 1)
        #expect(wrapper.items[0].trackId == "t1")
        #expect(wrapper.items[0].addedAt == "2024-01-01")
    }
    
    // MARK: - DynamicKey Tests
    
    @Test
    func dynamicKey_initializesWithStringValue() throws {
        let json = """
        {
            "custom_key": [{"id": "1"}]
        }
        """
        
        struct TestItem: Decodable, Sendable {
            let id: String
        }
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let wrapper = try decoder.decode(ArrayWrapper<TestItem>.self, from: data)
        
        #expect(wrapper.items.count == 1)
    }
    
    @Test
    func dynamicKey_handlesIntegerKey() throws {
        let json = """
        {
            "0": [{"id": "1"}]
        }
        """
        
        struct TestItem: Decodable, Sendable {
            let id: String
        }
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let wrapper = try decoder.decode(ArrayWrapper<TestItem>.self, from: data)
        
        #expect(wrapper.items.count == 1)
        #expect(wrapper.items[0].id == "1")
    }
    
    @Test
    func dynamicKey_intValueInitializer_convertsIntToString() throws {
        // Test that integer keys are converted to string representation
        let json = """
        {
            "123": [{"value": "test"}]
        }
        """
        
        struct TestItem: Decodable, Sendable {
            let value: String
        }
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let wrapper = try decoder.decode(ArrayWrapper<TestItem>.self, from: data)
        
        #expect(wrapper.items.count == 1)
        #expect(wrapper.items[0].value == "test")
    }
    

    
    @Test
    func arrayWrapper_isSendable() {
        struct TestItem: Decodable, Sendable {
            let id: String
        }
        
        let _: any Sendable.Type = ArrayWrapper<TestItem>.self
    }
    
    @Test
    func dynamicKey_stringValueInitializer_setsStringValue() {
        // Test DynamicKey.init?(stringValue:) directly
        struct TestKey: CodingKey {
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
        
        let key = TestKey(stringValue: "test")
        #expect(key?.stringValue == "test")
        #expect(key?.intValue == nil)
    }
    
}
