import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct BrowseServiceTests {

    /// Helper to create a client with mocks
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

    // MARK: - New Releases

    @Test(arguments: [nil, "US"])
    @MainActor
    func newReleases_buildsCorrectRequest(country: String?) async throws {
        let (client, http) = makeClient()
        let data = try TestDataLoader.load("new_releases.json")
        await http.addMockResponse(data: data, statusCode: 200)

        let page = try await client.browse.newReleases(
            country: country,
            limit: 10,
            offset: 5
        )

        #expect(page.items.first?.name == "New Release One")

        let request = await http.firstRequest
        #expect(request?.url?.path() == "/v1/browse/new-releases")
        #expect(request?.httpMethod == "GET")
        #expect(request?.url?.query()?.contains("limit=10") == true)
        #expect(request?.url?.query()?.contains("offset=5") == true)

        if let country {
            #expect(
                request?.url?.query()?.contains("country=\(country)") == true
            )
        } else {
            #expect(request?.url?.query()?.contains("country=") == false)
        }
    }

    // MARK: - Categories

    @Test(arguments: [nil, "US"])
    @MainActor
    func singleCategory_buildsCorrectRequest(country: String?) async throws {
        let (client, http) = makeClient()
        let data = try TestDataLoader.load("category_single.json")
        await http.addMockResponse(data: data, statusCode: 200)

        let category = try await client.browse.category(
            id: "party",
            country: country,
            locale: "es_MX"
        )

        #expect(category.id == "party")
        #expect(category.name == "Party")

        let request = await http.firstRequest
        #expect(request?.url?.path() == "/v1/browse/categories/party")
        #expect(request?.httpMethod == "GET")

        // Locale should always be present based on our call
        #expect(request?.url?.query()?.contains("locale=es_MX") == true)

        if let country {
            #expect(
                request?.url?.query()?.contains("country=\(country)") == true
            )
        } else {
            #expect(request?.url?.query()?.contains("country=") == false)
        }
    }

    @Test
    @MainActor
    func severalCategories_buildsCorrectRequest_andUnwrapsDTO() async throws {
        let (client, http) = makeClient()
        let data = try TestDataLoader.load("categories_several.json")
        await http.addMockResponse(data: data, statusCode: 200)

        let page = try await client.browse.categories(
            country: "US",
            locale: "sv_SE",
            limit: 5,
            offset: 0
        )

        #expect(page.items.first?.id == "toplists")

        let request = await http.firstRequest
        #expect(request?.url?.path() == "/v1/browse/categories")
        #expect(request?.url?.query()?.contains("country=US") == true)
        #expect(request?.url?.query()?.contains("locale=sv_SE") == true)
        #expect(request?.url?.query()?.contains("limit=5") == true)
    }

    // MARK: - Available Markets

    @Test
    @MainActor
    func availableMarkets_buildsCorrectRequest_andUnwrapsDTO() async throws {
        let (client, http) = makeClient()
        let data = try TestDataLoader.load("available_markets.json")
        await http.addMockResponse(data: data, statusCode: 200)

        let markets = try await client.browse.availableMarkets()

        #expect(markets.count == 3)
        #expect(markets.contains("CA"))
        #expect(markets.contains("MX"))
        #expect(markets.contains("US"))

        let request = await http.firstRequest
        #expect(request?.url?.path() == "/v1/markets")
        #expect(request?.httpMethod == "GET")
    }
}
