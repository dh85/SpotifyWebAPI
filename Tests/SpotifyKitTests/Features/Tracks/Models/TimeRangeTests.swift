import Foundation
import Testing
@testable import SpotifyKit

@Suite("TimeRange Tests")
struct TimeRangeTests {
    @Test("All cases exist")
    func allCasesExist() {
        let cases = TimeRange.allCases
        #expect(cases.count == 3)
        #expect(cases.contains(.shortTerm))
        #expect(cases.contains(.mediumTerm))
        #expect(cases.contains(.longTerm))
    }
    
    @Test("Raw values are correct")
    func rawValuesAreCorrect() {
        #expect(TimeRange.shortTerm.rawValue == "short_term")
        #expect(TimeRange.mediumTerm.rawValue == "medium_term")
        #expect(TimeRange.longTerm.rawValue == "long_term")
    }
    
    @Test("Decodes from raw values")
    func decodesFromRawValues() {
        #expect(TimeRange(rawValue: "short_term") == .shortTerm)
        #expect(TimeRange(rawValue: "medium_term") == .mediumTerm)
        #expect(TimeRange(rawValue: "long_term") == .longTerm)
        #expect(TimeRange(rawValue: "invalid") == nil)
    }
}
