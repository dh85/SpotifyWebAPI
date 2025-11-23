import Testing

@testable import SpotifyWebAPI

@Suite("Spotify API Limits")
struct SpotifyAPILimitsTests {

    @Test("Library limits match Spotify documentation")
    func libraryLimits() {
        #expect(SpotifyAPILimits.Albums.batchSize == 20)
        #expect(SpotifyAPILimits.Tracks.libraryBatchSize == 50)
        #expect(SpotifyAPILimits.Tracks.catalogBatchSize == 50)
        #expect(SpotifyAPILimits.Shows.batchSize == 50)
        #expect(SpotifyAPILimits.Episodes.batchSize == 50)
        #expect(SpotifyAPILimits.Audiobooks.batchSize == 50)
        #expect(SpotifyAPILimits.Chapters.batchSize == 50)
        #expect(SpotifyAPILimits.Artists.batchSize == 50)
    }

    @Test("Playlist limits stay in sync")
    func playlistLimits() {
        #expect(SpotifyAPILimits.Playlists.itemMutationBatchSize == 100)
        #expect(SpotifyAPILimits.Playlists.positionMutationBatchSize == 100)
    }

    @Test("Pagination and search limits share standard range")
    func paginationLimits() {
        let range = SpotifyAPILimits.Pagination.standardLimitRange
        #expect(range == 1...50)
        #expect(range.upperBound == SpotifyAPILimits.Search.maxLimitPerType)
    }

    @Test("User follow limits stay consistent")
    func userLimits() {
        #expect(SpotifyAPILimits.Users.followBatchSize == 50)
        #expect(SpotifyAPILimits.Users.playlistFollowerCheckBatchSize == 5)
    }
}
