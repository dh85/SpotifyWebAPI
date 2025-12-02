import Foundation
import Testing

@testable import SpotifyKit

@Suite
struct HTTPMethodTests {

  @Test
  func rawValuesMatchHTTPVerbs() {
    #expect(HTTPMethod.get.rawValue == "GET")
    #expect(HTTPMethod.post.rawValue == "POST")
    #expect(HTTPMethod.put.rawValue == "PUT")
    #expect(HTTPMethod.delete.rawValue == "DELETE")
    #expect(HTTPMethod.patch.rawValue == "PATCH")
    #expect(HTTPMethod.head.rawValue == "HEAD")
    #expect(HTTPMethod.options.rawValue == "OPTIONS")
  }

  @Test
  func allowsBodyReflectsVerbSemantics() {
    #expect(HTTPMethod.get.allowsBody == false)
    #expect(HTTPMethod.head.allowsBody == false)
    #expect(HTTPMethod.post.allowsBody == true)
    #expect(HTTPMethod.put.allowsBody == true)
    #expect(HTTPMethod.delete.allowsBody == true)
    #expect(HTTPMethod.patch.allowsBody == true)
    #expect(HTTPMethod.options.allowsBody == true)
  }
}
