# Error Recovery Guide

Learn how to handle common errors and implement robust recovery strategies in your SpotifyKit applications.

## Overview

SpotifyKit provides two main error types:
- ``SpotifyClientError`` - API request and network errors
- ``SpotifyAuthError`` - Authentication and token management errors

This guide shows you how to handle these errors gracefully and implement retry strategies.

## Common Error Scenarios

### 1. Token Expired / Missing Refresh Token

**When it happens:** User's refresh token is invalid, expired, or missing.

**Recovery:** Re-authenticate the user.

```swift
let client: UserSpotifyClient = .pkce(...)

do {
    let profile = try await client.users.me()
} catch SpotifyAuthError.missingRefreshToken {
    // Refresh token is missing or invalid - user must log in again
    await MainActor.run {
        showLoginScreen()
    }
} catch {
    print("Other error: \(error)")
}
```

**SwiftUI Example:**
```swift
@MainActor
class SpotifyViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var showLoginSheet = false
    
    let client: UserSpotifyClient
    
    func fetchProfile() async {
        do {
            let profile = try await client.users.me()
            isAuthenticated = true
        } catch SpotifyAuthError.missingRefreshToken {
            isAuthenticated = false
            showLoginSheet = true
        } catch {
            print("Error: \(error)")
        }
    }
}
```

### 2. Rate Limiting (429 Too Many Requests)

**When it happens:** You've exceeded Spotify's rate limits.

**Recovery:** The client automatically retries with exponential backoff. You can also monitor rate limits proactively.

```swift
// Monitor rate limits proactively
client.events.onRateLimitInfo { info in
    if let remaining = info.remaining, remaining < 10 {
        print("⚠️ Only \(remaining) requests remaining")
        // Slow down your requests
        await throttleRequests()
    }
    
    if let resetDate = info.resetDate {
        let secondsUntilReset = resetDate.timeIntervalSinceNow
        print("Rate limit resets in \(Int(secondsUntilReset))s")
    }
}

// Configure retry behavior
let config = SpotifyClientConfiguration.default
    .withMaxRateLimitRetries(3)

let client: UserSpotifyClient = .pkce(
    clientID: "your-client-id",
    redirectURI: URL(string: "myapp://callback")!,
    scopes: [.userReadPrivate],
    configuration: config
)
```

### 3. Network Failure

**When it happens:** No internet connection or network timeout.

**Recovery:** Retry with exponential backoff or show cached data.

```swift
func fetchAlbumWithRetry(_ id: String, maxRetries: Int = 3) async throws -> Album {
    var lastError: Error?
    
    for attempt in 0..<maxRetries {
        do {
            return try await client.albums.get(id)
        } catch SpotifyClientError.networkFailure(let message) {
            lastError = SpotifyClientError.networkFailure(message)
            
            if attempt < maxRetries - 1 {
                // Exponential backoff: 1s, 2s, 4s
                let delay = pow(2.0, Double(attempt))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
    }
    
    throw lastError ?? SpotifyClientError.networkFailure("Max retries exceeded")
}

// Usage with fallback to cache
do {
    let album = try await fetchAlbumWithRetry(albumID)
    updateUI(with: album)
} catch {
    // Show cached data
    if let cached = cache.album(for: albumID) {
        updateUI(with: cached)
        showOfflineBanner()
    } else {
        showErrorMessage("Unable to load album")
    }
}
```

### 4. Invalid Request (400 Bad Request)

**When it happens:** Request parameters are invalid (e.g., too many IDs, invalid limit).

**Recovery:** Validate inputs before making requests.

```swift
func saveAlbums(_ ids: [String]) async throws {
    // SpotifyKit validates automatically, but you can pre-validate
    guard ids.count <= 20 else {
        throw SpotifyClientError.invalidRequest(
            reason: "Cannot save more than 20 albums at once"
        )
    }
    
    do {
        try await client.albums.save(Set(ids))
    } catch SpotifyClientError.invalidRequest(let reason) {
        print("Invalid request: \(reason)")
        // Split into batches and retry
        for batch in ids.chunked(into: 20) {
            try await client.albums.save(Set(batch))
        }
    }
}
```

### 5. Resource Not Found (404)

**When it happens:** Album, track, or playlist doesn't exist or was deleted.

**Recovery:** Handle gracefully and update UI.

