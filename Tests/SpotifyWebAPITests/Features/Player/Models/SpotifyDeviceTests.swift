import Foundation
import Testing
@testable import SpotifyWebAPI

@Suite("SpotifyDevice Tests")
struct SpotifyDeviceTests {    
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
