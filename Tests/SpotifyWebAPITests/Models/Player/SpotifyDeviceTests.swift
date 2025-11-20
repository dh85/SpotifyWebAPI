import Foundation
import Testing
@testable import SpotifyWebAPI

@Suite("SpotifyDevice Tests")
struct SpotifyDeviceTests {
    @Test("Decodes with all fields")
    func decodesWithAllFields() throws {
        let json = """
        {
            "id": "device123",
            "is_active": true,
            "is_private_session": false,
            "is_restricted": false,
            "name": "My Speaker",
            "type": "speaker",
            "volume_percent": 75,
            "supports_volume": true
        }
        """.data(using: .utf8)!
        
        let device: SpotifyDevice = try decodeModel(from: json)
        
        #expect(device.id == "device123")
        #expect(device.isActive == true)
        #expect(device.isPrivateSession == false)
        #expect(device.isRestricted == false)
        #expect(device.name == "My Speaker")
        #expect(device.type == "speaker")
        #expect(device.volumePercent == 75)
        #expect(device.supportsVolume == true)
    }
    
    @Test("Decodes without optional fields")
    func decodesWithoutOptionalFields() throws {
        let json = """
        {
            "id": null,
            "is_active": false,
            "is_private_session": true,
            "is_restricted": true,
            "name": "Unknown Device",
            "type": "computer",
            "volume_percent": null,
            "supports_volume": null
        }
        """.data(using: .utf8)!
        
        let device: SpotifyDevice = try decodeModel(from: json)
        
        #expect(device.id == nil)
        #expect(device.isActive == false)
        #expect(device.isPrivateSession == true)
        #expect(device.isRestricted == true)
        #expect(device.name == "Unknown Device")
        #expect(device.type == "computer")
        #expect(device.volumePercent == nil)
        #expect(device.supportsVolume == nil)
    }
    
    @Test("Equatable works correctly")
    func equatableWorksCorrectly() {
        let device1 = SpotifyDevice(
            id: "device1",
            isActive: true,
            isPrivateSession: false,
            isRestricted: false,
            name: "Device 1",
            type: "smartphone",
            volumePercent: 50,
            supportsVolume: true
        )
        
        let device2 = SpotifyDevice(
            id: "device1",
            isActive: true,
            isPrivateSession: false,
            isRestricted: false,
            name: "Device 1",
            type: "smartphone",
            volumePercent: 50,
            supportsVolume: true
        )
        
        let device3 = SpotifyDevice(
            id: "device2",
            isActive: false,
            isPrivateSession: true,
            isRestricted: true,
            name: "Device 2",
            type: "computer",
            volumePercent: nil,
            supportsVolume: false
        )
        
        #expect(device1 == device2)
        #expect(device1 != device3)
    }
    
    @Test("Encodes correctly")
    func encodesCorrectly() throws {
        let device = SpotifyDevice(
            id: "device789",
            isActive: true,
            isPrivateSession: false,
            isRestricted: false,
            name: "Test Device",
            type: "speaker",
            volumePercent: 80,
            supportsVolume: true
        )
        
        let data = try encodeModel(device)
        let decoded: SpotifyDevice = try decodeModel(from: data)
        
        #expect(decoded == device)
    }
    
    @Test("Decodes future device types")
    func decodesFutureDeviceTypes() throws {
        let json = """
        {
            "id": "device123",
            "is_active": false,
            "is_private_session": false,
            "is_restricted": false,
            "name": "Future Device",
            "type": "smart_tv",
            "volume_percent": 50,
            "supports_volume": true
        }
        """.data(using: .utf8)!
        
        let device: SpotifyDevice = try decodeModel(from: json)
        #expect(device.type == "smart_tv")
    }
}
