import Foundation
import Testing

@testable import SpotifyKit

@Suite struct ResumePointTests {

    @Test
    func decodesResumePointJSON() throws {
        let json = """
        { "fully_played": true, "resume_position_ms": 1200 }
        """
        let resumePoint: ResumePoint = try decodeModel(from: Data(json.utf8))

        #expect(resumePoint.fullyPlayed)
        #expect(resumePoint.resumePositionMs == 1200)
        try expectCodableRoundTrip(resumePoint)
    }
}
