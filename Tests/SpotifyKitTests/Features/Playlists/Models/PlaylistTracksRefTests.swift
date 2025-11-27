import Foundation
import Testing

@testable import SpotifyKit

@Suite struct PlaylistTracksRefTests {

    @Test
    func supportsCodableRoundTrip() throws {
        let ref = PlaylistTracksRef(
            href: URL(string: "https://api.spotify.com/v1/playlists/playlist1/tracks"),
            total: 42
        )
        try expectCodableRoundTrip(ref)
    }
}
