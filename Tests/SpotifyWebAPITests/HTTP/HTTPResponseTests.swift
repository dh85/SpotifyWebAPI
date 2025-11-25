import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite("HTTPResponse Utility Tests")
struct HTTPResponseTests {

    @Test("isSuccess returns true for 2xx status codes")
    func isSuccessReturnsTrue() {
        let responses = [200, 201, 204, 299].map { makeResponse(statusCode: $0) }
        for response in responses {
            #expect(response.isSuccess == true)
        }
    }

    @Test("isSuccess returns false for non-2xx status codes")
    func isSuccessReturnsFalse() {
        let responses = [199, 300, 400, 500].map { makeResponse(statusCode: $0) }
        for response in responses {
            #expect(response.isSuccess == false)
        }
    }

    @Test("isClientError returns true for 4xx status codes")
    func isClientErrorReturnsTrue() {
        let responses = [400, 401, 403, 404, 429, 499].map { makeResponse(statusCode: $0) }
        for response in responses {
            #expect(response.isClientError == true)
        }
    }

    @Test("isClientError returns false for non-4xx status codes")
    func isClientErrorReturnsFalse() {
        let responses = [200, 300, 399, 500].map { makeResponse(statusCode: $0) }
        for response in responses {
            #expect(response.isClientError == false)
        }
    }

    @Test("isServerError returns true for 5xx status codes")
    func isServerErrorReturnsTrue() {
        let responses = [500, 502, 503, 504, 599].map { makeResponse(statusCode: $0) }
        for response in responses {
            #expect(response.isServerError == true)
        }
    }

    @Test("isServerError returns false for non-5xx status codes")
    func isServerErrorReturnsFalse() {
        let responses = [200, 300, 400, 499, 600].map { makeResponse(statusCode: $0) }
        for response in responses {
            #expect(response.isServerError == false)
        }
    }

    @Test("isError returns true for 4xx and 5xx status codes")
    func isErrorReturnsTrue() {
        let responses = [400, 404, 429, 500, 503].map { makeResponse(statusCode: $0) }
        for response in responses {
            #expect(response.isError == true)
        }
    }

    @Test("isError returns false for non-error status codes")
    func isErrorReturnsFalse() {
        let responses = [200, 201, 300, 301].map { makeResponse(statusCode: $0) }
        for response in responses {
            #expect(response.isError == false)
        }
    }

    @Test("statusCodeRange returns correct categories")
    func statusCodeRangeReturnsCorrectCategories() {
        #expect(makeResponse(statusCode: 100).statusCodeRange == .informational)
        #expect(makeResponse(statusCode: 199).statusCodeRange == .informational)
        #expect(makeResponse(statusCode: 200).statusCodeRange == .success)
        #expect(makeResponse(statusCode: 299).statusCodeRange == .success)
        #expect(makeResponse(statusCode: 300).statusCodeRange == .redirection)
        #expect(makeResponse(statusCode: 399).statusCodeRange == .redirection)
        #expect(makeResponse(statusCode: 400).statusCodeRange == .clientError)
        #expect(makeResponse(statusCode: 499).statusCodeRange == .clientError)
        #expect(makeResponse(statusCode: 500).statusCodeRange == .serverError)
        #expect(makeResponse(statusCode: 599).statusCodeRange == .serverError)
        #expect(makeResponse(statusCode: 600).statusCodeRange == nil)
        #expect(makeResponse(statusCode: 99).statusCodeRange == nil)
    }

    @Test("header retrieves value case-insensitively")
    func headerRetrievesValueCaseInsensitively() {
        let response = makeResponse(
            statusCode: 200,
            headers: [
                "Content-Type": "application/json",
                "X-Custom-Header": "custom-value",
                "Retry-After": "60"
            ]
        )

        #expect(response.header(named: "Content-Type") == "application/json")
        #expect(response.header(named: "content-type") == "application/json")
        #expect(response.header(named: "CONTENT-TYPE") == "application/json")
        #expect(response.header(named: "X-Custom-Header") == "custom-value")
        #expect(response.header(named: "x-custom-header") == "custom-value")
        #expect(response.header(named: "Retry-After") == "60")
        #expect(response.header(named: "retry-after") == "60")
    }

    @Test("header returns nil for missing headers")
    func headerReturnsNilForMissingHeaders() {
        let response = makeResponse(
            statusCode: 200,
            headers: ["Content-Type": "application/json"]
        )

        #expect(response.header(named: "X-Missing-Header") == nil)
        #expect(response.header(named: "Authorization") == nil)
    }

    @Test("headerInt parses integer values")
    func headerIntParsesIntegerValues() {
        let response = makeResponse(
            statusCode: 200,
            headers: [
                "Content-Length": "1234",
                "Retry-After": "60",
                "X-RateLimit-Remaining": "100"
            ]
        )

        #expect(response.headerInt(named: "Content-Length") == 1234)
        #expect(response.headerInt(named: "Retry-After") == 60)
        #expect(response.headerInt(named: "X-RateLimit-Remaining") == 100)
    }

    @Test("headerInt returns nil for non-integer values")
    func headerIntReturnsNilForNonIntegerValues() {
        let response = makeResponse(
            statusCode: 200,
            headers: [
                "Content-Type": "application/json",
                "X-Invalid": "not-a-number"
            ]
        )

        #expect(response.headerInt(named: "Content-Type") == nil)
        #expect(response.headerInt(named: "X-Invalid") == nil)
        #expect(response.headerInt(named: "X-Missing") == nil)
    }

    // MARK: - Helpers

    private func makeResponse(
        statusCode: Int,
        headers: [String: String] = [:]
    ) -> HTTPResponse {
        let url = URL(string: "https://api.spotify.com/test")!
        let urlResponse = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: headers
        )!
        return HTTPResponse(data: Data(), response: urlResponse)
    }
}
