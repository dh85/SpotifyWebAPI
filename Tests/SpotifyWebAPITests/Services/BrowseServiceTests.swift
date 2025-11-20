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
        let (client, http) = makeUserAuthClient()
        let data = try TestDataLoader.load("new_releases.json")
        await http.addMockResponse(data: data, statusCode: 200)

        let page = try await client.browse.newReleases(
            country: country,
            limit: 10,
            offset: 5
        )

        #expect(page.items.first?.name == "New Release One")

        expectRequest(
            await http.firstRequest, path: "/v1/browse/new-releases", method: "GET",
            queryContains: "limit=10", "offset=5")
        expectCountryParameter(await http.firstRequest, country: country)
    }

    // MARK: - Categories

    @Test
    func newReleasesUsesDefaultPagination() async throws {
        let (client, http) = makeUserAuthClient()
        let data = try TestDataLoader.load("new_releases.json")
        await http.addMockResponse(data: data, statusCode: 200)

        _ = try await client.browse.newReleases()

        expectPaginationDefaults(await http.firstRequest)
    }

    @Test
    func newReleasesThrowsErrorWhenLimitOutOfBounds() async throws {
        let (client, _) = makeUserAuthClient()
        await expectLimitErrors { limit in
            _ = try await client.browse.newReleases(limit: limit)
        }
    }

    // MARK: - Categories

    @Test(arguments: [nil, "US"])
    func categoryBuildsCorrectRequest(country: String?) async throws {
        let (client, http) = makeUserAuthClient()
        let data = try TestDataLoader.load("category_single.json")
        await http.addMockResponse(data: data, statusCode: 200)

        let category = try await client.browse.category(
            id: "party",
            country: country,
            locale: "es_MX"
        )

        #expect(category.id == "party")
        #expect(category.name == "Party")

        expectRequest(
            await http.firstRequest, path: "/v1/browse/categories/party", method: "GET",
            queryContains: "locale=es_MX")
        expectCountryParameter(await http.firstRequest, country: country)
    }

    @Test
    func categoriesBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        let data = try TestDataLoader.load("categories_several.json")
        await http.addMockResponse(data: data, statusCode: 200)

        let page = try await client.browse.categories(
            country: "US",
            locale: "sv_SE",
            limit: 5,
            offset: 0
        )

        #expect(page.items.first?.id == "toplists")

        expectRequest(
            await http.firstRequest, path: "/v1/browse/categories", method: "GET",
            queryContains: "country=US", "locale=sv_SE", "limit=5")
    }

    @Test
    func categoriesUsesDefaultPagination() async throws {
        let (client, http) = makeUserAuthClient()
        let data = try TestDataLoader.load("categories_several.json")
        await http.addMockResponse(data: data, statusCode: 200)

        _ = try await client.browse.categories()

        expectPaginationDefaults(await http.firstRequest)
    }

    @Test
    func categoriesThrowsErrorWhenLimitOutOfBounds() async throws {
        let (client, _) = makeUserAuthClient()
        await expectLimitErrors { limit in
            _ = try await client.browse.categories(limit: limit)
        }
    }

    // MARK: - Available Markets

    @Test
    func availableMarketsBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        let data = try TestDataLoader.load("available_markets.json")
        await http.addMockResponse(data: data, statusCode: 200)

        let markets = try await client.browse.availableMarkets()

        #expect(markets.count == 3)
        #expect(markets.contains("CA"))
        #expect(markets.contains("MX"))
        #expect(markets.contains("US"))

        expectRequest(await http.firstRequest, path: "/v1/markets", method: "GET")
    }

    // MARK: - Helper Methods

    private func expectCountryParameter(_ request: URLRequest?, country: String?) {
        if let country {
            #expect(request?.url?.query()?.contains("country=\(country)") == true)
        } else {
            #expect(request?.url?.query()?.contains("country=") == false)
        }
    }
}
