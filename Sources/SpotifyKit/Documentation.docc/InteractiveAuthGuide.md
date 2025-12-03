# Interactive Authentication for CLI Apps

Simplify PKCE authentication in command-line applications with the interactive auth flow.

## Overview

The interactive authentication flow streamlines the PKCE authorization process for CLI applications by handling the common pattern of:
1. Generating an authorization URL
2. Displaying it to the user
3. Prompting for the callback URL
4. Exchanging the code for tokens
5. Creating an authenticated client

This eliminates boilerplate code and makes it easier to build CLI tools that integrate with Spotify.

## Basic Usage

The simplest way to authenticate is with default callbacks that use stdout/stdin:

```swift
import SpotifyKit

let client = try await UserSpotifyClient.authenticateInteractive(
    clientID: "your-client-id",
    redirectURI: URL(string: "myapp://callback")!,
    scopes: [.playlistReadPrivate, .userReadPrivate]
)

// Client is ready to use
let playlists = try await client.playlists.myPlaylists()
```

This will:
- Print the authorization URL to stdout
- Wait for the user to paste the callback URL via stdin
- Exchange the code for tokens
- Return an authenticated client

## Custom Callbacks

For more control over the user experience, provide custom callbacks:

```swift
let callbacks = InteractiveAuthCallbacks(
    onAuthURL: { url in
        print("🔐 Please authorize the app:")
        print(url.absoluteString)
        
        // Optionally open browser automatically
        #if os(macOS)
        _ = try? Process.run(URL(fileURLWithPath: "/usr/bin/open"), arguments: [url.absoluteString])
        #endif
    },
    onPromptCallback: {
        print("\n✨ Paste the callback URL:")
        guard let input = readLine(), let url = URL(string: input) else {
            throw SpotifyAuthError.invalidCallback
        }
        return url
    }
)

let client = try await UserSpotifyClient.authenticateInteractive(
    clientID: "your-client-id",
    redirectURI: URL(string: "myapp://callback")!,
    scopes: [.playlistReadPrivate],
    callbacks: callbacks
)
```

## Token Caching

The interactive auth flow automatically checks for existing tokens before prompting for authentication:

```swift
// First run: prompts for authentication
let client1 = try await UserSpotifyClient.authenticateInteractive(
    clientID: "your-client-id",
    redirectURI: URL(string: "myapp://callback")!,
    scopes: [.playlistReadPrivate],
    tokenStore: TokenStoreFactory.defaultStore()
)

// Subsequent runs: reuses cached tokens (no prompt)
let client2 = try await UserSpotifyClient.authenticateInteractive(
    clientID: "your-client-id",
    redirectURI: URL(string: "myapp://callback")!,
    scopes: [.playlistReadPrivate],
    tokenStore: TokenStoreFactory.defaultStore()
)
```

### Custom Token Storage

Specify a custom token store for different caching strategies:

```swift
let tokenStore = RestrictedFileTokenStore(
    filename: "my_app_tokens.json",
    directory: FileManager.default.homeDirectoryForCurrentUser
)

let client = try await UserSpotifyClient.authenticateInteractive(
    clientID: "your-client-id",
    redirectURI: URL(string: "myapp://callback")!,
    scopes: [.playlistReadPrivate],
    tokenStore: tokenStore
)
```

## Advanced: Web Server Callback

For a better user experience, run a local web server to capture the callback automatically:

```swift
let callbacks = InteractiveAuthCallbacks(
    onAuthURL: { url in
        _ = try? Process.run(URL(fileURLWithPath: "/usr/bin/open"), arguments: [url.absoluteString])
    },
    onPromptCallback: {
        // Start local server on port 8080
        let server = LocalCallbackServer(port: 8080)
        try await server.start()
        
        // Wait for callback
        let callbackURL = try await server.waitForCallback()
        server.stop()
        
        return callbackURL
    }
)

let client = try await UserSpotifyClient.authenticateInteractive(
    clientID: "your-client-id",
    redirectURI: URL(string: "http://localhost:8080/callback")!,
    scopes: [.playlistReadPrivate],
    callbacks: callbacks
)
```

## Error Handling

The interactive auth flow throws `SpotifyAuthError` for authentication failures:

```swift
do {
    let client = try await UserSpotifyClient.authenticateInteractive(
        clientID: "your-client-id",
        redirectURI: URL(string: "myapp://callback")!,
        scopes: [.playlistReadPrivate]
    )
} catch SpotifyAuthError.invalidCallback {
    print("Invalid callback URL format")
} catch SpotifyAuthError.stateMismatch {
    print("CSRF state mismatch - possible security issue")
} catch {
    print("Authentication failed: \(error)")
}
```

## Comparison: Before and After

### Before (Manual Flow)

```swift
// ~30 lines of boilerplate
let tokenStore = RestrictedFileTokenStore(...)

if try await tokenStore.load() == nil {
    let authenticator = SpotifyPKCEAuthenticator(
        config: .pkce(clientID: "...", redirectURI: ..., scopes: [...]),
        tokenStore: tokenStore
    )
    
    let authURL = try await authenticator.makeAuthorizationURL()
    print("Open: \(authURL)")
    
    print("Paste callback URL:")
    guard let input = readLine(), let url = URL(string: input) else {
        throw MyError.invalidURL
    }
    
    _ = try await authenticator.handleCallback(url)
}

let client: UserSpotifyClient = .pkce(
    clientID: "...",
    redirectURI: ...,
    scopes: [...],
    tokenStore: tokenStore
)
```

### After (Interactive Flow)

```swift
// 5 lines
let client = try await UserSpotifyClient.authenticateInteractive(
    clientID: "your-client-id",
    redirectURI: URL(string: "myapp://callback")!,
    scopes: [.playlistReadPrivate]
)
```

## See Also

- ``InteractiveAuthCallbacks``
- ``SpotifyClient/authenticateInteractive(clientID:redirectURI:scopes:tokenStore:callbacks:)``
- ``TokenStoreFactory``
- <doc:TokenStorageGuide>
