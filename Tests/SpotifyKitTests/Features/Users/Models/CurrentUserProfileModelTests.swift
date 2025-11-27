import Foundation
import Testing

@testable import SpotifyKit

@Suite struct CurrentUserProfileModelTests {

    @Test
    func explicitContentSettingsEquatable() {
        let settings1 = CurrentUserProfile.ExplicitContentSettings(
            filterEnabled: true, filterLocked: false)
        let settings2 = CurrentUserProfile.ExplicitContentSettings(
            filterEnabled: true, filterLocked: false)
        let settings3 = CurrentUserProfile.ExplicitContentSettings(
            filterEnabled: false, filterLocked: true)

        #expect(settings1 == settings2)
        #expect(settings1 != settings3)
    }
}
