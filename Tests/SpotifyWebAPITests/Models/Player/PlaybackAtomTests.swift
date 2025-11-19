import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct PlaybackAtomTests {

    @Test
    func decodes_Actions_withFullDisallows_and_SnakeCase() async throws {
        // Arrange
        let testData = try TestDataLoader.load("actions_full.json")

        // Act
        let actions: Actions = try decodeModel(from: testData)

        // Assert
        // Check standard keys
        #expect(actions.disallows.resuming == true)
        #expect(actions.disallows.pausing == false)

        // Check snake_case conversion
        #expect(actions.disallows.interruptingPlayback == true)
        #expect(actions.disallows.skippingNext == true)
        #expect(actions.disallows.togglingRepeatContext == true)
        #expect(actions.disallows.togglingShuffle == false)
    }

    @Test
    func decodes_Actions_withPartialDisallows() async throws {
        // Arrange
        let testData = try TestDataLoader.load("actions_partial.json")

        // Act
        let actions: Actions = try decodeModel(from: testData)

        // Assert
        // Check present keys
        #expect(actions.disallows.resuming == true)
        #expect(actions.disallows.skippingNext == false)

        // Check that missing keys are correctly decoded as nil
        #expect(actions.disallows.pausing == nil)
        #expect(actions.disallows.seeking == nil)
        #expect(actions.disallows.togglingShuffle == nil)
    }

    @Test
    func decodes_Actions_withEmptyDisallows() async throws {
        // Arrange
        let testData = try TestDataLoader.load("actions_empty.json")

        // Act
        let actions: Actions = try decodeModel(from: testData)

        // Assert
        // Check that all optional properties are nil
        #expect(actions.disallows.resuming == nil)
        #expect(actions.disallows.pausing == nil)
        #expect(actions.disallows.seeking == nil)
        #expect(actions.disallows.togglingRepeatContext == nil)
    }

    // MARK: - PlaybackContext Tests

    @Test
    func decodes_PlaybackContext_withSnakeCase() async throws {
        // This test validates that 'external_urls' is correctly
        // decoded to the 'externalUrls' property.

        // Arrange
        let testData = try TestDataLoader.load("playback_context.json")

        // Act
        let context: PlaybackContext = try decodeModel(from: testData)

        // Assert
        #expect(context.type == .playlist)
        #expect(context.uri == "spotify:playlist:37i9dQZEVXbMDoHDwVN2tF")
        #expect(
            context.href.absoluteString.contains(
                "v1/playlists/37i9dQZEVXbMDoHDwVN2tF"
            )
        )
        #expect(
            context.externalUrls.spotify?.absoluteString.contains(
                "open.spotify.com"
            ) == true
        )
    }

    // MARK: - PlaybackOffset Tests

    @Test
    func playbackOffset_factory_position_assignsCorrectly() {
        // Arrange
        let offset = PlaybackOffset.position(5)

        // Assert
        #expect(offset.position == 5)
        #expect(offset.uri == nil)
    }

    @Test
    func playbackOffset_factory_uri_assignsCorrectly() {
        // Arrange
        let uri = "spotify:track:123"
        let offset = PlaybackOffset.uri(uri)

        // Assert
        #expect(offset.position == nil)
        #expect(offset.uri == uri)
    }

    @Test
    func playbackOffset_encodes_position_correctly() async throws {
        // Arrange
        let offset = PlaybackOffset.position(3)
        let expectedJSON = #"{"position":3}"#

        // Act
        let data = try encodeModel(offset)
        let jsonString = String(data: data, encoding: .utf8)

        // Assert
        #expect(jsonString == expectedJSON)
    }

    @Test
    func playbackOffset_encodes_uri_correctly() async throws {
        // Arrange
        let uri = "spotify:track:abc"
        let offset = PlaybackOffset.uri(uri)
        let expectedJSON = #"{"uri":"spotify:track:abc"}"#

        // Act
        let data = try encodeModel(offset)
        let jsonString = String(data: data, encoding: .utf8)

        // Assert
        #expect(jsonString == expectedJSON)
    }

    @Test
    func playbackOffset_encodes_nil_for_unusedProperty() async throws {
        // This test ensures that when encoding a position, the 'uri' key
        // is *not* present in the JSON, and vice-versa.

        // Arrange
        let positionOffset = PlaybackOffset.position(1)

        // Act
        let positionData = try encodeModel(positionOffset)
        let positionString = String(data: positionData, encoding: .utf8)!

        // Assert
        #expect(positionString.contains("uri") == false)
        #expect(positionString.contains("position") == true)

        // Arrange 2
        let uriOffset = PlaybackOffset.uri("spotify:track:abc")

        // Act 2
        let uriData = try encodeModel(uriOffset)
        let uriString = String(data: uriData, encoding: .utf8)!

        // Assert 2
        #expect(uriString.contains("position") == false)
        #expect(uriString.contains("uri") == true)
    }
}

@Suite struct RepeatModeTests {

    @Test
    func repeatMode_rawValues_matchAPIConstants() {
        // The Spotify API expects lowercase strings: "track", "context", "off"
        // This test ensures our enum cases map correctly to these strings.

        #expect(RepeatMode.track.rawValue == "track")
        #expect(RepeatMode.context.rawValue == "context")
        #expect(RepeatMode.off.rawValue == "off")
    }

    @Test
    func repeatMode_isCaseIterable() {
        // Verify we cover all known cases
        #expect(RepeatMode.allCases.count == 3)
        #expect(RepeatMode.allCases.contains(.track))
        #expect(RepeatMode.allCases.contains(.context))
        #expect(RepeatMode.allCases.contains(.off))
    }

    @Test
    func repeatMode_encodesCorrectly() throws {
        // Verify that encoding the enum results in the raw string value wrapped in quotes

        let trackData = try encodeModel(RepeatMode.track)
        let trackString = String(data: trackData, encoding: .utf8)
        #expect(trackString == "\"track\"")

        let contextData = try encodeModel(RepeatMode.context)
        let contextString = String(data: contextData, encoding: .utf8)
        #expect(contextString == "\"context\"")

        let offData = try encodeModel(RepeatMode.off)
        let offString = String(data: offData, encoding: .utf8)
        #expect(offString == "\"off\"")
    }
}

extension RepeatMode: Encodable {}
