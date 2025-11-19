import Testing
import Foundation
@testable import SpotifyWebAPI

@Suite struct SpotifyDeviceTests {

    @Test
    func decodes_SpotifyDevice_Correctly() throws {
        // Arrange
        let testData = try TestDataLoader.load("device_full.json")

        // Act
        // Use snake_case helper to handle 'is_active', 'volume_percent', etc.
        let device: SpotifyDevice = try decodeModel(from: testData)

        // Assert
        #expect(device.id == "5fbb3ba6aa454b5534c4ba43a8c7e8e45a63ad0e")
        #expect(device.isActive == true)
        #expect(device.isPrivateSession == false)
        #expect(device.isRestricted == false)
        #expect(device.name == "My Fridge")
        #expect(device.type == .speaker)
        #expect(device.volumePercent == 100)
        #expect(device.supportsVolume == true)
    }

    @Test
    func deviceType_enums_matchStrings() {
        // Verify the raw values match the API expectations (lowercase)
        #expect(SpotifyDevice.DeviceType.computer.rawValue == "computer")
        #expect(SpotifyDevice.DeviceType.smartphone.rawValue == "smartphone")
        #expect(SpotifyDevice.DeviceType.speaker.rawValue == "speaker")
    }

    @Test
    func encodes_SpotifyDevice_Correctly() throws {
        // Arrange
        let device = SpotifyDevice(
            id: "123",
            isActive: true,
            isPrivateSession: false,
            isRestricted: false,
            name: "Test Phone",
            type: .smartphone,
            volumePercent: 50,
            supportsVolume: true
        )

        // Act
        let data = try encodeModel(device)
        let jsonString = String(data: data, encoding: .utf8)!

        // Assert
        // Verify key encoding strategy worked (snake_case)
        #expect(jsonString.contains("is_active"))
        #expect(jsonString.contains("volume_percent"))
        #expect(jsonString.contains("smartphone"))
    }
}
