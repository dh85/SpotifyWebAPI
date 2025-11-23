import Foundation
import Testing

@testable import SpotifyWebAPI

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

@Suite
@MainActor
struct BrowseServiceTests {

    // MARK: - New Releases

    @Test(arguments: [nil, "US"])
    func newReleasesBuildsCorrectRequest(country: String?) async throws {
        try await withMockServiceClient(fixture: "new_releases.json") { client, http in
            let page = try await client.browse.newReleases(
                country: country,
                limit: 10,
                offset: 5
            )

            #expect(page.items.first?.name == "New Release One")

            let request = await http.firstRequest
            expectRequest(
                request, path: "/v1/browse/new-releases", method: "GET",
                queryContains: "limit=10", "offset=5")
            expectCountryParameter(request, country: country)
        }
    }

    // MARK: - Categories

    @Test
    func newReleasesUsesDefaultPagination() async throws {
        try await expectDefaultPagination(fixture: "new_releases.json") { client in
            _ = try await client.browse.newReleases()
        }
    }

    @Test
    func newReleasesThrowsErrorWhenLimitOutOfBounds() async throws {
        let (client, _) = makeUserAuthClient()
        await expectLimitErrors { limit in
            _ = try await client.browse.newReleases(limit: limit)
        }
    }

    @Test
    func streamNewReleasePagesBuildsRequests() async throws {
        let (client, http) = makeUserAuthClient()
        let data = try TestDataLoader.load("new_releases.json")
        await http.addMockResponse(data: data, statusCode: 200)

        var pages: [Int] = []
        let stream = await client.browse.streamNewReleasePages(
            country: "SE",
            pageSize: 20,
            maxPages: 1
        )
        for try await page in stream {
            pages.append(page.items.count)
        }

        #expect(pages.count == 1)
        let request = await http.firstRequest
        expectRequest(request, path: "/v1/browse/new-releases", method: "GET")
        expectCountryParameter(request, country: "SE")
        #expect(request?.url?.query()?.contains("limit=20") == true)
    }

    @Test
    func streamNewReleasesEmitsItems() async throws {
        let (client, http) = makeUserAuthClient()
        let data = try TestDataLoader.load("new_releases.json")
        await http.addMockResponse(data: data, statusCode: 200)

        var albums: [String] = []
        let stream = await client.browse.streamNewReleases(country: "DK", pageSize: 15)
        for try await album in stream {
            if let id = album.id {
                albums.append(id)
            }
        }

        #expect(albums.isEmpty == false)
        let request = await http.firstRequest
        expectRequest(request, path: "/v1/browse/new-releases", method: "GET")
        expectCountryParameter(request, country: "DK")
        #expect(request?.url?.query()?.contains("limit=15") == true)
    }

    // MARK: - Categories

    @Test(arguments: [nil, "US"])
    func categoryBuildsCorrectRequest(country: String?) async throws {
        try await withMockServiceClient(fixture: "category_single.json") { client, http in
            let category = try await client.browse.category(
                id: "party",
                country: country,
                locale: "es_MX"
            )

            #expect(category.id == "party")
            #expect(category.name == "Party")

            let request = await http.firstRequest
            expectRequest(
                request, path: "/v1/browse/categories/party", method: "GET",
                queryContains: "locale=es_MX")
            expectCountryParameter(request, country: country)
            expectLocaleParameter(request, locale: "es_MX")
        }
    }

    @Test
    func categoriesBuildsCorrectRequest() async throws {
        try await withMockServiceClient(fixture: "categories_several.json") { client, http in
            let page = try await client.browse.categories(
                country: "US",
                locale: "sv_SE",
                limit: 5,
                offset: 0
            )

            #expect(page.items.first?.id == "toplists")

            let request = await http.firstRequest
            expectRequest(
                request, path: "/v1/browse/categories", method: "GET",
                queryContains: "country=US", "locale=sv_SE", "limit=5")
        }
    }

    @Test
    func categoriesUsesDefaultPagination() async throws {
        try await expectDefaultPagination(fixture: "categories_several.json") { client in
            _ = try await client.browse.categories()
        }
    }

    @Test
    func categoriesThrowsErrorWhenLimitOutOfBounds() async throws {
        let (client, _) = makeUserAuthClient()
        await expectLimitErrors { limit in
            _ = try await client.browse.categories(limit: limit)
        }
    }

    @Test
    func streamCategoryPagesBuildsRequests() async throws {
        let (client, http) = makeUserAuthClient()
        let data = try TestDataLoader.load("categories_several.json")
        await http.addMockResponse(data: data, statusCode: 200)

        var pages: [Int] = []
        let stream = await client.browse.streamCategoryPages(
            country: "MX",
            locale: "es_MX",
            pageSize: 20,
            maxPages: 1
        )
        for try await page in stream {
            pages.append(page.items.count)
        }

        #expect(pages.count == 1)
        let request = await http.firstRequest
        expectRequest(request, path: "/v1/browse/categories", method: "GET")
        expectCountryParameter(request, country: "MX")
        expectLocaleParameter(request, locale: "es_MX")
        #expect(request?.url?.query()?.contains("limit=20") == true)
    }

    @Test
    func streamCategoriesEmitsItems() async throws {
        let (client, http) = makeUserAuthClient()
        let data = try TestDataLoader.load("categories_several.json")
        await http.addMockResponse(data: data, statusCode: 200)

        var categories: [String] = []
        let stream = await client.browse.streamCategories(
            country: "BR",
            locale: "pt_BR",
            pageSize: 25,
            maxItems: 25
        )
        for try await category in stream {
            categories.append(category.id)
        }

        #expect(categories.isEmpty == false)
        let request = await http.firstRequest
        expectRequest(request, path: "/v1/browse/categories", method: "GET")
        expectCountryParameter(request, country: "BR")
        expectLocaleParameter(request, locale: "pt_BR")
        #expect(request?.url?.query()?.contains("limit=25") == true)
    }

    // MARK: - Available Markets

    @Test
    func availableMarketsBuildsCorrectRequest() async throws {
        try await withMockServiceClient(fixture: "available_markets.json") { client, http in
            let markets = try await client.browse.availableMarkets()

            #expect(markets.count == 3)
            #expect(markets.contains("CA"))
            #expect(markets.contains("MX"))
            #expect(markets.contains("US"))

            expectRequest(await http.firstRequest, path: "/v1/markets", method: "GET")
        }
    }

    @Test
    func categoryOmitsLocaleWhenNil() async throws {
        try await withMockServiceClient(fixture: "category_single.json") { client, http in
            _ = try await client.browse.category(id: "party", country: "US", locale: nil)
            let request = await http.firstRequest
            expectRequest(request, path: "/v1/browse/categories/party", method: "GET")
            expectCountryParameter(request, country: "US")
            expectLocaleParameter(request, locale: nil)
        }
    }

    @Test
    func availableMarketsPropagatesHTTPError() async throws {
        let configuration = SpotifyClientConfiguration(networkRecovery: .disabled)
        try await withMockServiceClient(
            fixture: nil,
            configuration: configuration
        ) { client, http in
            await http.addMockResponse(statusCode: 500)
            await #expect(throws: SpotifyClientError.httpError(statusCode: 500, body: "")) {
                _ = try await client.browse.availableMarkets()
            }
            expectRequest(await http.firstRequest, path: "/v1/markets", method: "GET")
        }
    }
}
