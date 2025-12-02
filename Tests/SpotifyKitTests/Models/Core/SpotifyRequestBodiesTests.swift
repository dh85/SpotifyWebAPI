import Foundation
import Testing

@testable import SpotifyKit

@Suite struct SpotifyRequestBodiesTests {

  @Test
  func idsBodyEncodesCorrectly() throws {
    let body = IDsBody(ids: ["id1", "id2", "id3"])
    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    let data = try encoder.encode(body)
    let json = String(data: data, encoding: .utf8)

    #expect(json?.contains("\"ids\"") == true)
    #expect(json?.contains("id1") == true)
    #expect(json?.contains("id2") == true)
    #expect(json?.contains("id3") == true)
  }

  @Test
  func idsBodyDecodesCorrectly() throws {
    let json = """
      {
          "ids": ["id1", "id2", "id3"]
      }
      """
    let data = json.data(using: .utf8)!
    let body = try JSONDecoder().decode(IDsBody.self, from: data)

    #expect(body.ids.count == 3)
    #expect(body.ids.contains("id1"))
    #expect(body.ids.contains("id2"))
    #expect(body.ids.contains("id3"))
  }

  @Test
  func idsBodyHandlesEmptySet() throws {
    let body = IDsBody(ids: [])
    let encoder = JSONEncoder()
    let data = try encoder.encode(body)
    let decoded = try JSONDecoder().decode(IDsBody.self, from: data)

    #expect(decoded.ids.isEmpty)
  }

  @Test
  func idsBodyRemovesDuplicates() throws {
    let json = """
      {
          "ids": ["id1", "id2", "id1", "id3", "id2"]
      }
      """
    let data = json.data(using: .utf8)!
    let body = try JSONDecoder().decode(IDsBody.self, from: data)

    #expect(body.ids.count == 3)
    #expect(body.ids.contains("id1"))
    #expect(body.ids.contains("id2"))
    #expect(body.ids.contains("id3"))
  }
}
