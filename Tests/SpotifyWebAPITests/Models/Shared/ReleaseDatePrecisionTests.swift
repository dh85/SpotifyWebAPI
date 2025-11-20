import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct ReleaseDatePrecisionTests {

    @Test
    func hasCorrectRawValues() {
        #expect(ReleaseDatePrecision.year.rawValue == "year")
        #expect(ReleaseDatePrecision.month.rawValue == "month")
        #expect(ReleaseDatePrecision.day.rawValue == "day")
    }

    @Test
    func equatableWorksCorrectly() {
        #expect(ReleaseDatePrecision.year == ReleaseDatePrecision.year)
        #expect(ReleaseDatePrecision.year != ReleaseDatePrecision.month)
    }

    @Test
    func decodesFromRawValue() {
        #expect(ReleaseDatePrecision(rawValue: "year") == .year)
        #expect(ReleaseDatePrecision(rawValue: "month") == .month)
        #expect(ReleaseDatePrecision(rawValue: "day") == .day)
        #expect(ReleaseDatePrecision(rawValue: "invalid") == nil)
    }

    @Test
    func encodesCorrectly() throws {
        let encoder = JSONEncoder()
        let yearData = try encoder.encode(ReleaseDatePrecision.year)
        let monthData = try encoder.encode(ReleaseDatePrecision.month)
        let dayData = try encoder.encode(ReleaseDatePrecision.day)

        #expect(String(data: yearData, encoding: .utf8) == "\"year\"")
        #expect(String(data: monthData, encoding: .utf8) == "\"month\"")
        #expect(String(data: dayData, encoding: .utf8) == "\"day\"")
    }

    @Test
    func decodesCorrectly() throws {
        let decoder = JSONDecoder()
        let year = try decoder.decode(
            ReleaseDatePrecision.self, from: "\"year\"".data(using: .utf8)!)
        let month = try decoder.decode(
            ReleaseDatePrecision.self, from: "\"month\"".data(using: .utf8)!)
        let day = try decoder.decode(
            ReleaseDatePrecision.self, from: "\"day\"".data(using: .utf8)!)

        #expect(year == .year)
        #expect(month == .month)
        #expect(day == .day)
    }
}
