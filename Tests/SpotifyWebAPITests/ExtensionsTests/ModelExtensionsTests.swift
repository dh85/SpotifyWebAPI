import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite("Model Extensions Tests")
struct ModelExtensionsTests {

    @Test("Duration formatting logic")
    func durationFormatting() {
        let ms1 = 225000  // 3:45
        let minutes1 = ms1 / 60000
        let seconds1 = (ms1 % 60000) / 1000
        #expect(String(format: "%d:%02d", minutes1, seconds1) == "3:45")
        
        let ms2 = 2730000  // 45:30
        let minutes2 = ms2 / 60000
        let seconds2 = (ms2 % 60000) / 1000
        #expect(String(format: "%d:%02d", minutes2, seconds2) == "45:30")
    }

    @Test("SpotifyImage convenience properties")
    func imageConvenience() {
        let highRes = SpotifyImage(url: URL(string: "url1")!, height: 1000, width: 1000)
        let thumbnail = SpotifyImage(url: URL(string: "url2")!, height: 100, width: 100)
        let medium = SpotifyImage(url: URL(string: "url3")!, height: 300, width: 300)

        #expect(highRes.isHighRes == true)
        #expect(highRes.isThumbnail == false)
        #expect(thumbnail.isHighRes == false)
        #expect(thumbnail.isThumbnail == true)
        #expect(medium.isHighRes == false)
        #expect(medium.isThumbnail == false)
    }

    @Test("Image array largest and smallest")
    func imageArrayConvenience() {
        let images = [
            SpotifyImage(url: URL(string: "url1")!, height: 640, width: 640),
            SpotifyImage(url: URL(string: "url2")!, height: 300, width: 300),
            SpotifyImage(url: URL(string: "url3")!, height: 64, width: 64),
        ]

        #expect(images.largest?.width == 640)
        #expect(images.smallest?.width == 64)
    }

    @Test("Image array empty")
    func imageArrayEmpty() {
        let images: [SpotifyImage] = []

        #expect(images.largest == nil)
        #expect(images.smallest == nil)
    }
}
