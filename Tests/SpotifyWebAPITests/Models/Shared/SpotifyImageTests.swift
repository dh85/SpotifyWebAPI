import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct SpotifyImageTests {

    @Test
    func decodesWithAllFields() throws {
        let json = """
            {
                "url": "https://i.scdn.co/image/ab67616d0000b273",
                "height": 640,
                "width": 640
            }
            """
        let data = json.data(using: .utf8)!
        let image: SpotifyImage = try decodeModel(from: data)

        #expect(image.url.absoluteString == "https://i.scdn.co/image/ab67616d0000b273")
        #expect(image.height == 640)
        #expect(image.width == 640)
    }

    @Test
    func decodesWithoutDimensions() throws {
        let json = """
            {
                "url": "https://i.scdn.co/image/ab67616d0000b273",
                "height": null,
                "width": null
            }
            """
        let data = json.data(using: .utf8)!
        let image: SpotifyImage = try decodeModel(from: data)

        #expect(image.url.absoluteString == "https://i.scdn.co/image/ab67616d0000b273")
        #expect(image.height == nil)
        #expect(image.width == nil)
    }

    @Test
    func decodesWithOnlyUrl() throws {
        let json = """
            {
                "url": "https://i.scdn.co/image/test"
            }
            """
        let data = json.data(using: .utf8)!
        let image: SpotifyImage = try decodeModel(from: data)

        #expect(image.url.absoluteString == "https://i.scdn.co/image/test")
        #expect(image.height == nil)
        #expect(image.width == nil)
    }

    @Test
    func encodesCorrectly() throws {
        let image = SpotifyImage(
            url: URL(string: "https://i.scdn.co/image/test")!,
            height: 300,
            width: 300
        )
        let encoder = JSONEncoder()
        let data = try encoder.encode(image)
        let decoded: SpotifyImage = try JSONDecoder().decode(SpotifyImage.self, from: data)

        #expect(decoded == image)
    }

    @Test
    func equatableWorksCorrectly() {
        let image1 = SpotifyImage(
            url: URL(string: "https://i.scdn.co/image/1")!, height: 640, width: 640)
        let image2 = SpotifyImage(
            url: URL(string: "https://i.scdn.co/image/1")!, height: 640, width: 640)
        let image3 = SpotifyImage(
            url: URL(string: "https://i.scdn.co/image/2")!, height: 640, width: 640)
        let image4 = SpotifyImage(
            url: URL(string: "https://i.scdn.co/image/1")!, height: 300, width: 300)

        #expect(image1 == image2)
        #expect(image1 != image3)
        #expect(image1 != image4)
    }
}
