import Foundation

/// Wrapper for the `GET /v1/me/player/devices` endpoint response.
struct AvailableDevicesResponse: Codable, Sendable, Equatable {
    let devices: [Device]
}