```swift
func loadPlaylist(_ id: String) async {
    do {
        let playlist = try await client.playlists.get(id)
        updateUI(with: playlist)
    } catch SpotifyClientError.httpError(404, _) {
        // Playlist was deleted or doesn't exist
        await MainActor.run {
            showAlert(
                title: "Playlist Not Found",
                message: "This playlist may have been deleted."
            )
            removeFromFavorites(id)
        }
    } catch {
        showError(error)
    }
}
```

### 6. Insufficient Permissions (403 Forbidden)

**When it happens:** Missing required OAuth scopes.

**Recovery:** Request additional scopes and re-authenticate.

```swift
func modifyPlaylist(_ id: String) async {
    do {
        try await client.playlists.addItems(id, uris: trackURIs)
    } catch SpotifyClientError.httpError(403, _) {
        // Missing playlist-modify-public or playlist-modify-private scope
        await MainActor.run {
            showAlert(
                title: "Permission Required",
                message: "Please grant permission to modify playlists."
            ) {
                // Re-authenticate with additional scopes
                await reauthorizeWithScopes([
                    .userReadPrivate,
                    .playlistModifyPublic,
                    .playlistModifyPrivate
                ])
            }
        }
    } catch {
        showError(error)
    }
}
```

### 7. Service Unavailable (503)

**When it happens:** Spotify's servers are temporarily unavailable.

**Recovery:** Retry with exponential backoff.

```swift
func fetchWithServiceRetry<T>(
    maxRetries: Int = 3,
    operation: () async throws -> T
) async throws -> T {
    var lastError: Error?
    
    for attempt in 0..<maxRetries {
        do {
            return try await operation()
        } catch SpotifyClientError.httpError(503, _) {
            lastError = error
            
            if attempt < maxRetries - 1 {
                let delay = pow(2.0, Double(attempt)) * 2.0  // 2s, 4s, 8s
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
    }
    
    throw lastError ?? SpotifyClientError.networkFailure("Service unavailable")
}

// Usage
do {
    let album = try await fetchWithServiceRetry {
        try await client.albums.get(albumID)
    }
} catch {
    showMaintenanceMessage()
}
```

### 8. Offline Mode

**When it happens:** You've enabled offline mode or device has no connectivity.

**Recovery:** Show cached data and offline indicator.

```swift
// Enable offline mode
await client.setOffline(true)

func loadContent() async {
    do {
        let albums = try await client.albums.saved()
        updateUI(with: albums)
    } catch SpotifyClientError.offline {
        // Client is in offline mode
        if let cached = cache.savedAlbums() {
            updateUI(with: cached)
            showOfflineIndicator()
        } else {
            showOfflineEmptyState()
        }
    }
}

// Check offline status before making requests
if await client.isOffline() {
    loadFromCache()
} else {
    loadFromNetwork()
}
```

## Comprehensive Error Handler

Here's a reusable error handler that covers all common scenarios:

```swift
@MainActor
class SpotifyErrorHandler {
    let client: UserSpotifyClient
    weak var viewController: UIViewController?
    
    init(client: UserSpotifyClient, viewController: UIViewController? = nil) {
        self.client = client
        self.viewController = viewController
    }
    
    func handle(_ error: Error, retry: (() async throws -> Void)? = nil) async {
        switch error {
        // Auth errors
        case SpotifyAuthError.missingRefreshToken:
            showReauthAlert()
            
        case SpotifyAuthError.stateMismatch:
            showAlert(
                title: "Security Error",
                message: "Authentication failed. Please try again."
            )
            
        // Client errors
        case SpotifyClientError.offline:
            showOfflineAlert()
            
        case SpotifyClientError.networkFailure(let message):
            showRetryAlert(message: message, retry: retry)
            
        case SpotifyClientError.httpError(let code, let body):
            await handleHTTPError(code: code, body: body, retry: retry)
            
        case SpotifyClientError.invalidRequest(let reason):
            showAlert(title: "Invalid Request", message: reason)
            
        default:
            showAlert(
                title: "Error",
                message: error.localizedDescription
            )
        }
    }
    
    private func handleHTTPError(
        code: Int,
        body: String,
        retry: (() async throws -> Void)?
    ) async {
        switch code {
        case 401:
            showReauthAlert()
            
        case 403:
            showAlert(
                title: "Permission Denied",
                message: "You don't have permission to perform this action."
            )
            
        case 404:
            showAlert(
                title: "Not Found",
                message: "The requested resource was not found."
            )
            
        case 429:
            showAlert(
                title: "Too Many Requests",
                message: "Please wait a moment before trying again."
            )
            
        case 500...599:
            showRetryAlert(
                message: "Spotify's servers are experiencing issues.",
                retry: retry
            )
            
        default:
            showAlert(
                title: "Error \(code)",
                message: body
            )
        }
    }
    
    private func showReauthAlert() {
        showAlert(
            title: "Session Expired",
            message: "Please log in again to continue."
        ) {
            // Navigate to login screen
            self.viewController?.present(LoginViewController(), animated: true)
        }
    }
    
    private func showOfflineAlert() {
        showAlert(
            title: "Offline",
            message: "You're currently offline. Some features may be unavailable."
        )
    }
    
    private func showRetryAlert(message: String, retry: (() async throws -> Void)?) {
        guard let retry else {
            showAlert(title: "Network Error", message: message)
            return
        }
        
        let alert = UIAlertController(
            title: "Network Error",
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { _ in
            Task {
                do {
                    try await retry()
                } catch {
                    await self.handle(error, retry: retry)
                }
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        viewController?.present(alert, animated: true)
    }
    
    private func showAlert(
        title: String,
        message: String,
        action: (() -> Void)? = nil
    ) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            action?()
        })
        
        viewController?.present(alert, animated: true)
    }
}

// Usage
let errorHandler = SpotifyErrorHandler(client: client, viewController: self)

do {
    try await client.player.play(uri: trackURI)
} catch {
    await errorHandler.handle(error) {
        try await client.player.play(uri: trackURI)
    }
}
```

