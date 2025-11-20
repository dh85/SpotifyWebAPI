import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct ResumePointTests {

    @Test
    func decodesFromJSON() throws {
        let json = """
            {
                "fully_played": false,
                "resume_position_ms": 120000
            }
            """
        let data = json.data(using: .utf8)!
        let resumePoint: ResumePoint = try decodeModel(from: data)

        #expect(resumePoint.fullyPlayed == false)
        #expect(resumePoint.resumePositionMs == 120000)
    }

    @Test
    func decodesFullyPlayed() throws {
        let json = """
            {
                "fully_played": true,
                "resume_position_ms": 0
            }
            """
        let data = json.data(using: .utf8)!
        let resumePoint: ResumePoint = try decodeModel(from: data)

        #expect(resumePoint.fullyPlayed == true)
        #expect(resumePoint.resumePositionMs == 0)
    }

    @Test
    func equatableWorksCorrectly() throws {
        let json = """
            {
                "fully_played": false,
                "resume_position_ms": 60000
            }
            """
        let data = json.data(using: .utf8)!
        let resumePoint1: ResumePoint = try decodeModel(from: data)
        let resumePoint2: ResumePoint = try decodeModel(from: data)

        #expect(resumePoint1 == resumePoint2)
    }
}
