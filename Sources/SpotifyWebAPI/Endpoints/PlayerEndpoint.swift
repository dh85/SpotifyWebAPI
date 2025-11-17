import Foundation

enum PlayerEndpoint {

    /// GET /v1/me/player
    static func getPlaybackState(
        market: String?,
        additionalTypes: [String]?
    ) -> (path: String, query: [URLQueryItem]) {

        let path = "/me/player"
        var items: [URLQueryItem] = []

        if let market {
            items.append(.init(name: "market", value: market))
        }
        if let additionalTypes, !additionalTypes.isEmpty {
            items.append(
                .init(
                    name: "additional_types",
                    value: additionalTypes.joined(separator: ",")
                )
            )
        }

        return (path, items.isEmpty ? [] : items)
    }

    /// PUT /v1/me/player
    static func transferPlayback() -> (path: String, query: [URLQueryItem]) {
        let path = "/me/player"
        return (path, [])  // Body is used, not query
    }

    /// GET /v1/me/player/devices
    static func getAvailableDevices() -> (path: String, query: [URLQueryItem]) {
        let path = "/me/player/devices"
        return (path, [])  // No query parameters
    }

    /// GET /v1/me/player/currently-playing
    static func getCurrentlyPlaying(
        market: String?,
        additionalTypes: [String]?
    ) -> (path: String, query: [URLQueryItem]) {

        let path = "/me/player/currently-playing"
        var items: [URLQueryItem] = []

        if let market {
            items.append(.init(name: "market", value: market))
        }
        if let additionalTypes, !additionalTypes.isEmpty {
            items.append(
                .init(
                    name: "additional_types",
                    value: additionalTypes.joined(separator: ",")
                )
            )
        }

        return (path, items.isEmpty ? [] : items)
    }

    /// PUT /v1/me/player/play
    static func startPlayback(
        deviceID: String?
    ) -> (path: String, query: [URLQueryItem]) {
        let path = "/me/player/play"
        var items: [URLQueryItem] = []

        if let deviceID {
            items.append(.init(name: "device_id", value: deviceID))
        }

        return (path, items.isEmpty ? [] : items)
    }

    /// PUT /v1/me/player/pause
    static func pausePlayback(
        deviceID: String?
    ) -> (path: String, query: [URLQueryItem]) {
        let path = "/me/player/pause"
        var items: [URLQueryItem] = []

        if let deviceID {
            items.append(.init(name: "device_id", value: deviceID))
        }

        return (path, items.isEmpty ? [] : items)
    }

    /// POST /v1/me/player/next
    static func skipToNext(
        deviceID: String?
    ) -> (path: String, query: [URLQueryItem]) {
        let path = "/me/player/next"
        var items: [URLQueryItem] = []

        if let deviceID {
            items.append(.init(name: "device_id", value: deviceID))
        }

        return (path, items.isEmpty ? [] : items)
    }

    /// POST /v1/me/player/previous
    static func skipToPrevious(
        deviceID: String?
    ) -> (path: String, query: [URLQueryItem]) {
        let path = "/me/player/previous"
        var items: [URLQueryItem] = []

        if let deviceID {
            items.append(.init(name: "device_id", value: deviceID))
        }

        return (path, items.isEmpty ? [] : items)
    }

    /// PUT /v1/me/player/seek
    static func seekToPosition(
        positionMs: Int,
        deviceID: String?
    ) -> (path: String, query: [URLQueryItem]) {
        let path = "/me/player/seek"
        var items: [URLQueryItem] = [
            .init(name: "position_ms", value: String(positionMs))
        ]

        if let deviceID {
            items.append(.init(name: "device_id", value: deviceID))
        }

        return (path, items)
    }

    /// PUT /v1/me/player/repeat
    static func setRepeatMode(
        state: RepeatMode,
        deviceID: String?
    ) -> (path: String, query: [URLQueryItem]) {
        let path = "/me/player/repeat"
        var items: [URLQueryItem] = [
            .init(name: "state", value: state.rawValue)
        ]

        if let deviceID {
            items.append(.init(name: "device_id", value: deviceID))
        }

        return (path, items)
    }

    /// PUT /v1/me/player/volume
    static func setPlaybackVolume(
        volumePercent: Int,
        deviceID: String?
    ) -> (path: String, query: [URLQueryItem]) {
        let path = "/me/player/volume"
        var items: [URLQueryItem] = [
            .init(name: "volume_percent", value: String(volumePercent))
        ]

        if let deviceID {
            items.append(.init(name: "device_id", value: deviceID))
        }

        return (path, items)
    }

    /// PUT /v1/me/player/shuffle
    static func setPlaybackShuffle(
        state: Bool,
        deviceID: String?
    ) -> (path: String, query: [URLQueryItem]) {
        let path = "/me/player/shuffle"
        var items: [URLQueryItem] = [
            .init(name: "state", value: String(state))
        ]

        if let deviceID {
            items.append(.init(name: "device_id", value: deviceID))
        }

        return (path, items)
    }

    /// GET /v1/me/player/recently-played
    static func getRecentlyPlayed(
        limit: Int,
        after: Int64?,  // Unix timestamp in ms
        before: Int64?  // Unix timestamp in ms
    ) -> (path: String, query: [URLQueryItem]) {
        let path = "/me/player/recently-played"

        var items: [URLQueryItem] = [
            .init(name: "limit", value: String(limit))
        ]

        if let after {
            items.append(.init(name: "after", value: String(after)))
        }
        if let before {
            items.append(.init(name: "before", value: String(before)))
        }

        return (path, items)
    }

    /// POST /v1/me/player/queue
    static func addItemToQueue(
        uri: String,
        deviceID: String?
    ) -> (path: String, query: [URLQueryItem]) {
        let path = "/me/player/queue"

        var items: [URLQueryItem] = [
            .init(name: "uri", value: uri)
        ]

        if let deviceID {
            items.append(.init(name: "device_id", value: deviceID))
        }

        return (path, items)
    }
}
