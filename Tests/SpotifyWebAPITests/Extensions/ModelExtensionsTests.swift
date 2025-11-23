import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite("Model Extensions Tests")
struct ModelExtensionsTests {

    @Test("Duration formatting")
    func durationFormatting() {
        #expect(formatDuration(225000) == "3:45")
        #expect(formatDuration(2730000) == "45:30")
        #expect(formatDuration(60000) == "1:00")
        #expect(formatDuration(0) == "0:00")
    }

    @Test("Artist names joining")
    func artistNamesJoining() {
        let names = ["Artist One", "Artist Two", "Artist Three"]
        let result = names.joined(separator: ", ")
        #expect(result == "Artist One, Artist Two, Artist Three")
    }

    @Test("SpotifyImage isHighRes")
    func imageIsHighRes() {
        #expect(SpotifyImage(url: URL(string: "url")!, height: 1000, width: 1000).isHighRes == true)
        #expect(SpotifyImage(url: URL(string: "url")!, height: 640, width: 640).isHighRes == true)
        #expect(SpotifyImage(url: URL(string: "url")!, height: 639, width: 639).isHighRes == false)
        #expect(SpotifyImage(url: URL(string: "url")!, height: 300, width: nil).isHighRes == false)
    }

    @Test("SpotifyImage isThumbnail")
    func imageIsThumbnail() {
        #expect(SpotifyImage(url: URL(string: "url")!, height: 64, width: 64).isThumbnail == true)
        #expect(SpotifyImage(url: URL(string: "url")!, height: 199, width: 199).isThumbnail == true)
        #expect(SpotifyImage(url: URL(string: "url")!, height: 200, width: 200).isThumbnail == false)
        #expect(SpotifyImage(url: URL(string: "url")!, height: 300, width: nil).isThumbnail == false)
    }

    @Test("Image array largest")
    func imageArrayLargest() {
        let images = [
            SpotifyImage(url: URL(string: "url1")!, height: 640, width: 640),
            SpotifyImage(url: URL(string: "url2")!, height: 300, width: 300),
            SpotifyImage(url: URL(string: "url3")!, height: 64, width: 64)
        ]
        #expect(images.largest?.width == 640)
    }

    @Test("Image array smallest")
    func imageArraySmallest() {
        let images = [
            SpotifyImage(url: URL(string: "url1")!, height: 640, width: 640),
            SpotifyImage(url: URL(string: "url2")!, height: 300, width: 300),
            SpotifyImage(url: URL(string: "url3")!, height: 64, width: 64)
        ]
        #expect(images.smallest?.width == 64)
    }

    @Test("Image array empty")
    func imageArrayEmpty() {
        let images: [SpotifyImage] = []
        #expect(images.largest == nil)
        #expect(images.smallest == nil)
    }

    @Test("Image array with nil widths")
    func imageArrayNilWidths() {
        let images = [
            SpotifyImage(url: URL(string: "url1")!, height: 640, width: nil),
            SpotifyImage(url: URL(string: "url2")!, height: 300, width: 300),
            SpotifyImage(url: URL(string: "url3")!, height: 64, width: nil)
        ]
        #expect(images.largest?.width == 300)
        #expect(images.smallest?.width == nil)
    }
}

// MARK: - Helpers

fileprivate func formatDuration(_ ms: Int) -> String {
    let minutes = ms / 60000
    let seconds = (ms % 60000) / 1000
    return String(format: "%d:%02d", minutes, seconds)
}
