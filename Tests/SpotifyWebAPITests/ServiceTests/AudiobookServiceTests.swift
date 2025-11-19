import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct AudiobookServiceTests {

    /// Helper to create a user-auth client with mocks
    @MainActor
    private func makeClient() -> (
        client: SpotifyClient<UserAuthCapability>, http: MockHTTPClient
    ) {
        let http = MockHTTPClient()
        let auth = MockTokenAuthenticator(token: .mockValid)
        let client = SpotifyClient<UserAuthCapability>(
            backend: auth,
            httpClient: http
        )
        return (client, http)
    }

    // MARK: - Public Access Tests

    @Test
    @MainActor
    func getAudiobook_buildsCorrectRequest_withMarket() async throws {
        let (client, http) = makeClient()
        let data = try TestDataLoader.load("audiobook_full.json")
        await http.addMockResponse(data: data, statusCode: 200)

        let audiobookId = "7iHfbu1YPACw6oZPAFJtqe"

        let audiobook = try await client.audiobooks.get(
            audiobookId,
            market: "US"
        )

        #expect(audiobook.id == audiobookId)
        #expect(audiobook.name == "Dune: Book One in the Dune Chronicles")

        let request = await http.firstRequest
        #expect(request?.url?.path() == "/v1/audiobooks/\(audiobookId)")
        #expect(request?.httpMethod == "GET")
        #expect(request?.url?.query()?.contains("market=US") == true)
    }

    @Test
    @MainActor
    func getAudiobook_nilMarket_omitsQueryParameter() async throws {
        let (client, http) = makeClient()
        let data = try TestDataLoader.load("audiobook_full.json")
        await http.addMockResponse(data: data, statusCode: 200)

        let audiobookId = "7iHfbu1YPACw6oZPAFJtqe"

        _ = try await client.audiobooks.get(audiobookId, market: nil)

        let request = await http.firstRequest
        #expect(request?.url?.path() == "/v1/audiobooks/\(audiobookId)")
        #expect(request?.url?.query()?.contains("market=") == false)
        #expect(request?.httpMethod == "GET")
    }

    @Test
    @MainActor
    func severalAudiobooks_buildsCorrectRequest_andUnwrapsDTO() async throws {
        let (client, http) = makeClient()
        let data = try TestDataLoader.load("audiobooks_several.json")
        await http.addMockResponse(data: data, statusCode: 200)

        let audiobooks = try await client.audiobooks.several(
            ids: [
                "18yVqkdbdRvS24c0Ilj2ci",
                "1HGw3J3NxZO1TP1BTtVhpZ",
                "7iHfbu1YPACw6oZPAFJtqe",
            ],
            market: "ES"
        )

        #expect(audiobooks.count == 3)
        #expect(audiobooks[2]?.name == "Dune: Book One in the Dune Chronicles")

        let request = await http.firstRequest
        #expect(request?.url?.path() == "/v1/audiobooks")
        #expect(request?.httpMethod == "GET")
        #expect(
            request?.url?.query()?.contains(
                "ids=18yVqkdbdRvS24c0Ilj2ci,1HGw3J3NxZO1TP1BTtVhpZ"
            ) == true
        )
        #expect(request?.url?.query()?.contains("market=ES") == true)
    }

    @Test
    @MainActor
    func severalAudiobooks_nilMarket_omitsQueryParameter() async throws {
        let (client, http) = makeClient()
        let data = try TestDataLoader.load("audiobooks_several.json")
        await http.addMockResponse(data: data, statusCode: 200)

        _ = try await client.audiobooks.several(
            ids: [
                "18yVqkdbdRvS24c0Ilj2ci",
                "1HGw3J3NxZO1TP1BTtVhpZ",
                "7iHfbu1YPACw6oZPAFJtqe",
            ],
            market: nil
        )

        let request = await http.firstRequest
        #expect(request?.url?.path() == "/v1/audiobooks")
        #expect(
            request?.url?.query()?.contains(
                "ids=18yVqkdbdRvS24c0Ilj2ci,1HGw3J3NxZO1TP1BTtVhpZ"
            ) == true
        )
        // Verify market parameter is completely absent
        #expect(request?.url?.query()?.contains("market=") == false)
    }

    @Test(arguments: [nil, "ES"])
    @MainActor
    func audiobookChapters_buildsCorrectRequest(market: String?) async throws {
        let (client, http) = makeClient()
        let data = try TestDataLoader.load("audiobook_chapters.json")
        await http.addMockResponse(data: data, statusCode: 200)

        let page = try await client.audiobooks.chapters(
            for: "7iHfbu1YPACw6oZPAFJtqe",
            limit: 10,
            offset: 5,
            market: market
        )

        #expect(page.items.count == 20)
        #expect(page.items.first?.name == "Opening Credits")

        let request = await http.firstRequest
        #expect(
            request?.url?.path()
                == "/v1/audiobooks/7iHfbu1YPACw6oZPAFJtqe/chapters"
        )
        #expect(request?.httpMethod == "GET")
        #expect(request?.url?.query()?.contains("limit=10") == true)
        #expect(request?.url?.query()?.contains("offset=5") == true)

        if let market {
            #expect(request?.url?.query()?.contains("market=\(market)") == true)
        } else {
            #expect(request?.url?.query()?.contains("market=") == false)
        }
    }

    // MARK: - User Access Tests

    @Test
    @MainActor
    func savedAudiobooks_buildsCorrectRequest() async throws {
        let (client, http) = makeClient()
        let data = try TestDataLoader.load("audiobooks_saved.json")
        await http.addMockResponse(data: data, statusCode: 200)

        let page = try await client.audiobooks.saved(limit: 5, offset: 0)

        #expect(page.items.first?.audiobook.name == "Saved Audiobook Title")

        let request = await http.firstRequest
        #expect(request?.url?.path() == "/v1/me/audiobooks")
        #expect(request?.httpMethod == "GET")
        #expect(request?.url?.query()?.contains("limit=5") == true)
        // Ensure market is NOT present (not supported by this endpoint)
        #expect(request?.url?.query()?.contains("market=") == false)
    }

    @Test
    @MainActor
    func saveAudiobooks_buildsCorrectRequest() async throws {
        let (client, http) = makeClient()
        await http.addMockResponse(statusCode: 200)  // PUT 200 OK
        let ids = Set([
            "18yVqkdbdRvS24c0Ilj2ci",
            "1HGw3J3NxZO1TP1BTtVhpZ",
            "7iHfbu1YPACw6oZPAFJtqe",
        ])

        try await client.audiobooks.save(ids)

        let request = await http.firstRequest
        #expect(request?.url?.path() == "/v1/me/audiobooks")
        #expect(request?.httpMethod == "PUT")

        if let bodyData = request?.httpBody,
            let body = try? JSONDecoder().decode(IDsBody.self, from: bodyData)
        {
            #expect(body.ids == ids)
        } else {
            Issue.record("Failed to decode HTTP body")
        }
    }

    @Test
    @MainActor
    func removeAudiobooks_buildsCorrectRequest() async throws {
        let (client, http) = makeClient()
        await http.addMockResponse(statusCode: 200)  // DELETE 200 OK
        let ids = Set([
            "18yVqkdbdRvS24c0Ilj2ci",
            "1HGw3J3NxZO1TP1BTtVhpZ",
            "7iHfbu1YPACw6oZPAFJtqe",
        ])

        try await client.audiobooks.remove(ids)

        let request = await http.firstRequest
        #expect(request?.url?.path() == "/v1/me/audiobooks")
        #expect(request?.httpMethod == "DELETE")

        if let bodyData = request?.httpBody,
            let body = try? JSONDecoder().decode(IDsBody.self, from: bodyData)
        {
            #expect(body.ids == ids)
        } else {
            Issue.record("Failed to decode HTTP body")
        }
    }

    @Test
    @MainActor
    func checkSavedAudiobooks_buildsCorrectRequest() async throws {
        let (client, http) = makeClient()
        let data = try TestDataLoader.load("check_saved_audiobooks.json")
        await http.addMockResponse(data: data, statusCode: 200)
        let ids = Set([
            "18yVqkdbdRvS24c0Ilj2ci",
            "1HGw3J3NxZO1TP1BTtVhpZ",
            "7iHfbu1YPACw6oZPAFJtqe",
        ])

        let results = try await client.audiobooks.checkSaved(ids)

        #expect(results == [false, false, true])

        let request = await http.firstRequest
        #expect(request?.url?.path() == "/v1/me/audiobooks/contains")
        #expect(request?.httpMethod == "GET")
        #expect(
            request?.url?.query()?.contains(
                "ids=18yVqkdbdRvS24c0Ilj2ci,1HGw3J3NxZO1TP1BTtVhpZ"
            ) == true
        )
    }
}
