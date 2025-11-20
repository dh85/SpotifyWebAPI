import Foundation

func makePaginationQuery(limit: Int, offset: Int) -> [URLQueryItem] {
    [
        .init(name: "limit", value: String(limit)),
        .init(name: "offset", value: String(offset))
    ]
}
