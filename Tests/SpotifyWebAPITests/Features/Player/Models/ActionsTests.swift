import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct ActionsTests {

    @Test
    func decodesFullActionsFixture() throws {
        let data = try TestDataLoader.load("actions_full")
        let actions: Actions = try decodeModel(from: data)

        #expect(actions.interruptingPlayback == true)
        #expect(actions.pausing == false)
        #expect(actions.seeking == false)
        #expect(actions.skippingNext == true)
        #expect(actions.transferringPlayback == false)
    }
}
