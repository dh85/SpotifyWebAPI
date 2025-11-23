import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct SearchTypeTests {

    @Test
    func caseIterableContainsAllCases() {
        #expect(SearchType.allCases.count == 7)
        #expect(SearchType.allCases.contains(.album))
        #expect(SearchType.allCases.contains(.artist))
        #expect(SearchType.allCases.contains(.playlist))
        #expect(SearchType.allCases.contains(.track))
        #expect(SearchType.allCases.contains(.show))
        #expect(SearchType.allCases.contains(.episode))
        #expect(SearchType.allCases.contains(.audiobook))
    }

    @Test
    func decodesFromRawValue() {
        #expect(SearchType(rawValue: "album") == .album)
        #expect(SearchType(rawValue: "artist") == .artist)
        #expect(SearchType(rawValue: "invalid") == nil)
    }
}
