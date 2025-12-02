import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

// MARK: - Batch Helpers

func chunkedUniqueSets(from ids: [String], chunkSize: Int) -> [Set<String>] {
  precondition(chunkSize > 0, "chunkSize must be greater than zero")

  var seen = Set<String>()
  var current: [String] = []
  var batches: [[String]] = []

  for id in ids {
    guard seen.insert(id).inserted else { continue }
    current.append(id)
    if current.count == chunkSize {
      batches.append(current)
      current.removeAll(keepingCapacity: true)
    }
  }

  if !current.isEmpty {
    batches.append(current)
  }

  return batches.map { Set($0) }
}

func chunkedArrays<T>(from items: [T], chunkSize: Int) -> [[T]] {
  precondition(chunkSize > 0, "chunkSize must be greater than zero")
  guard !items.isEmpty else { return [] }

  var result: [[T]] = []
  var index = 0
  while index < items.count {
    let end = min(index + chunkSize, items.count)
    result.append(Array(items[index..<end]))
    index = end
  }
  return result
}
