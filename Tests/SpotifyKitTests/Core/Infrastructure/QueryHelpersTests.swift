import Foundation
import Testing

@testable import SpotifyKit

@Suite
struct QueryHelpersTests {

  @Test
  func makePaginationQueryBuildsCorrectItems() {
    let items = makePaginationQuery(limit: 20, offset: 10)
    #expect(items.count == 2)
    #expect(items[0].name == "limit")
    #expect(items[0].value == "20")
    #expect(items[1].name == "offset")
    #expect(items[1].value == "10")
  }

  @Test
  func makeIDsQueryItemJoinsIDs() {
    let ids: Set<String> = ["id1", "id2", "id3"]
    let item = makeIDsQueryItem(from: ids)
    #expect(item.name == "ids")
    #expect(item.value?.contains("id1") == true)
    #expect(item.value?.contains("id2") == true)
    #expect(item.value?.contains("id3") == true)
  }

  @Test
  func makeMarketQueryItemsReturnsEmptyWhenNil() {
    let items = makeMarketQueryItems(from: nil)
    #expect(items.isEmpty)
  }

  @Test
  func makeMarketQueryItemsReturnsItemWhenPresent() {
    let items = makeMarketQueryItems(from: "US")
    #expect(items.count == 1)
    #expect(items[0].name == "market")
    #expect(items[0].value == "US")
  }

  @Test
  func makePagedMarketQueryCombinesPaginationAndMarket() throws {
    let items = try makePagedMarketQuery(limit: 10, offset: 5, market: "GB")
    #expect(items.count == 3)
    #expect(items.contains { $0.name == "limit" && $0.value == "10" })
    #expect(items.contains { $0.name == "offset" && $0.value == "5" })
    #expect(items.contains { $0.name == "market" && $0.value == "GB" })
  }

  @Test
  func buildPaginationQueryValidatesLimit() throws {
    do {
      _ = try buildPaginationQuery(limit: 100, offset: 0)
      Issue.record("Expected validation error for limit > 50")
    } catch {
      // Expected
    }
  }

  @Test
  func buildPaginationQuerySkipsValidationWhenDisabled() throws {
    let items = try buildPaginationQuery(limit: 100, offset: 0, validate: false)
    #expect(items.count == 2)
    #expect(items[0].value == "100")
  }

  @Test
  func queryBuilderStartsEmpty() {
    let builder = QueryBuilder()
    #expect(builder.build().isEmpty)
  }

  @Test
  func queryBuilderAddsItems() {
    let items = QueryBuilder()
      .adding([URLQueryItem(name: "test", value: "value")])
      .build()
    #expect(items.count == 1)
    #expect(items[0].name == "test")
    #expect(items[0].value == "value")
  }

  @Test
  func queryBuilderSkipsNilValues() {
    let items = QueryBuilder()
      .adding(name: "present", value: "yes")
      .adding(name: "missing", value: nil as String?)
      .build()
    #expect(items.count == 1)
    #expect(items[0].name == "present")
  }

  @Test
  func queryBuilderHandlesLosslessStringConvertible() {
    let items = QueryBuilder()
      .adding(name: "count", value: 42)
      .adding(name: "flag", value: true)
      .adding(name: "nil", value: nil as Int?)
      .build()
    #expect(items.count == 2)
    #expect(items.contains { $0.name == "count" && $0.value == "42" })
    #expect(items.contains { $0.name == "flag" && $0.value == "true" })
  }

  @Test
  func queryBuilderAddsPagination() throws {
    let items = try QueryBuilder()
      .addingPagination(limit: 20, offset: 10)
      .build()
    #expect(items.count == 2)
    #expect(items.contains { $0.name == "limit" && $0.value == "20" })
    #expect(items.contains { $0.name == "offset" && $0.value == "10" })
  }

  @Test
  func queryBuilderAddsMarket() {
    let items = QueryBuilder()
      .addingMarket("US")
      .build()
    #expect(items.count == 1)
    #expect(items[0].name == "market")
    #expect(items[0].value == "US")
  }

  @Test
  func queryBuilderAddsCountry() {
    let items = QueryBuilder()
      .addingCountry("FR")
      .build()
    #expect(items.count == 1)
    #expect(items[0].name == "country")
    #expect(items[0].value == "FR")
  }

  @Test
  func queryBuilderAddsLocale() {
    let items = QueryBuilder()
      .addingLocale("en_US")
      .build()
    #expect(items.count == 1)
    #expect(items[0].name == "locale")
    #expect(items[0].value == "en_US")
  }

  @Test
  func queryBuilderAddsFields() {
    let items = QueryBuilder()
      .addingFields("items(id,name)")
      .build()
    #expect(items.count == 1)
    #expect(items[0].name == "fields")
    #expect(items[0].value == "items(id,name)")
  }

  @Test
  func queryBuilderAddsAdditionalTypes() {
    let types: Set<AdditionalItemType> = [.track, .episode]
    let items = QueryBuilder()
      .addingAdditionalTypes(types)
      .build()
    #expect(items.count == 1)
    #expect(items[0].name == "additional_types")
    #expect(items[0].value?.contains("track") == true)
    #expect(items[0].value?.contains("episode") == true)
  }

  @Test
  func queryBuilderSkipsEmptyAdditionalTypes() {
    let items = QueryBuilder()
      .addingAdditionalTypes(Set<AdditionalItemType>())
      .build()
    #expect(items.isEmpty)
  }

  @Test
  func queryBuilderSkipsNilAdditionalTypes() {
    let items = QueryBuilder()
      .addingAdditionalTypes(nil)
      .build()
    #expect(items.isEmpty)
  }

  @Test
  func queryBuilderChainsMultipleOperations() throws {
    let items = try QueryBuilder()
      .addingPagination(limit: 10, offset: 0)
      .addingMarket("US")
      .addingFields("items")
      .adding(name: "custom", value: "value")
      .build()
    #expect(items.count == 5)
  }

  @Test
  func queryBuilderSkipsEmptyArrays() {
    let items = QueryBuilder()
      .adding([])
      .adding(name: "test", value: "value")
      .build()
    #expect(items.count == 1)
  }
}
