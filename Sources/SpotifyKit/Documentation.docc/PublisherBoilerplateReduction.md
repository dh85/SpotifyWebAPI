# Combine Publisher Boilerplate Reduction

This document demonstrates how the `PublisherGenerators` helpers reduce boilerplate when creating Combine publishers from async/await methods.

## Overview

The `PublisherGenerators.swift` file provides generic helper methods that simplify creating publishers by leveraging Swift's type inference and method references.

## Before (Current Pattern)

Each publisher method requires explicit closure syntax:

```swift
public func getPublisher(
    _ id: String,
    market: String? = nil,
    priority: TaskPriority? = nil
) -> AnyPublisher<Album, Error> {
    catalogItemPublisher(id: id, market: market, priority: priority) {
        service, albumID, market in
        try await service.get(albumID, market: market)
    }
}
```

## After (Using Publisher Generators)

### Option 1: Direct Method Reference (Simplest)
For methods with matching signatures, you can use method references:

```swift
public func devicesPublisher(
    priority: TaskPriority? = nil
) -> AnyPublisher<[SpotifyDevice], Error> {
    makePublisher(priority: priority, operation: devices)
}
```

### Option 2: Parameter Forwarding
For methods with parameters, use the parameter-forwarding overloads:

```swift
public func getPublisher(
    _ id: String,
    market: String? = nil,
    priority: TaskPriority? = nil
) -> AnyPublisher<Album, Error> {
    makePublisher(id, market, priority: priority, operation: Self.get)
}
```

### Option 3: Closure Adapter (Most Flexible)
For methods where parameters don't match exactly or need transformation:

```swift
public func searchPublisher(
    query: String,
    categories: [SearchCategory],
    market: String? = nil,
    limit: Int? = nil,
    offset: Int? = nil,
    includeExternal: String? = nil,
    priority: TaskPriority? = nil
) -> AnyPublisher<SearchResult, Error> {
    makePublisher(priority: priority) {
        try await self.search(
            query: query,
            categories: categories,
            market: market,
            limit: limit,
            offset: offset,
            includeExternal: includeExternal
        )
    }
}
```

## Benefits

1.  **Reduced Code Size**: Removes repetitive closure boilerplate.
2.  **Improved Readability**: The intent is clearer—"make a publisher for this operation".
3.  **Consistency**: Enforces a standard pattern for creating publishers.
4.  **Type Safety**: Compiler checks that the async method signature matches the publisher's expected output.
