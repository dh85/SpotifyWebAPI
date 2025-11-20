import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct SpotifyCopyrightTests {

    @Test
    func copyrightTypeHasCorrectRawValues() {
        #expect(SpotifyCopyright.CopyrightType.copyright.rawValue == "C")
        #expect(SpotifyCopyright.CopyrightType.performance.rawValue == "P")
    }

    @Test
    func copyrightTypeDecodesFromRawValue() {
        #expect(SpotifyCopyright.CopyrightType(rawValue: "C") == .copyright)
        #expect(SpotifyCopyright.CopyrightType(rawValue: "P") == .performance)
        #expect(SpotifyCopyright.CopyrightType(rawValue: "invalid") == nil)
    }

    @Test
    func decodesCorrectly() throws {
        let json = """
            {
                "text": "2023 Record Label",
                "type": "C"
            }
            """
        let data = json.data(using: .utf8)!
        let copyright: SpotifyCopyright = try decodeModel(from: data)

        #expect(copyright.text == "2023 Record Label")
        #expect(copyright.type == .copyright)
    }

    @Test
    func decodesPerformanceCopyright() throws {
        let json = """
            {
                "text": "2023 Studio Productions",
                "type": "P"
            }
            """
        let data = json.data(using: .utf8)!
        let copyright: SpotifyCopyright = try decodeModel(from: data)

        #expect(copyright.text == "2023 Studio Productions")
        #expect(copyright.type == .performance)
    }

    @Test
    func encodesCorrectly() throws {
        let copyright = SpotifyCopyright(text: "2023 Label", type: .copyright)
        let encoder = JSONEncoder()
        let data = try encoder.encode(copyright)
        let decoded: SpotifyCopyright = try JSONDecoder().decode(
            SpotifyCopyright.self, from: data)

        #expect(decoded == copyright)
    }

    @Test
    func equatableWorksCorrectly() {
        let copyright1 = SpotifyCopyright(text: "2023 Label", type: .copyright)
        let copyright2 = SpotifyCopyright(text: "2023 Label", type: .copyright)
        let copyright3 = SpotifyCopyright(text: "2023 Label", type: .performance)
        let copyright4 = SpotifyCopyright(text: "Different", type: .copyright)

        #expect(copyright1 == copyright2)
        #expect(copyright1 != copyright3)
        #expect(copyright1 != copyright4)
    }
}
