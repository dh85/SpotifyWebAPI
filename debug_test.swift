import Foundation

// Simulate the array behavior
var metrics: [String] = []

// Add 150 items
for i in 0..<150 {
    metrics.append("test-op-\(i)")
}

print("Before limiting: \(metrics.count) items")
print("First 5: \(Array(metrics.prefix(5)))")
print("Last 5: \(Array(metrics.suffix(5)))")

// Apply the limiting logic
if metrics.count > 100 {
    metrics.removeFirst(metrics.count - 100)
}

print("\nAfter limiting: \(metrics.count) items")
print("First 5: \(Array(metrics.prefix(5)))")
print("Last 5: \(Array(metrics.suffix(5)))")
print("First item: \(metrics.first ?? "nil")")
print("Last item: \(metrics.last ?? "nil")")