## SwiftUI Error Handling

```swift
@MainActor
class SpotifyViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showReauthSheet = false
    
    let client: UserSpotifyClient
    
    init(client: UserSpotifyClient) {
        self.client = client
    }
    
    func handle(_ error: Error) {
        switch error {
        case SpotifyAuthError.missingRefreshToken:
            showReauthSheet = true
            
        case SpotifyClientError.offline:
            errorMessage = "You're offline. Some features are unavailable."
            showError = true
            
        case SpotifyClientError.httpError(404, _):
            errorMessage = "Content not found or has been removed."
            showError = true
            
        case SpotifyClientError.httpError(403, _):
            errorMessage = "You don't have permission for this action."
            showError = true
            
        default:
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func fetchProfile() async {
        do {
            let profile = try await client.users.me()
            // Update UI
        } catch {
            handle(error)
        }
    }
}

struct ContentView: View {
    @StateObject var viewModel: SpotifyViewModel
    
    var body: some View {
        VStack {
            // Your content
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
        .sheet(isPresented: $viewModel.showReauthSheet) {
            LoginView()
        }
    }
}
```

## Best Practices

### 1. Always Handle Auth Errors

```swift
// ✅ Good
do {
    let profile = try await client.users.me()
} catch SpotifyAuthError.missingRefreshToken {
    showLoginScreen()
} catch {
    showError(error)
}

// ❌ Bad - ignores auth errors
let profile = try? await client.users.me()
```

### 2. Use Retry Logic for Transient Errors

```swift
// ✅ Good - retries network failures
func fetchWithRetry<T>(
    _ operation: () async throws -> T
) async throws -> T {
    for attempt in 0..<3 {
        do {
            return try await operation()
        } catch SpotifyClientError.networkFailure {
            if attempt == 2 { throw error }
            try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt)) * 1_000_000_000))
        }
    }
    fatalError("Unreachable")
}
```

### 3. Provide User Feedback

```swift
// ✅ Good - clear user feedback
catch SpotifyClientError.httpError(403, _) {
    showAlert(
        title: "Permission Required",
        message: "Please grant permission to modify playlists in Settings."
    )
}

// ❌ Bad - generic error
catch {
    print("Error: \(error)")
}
```

### 4. Monitor Token Lifecycle

```swift
// ✅ Good - proactive monitoring
client.events.onTokenRefreshWillStart { info in
    print("Token refreshing (expires in \(info.secondsUntilExpiration)s)")
}

client.events.onTokenRefreshDidFail { error in
    showLoginScreen()
}
```

### 5. Validate Before Requesting

```swift
// ✅ Good - validate early
guard ids.count <= 50 else {
    throw SpotifyClientError.invalidRequest(
        reason: "Maximum 50 IDs allowed"
    )
}
try await client.tracks.several(ids: Set(ids))
```

## Topics

### Related Guides

- <doc:AuthGuide>
- <doc:CommonPatterns>
- <doc:NetworkSecurity>
