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

### Option 3: Inline Closure (When Needed)
For complex cases or parameter transformation:

```swift
public func statePublisher(
    market: String? = nil,
    additionalTypes: Set<AdditionalItemType>? = nil,
    priority: TaskPriority? = nil
) -> AnyPublisher<PlaybackState?, Error> {
    publisher(priority: priority) { service in
        try await service.state(market: market, additionalTypes: additionalTypes)
    }
}
```

## Adoption Status

The `makePublisher` pattern has been adopted in the following services where it provides clear benefits:

### ✅ Adopted

- **ArtistsService**: `topTracksPublisher` - Simple 2-parameter forwarding
- **PlaylistsService**: `coverImagePublisher` - Simple 1-parameter forwarding

### ⚠️ Not Suitable

Methods that were evaluated but kept with closure syntax due to:
- Complex parameter handling (multiple optionals with default values)
- Method signature incompatibility (returning values vs taking parameters)
- Better readability with explicit closures

Examples:
- `PlayerService.devicesPublisher()` - Method returns `() async throws -> [SpotifyDevice]` but helper expects `(Self) async throws -> [SpotifyDevice]`
- `UsersService.mePublisher()` - Same signature mismatch issue
- `BrowseService.availableMarketsPublisher()` - Same signature mismatch issue

### 📋 Still Using Specialized Helpers

Most services continue using the domain-specific helpers which provide semantic clarity:
- `catalogItemPublisher` - For single item fetches
- `catalogCollectionPublisher` - For multiple items
- `librarySavedPublisher` - For paginated saved items
- `libraryMutationPublisher` - For save/remove operations
- `pagedPublisher` - For generic pagination

These specialised helpers encode domain knowledge and should be preferred over generic `makePublisher` for catalogue and library operations.

## Benefits

1. **Reduced Boilerplate**: Eliminates repetitive closure syntax for simple cases
2. **Type Safety**: Compiler enforces correct parameter and return types
3. **Clearer Intent**: Method references make the mapping obvious
4. **Maintainability**: Changes to async methods automatically propagate to publishers

## Available Helpers

- `makePublisher(priority:operation:)` - For methods with no parameters
- `makePublisher(_:priority:operation:)` - For methods with 1 parameter
- `makePublisher(_:_:priority:operation:)` - For methods with 2 parameters
- `makePublisher(_:_:_:priority:operation:)` - For methods with 3 parameters
- `makePublisher(_:_:_:_:priority:operation:)` - For methods with 4 parameters

## Migration Guide

To migrate existing publisher methods:

1. **Identify the pattern**: Look at the async method signature
2. **Count parameters**: Determine which `makePublisher` overload to use
3. **Use method reference**: Try using `Self.methodName` first
4. **Fall back to closure**: If method reference doesn't work, use inline closure

## Example Migrations

### Albums Service

**Before:**
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

**After:**
```swift
public func getPublisher(
    _ id: String,
    market: String? = nil,
    priority: TaskPriority? = nil
) -> AnyPublisher<Album, Error> {
    makePublisher(id, market, priority: priority, operation: Self.get)
}
```

### Player Service

**Before:**
```swift
public func devicesPublisher(priority: TaskPriority? = nil) -> AnyPublisher<
    [SpotifyDevice], Error
> {
    publisher(priority: priority) { service in
        try await service.devices()
    }
}
```

**After:**
```swift
public func devicesPublisher(
    priority: TaskPriority? = nil
) -> AnyPublisher<[SpotifyDevice], Error> {
    makePublisher(priority: priority, operation: devices)
}
```

## When NOT to Use

Keep the existing `catalogItemPublisher`, `librarySavedPublisher`, etc. helpers for:
- Complex parameter transformations
- Special pagination handling
- Library-specific operations
- When semantic naming adds clarity

## Testing

All existing tests continue to work without modification since the public API remains unchanged.
