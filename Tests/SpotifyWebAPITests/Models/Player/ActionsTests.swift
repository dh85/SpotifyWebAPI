import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct ActionsTests {

    @Test
    func decodesFromJSON() throws {
        let json = """
            {
                "resuming": true,
                "skipping_prev": true
            }
            """
        let data = json.data(using: .utf8)!
        let actions: Actions = try decodeModel(from: data)

        #expect(actions.resuming == true)
        #expect(actions.skippingPrev == true)
    }

    @Test
    func equatableWorksCorrectly() throws {
        let json = """
            {
                "pausing": true
            }
            """
        let data = json.data(using: .utf8)!
        let actions1: Actions = try decodeModel(from: data)
        let actions2: Actions = try decodeModel(from: data)

        #expect(actions1 == actions2)
    }
}
