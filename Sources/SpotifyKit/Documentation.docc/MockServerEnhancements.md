# SpotifyMockAPIServer Enhancements

## Overview
The `SpotifyMockAPIServer` has been enhanced to support comprehensive integration testing for OAuth flows, error injection, and rate limiting. These enhancements enable Phase 1 integration tests that verify authentication, error handling, and network resilience.

## New Features

### 1. OAuth Flow Support

The server now simulates complete OAuth 2.0 flows including:

#### PKCE (Proof Key for Code Exchange)
- **Endpoint**: `GET /authorize`
- **Parameters**:
  - `client_id`: Required OAuth client identifier
  - `redirect_uri`: Required callback URL
  - `state`: Required CSRF protection token
  - `response_type`: Must be "code"
  - `code_challenge`: PKCE challenge (base64url-encoded)
  - `code_challenge_method`: "plain" or "S256" (SHA-256)
  - `scope`: Optional OAuth scope (defaults to configuration)

The server:
1. Validates client_id and redirect_uri
2. Stores the PKCE challenge for later verification
3. Generates an authorization code
4. Redirects to redirect_uri with code and state

#### Authorization Code Flow
- Same `/authorize` endpoint without PKCE parameters
- Requires client_secret in token exchange
- Stores authorization code with 10-minute expiry

#### Token Exchange
- **Endpoint**: `POST /api/token`
- **Grant Types**:
  - `authorization_code`: Exchange auth code for access token
  - `refresh_token`: Refresh an expired access token
  - `client_credentials`: Simple token issuance (existing behaviour)

**Authorization Code Grant**:
```
POST /api/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&code=AUTH_CODE&redirect_uri=REDIRECT_URI&code_verifier=VERIFIER
```

For PKCE flow:
- Validates `code_verifier` against stored `code_challenge`

### 2. Error Injection

The server supports deterministic error injection via `SpotifyMockAPIServer.Configuration`.

#### Global Errors
Configure the server to return specific errors for all requests:

```swift
let config = SpotifyMockAPIServer.Configuration(
    forcedError: .rateLimitExceeded // Returns 429 for everything
)
```

#### Endpoint-Specific Errors
(Future enhancement)

### 3. Rate Limiting Simulation

The server can simulate 429 Too Many Requests responses with `Retry-After` headers.

- **Behaviour**: When `forcedError` is set to `.rateLimitExceeded`, the server returns 429.
- **Headers**: Includes `Retry-After: <seconds>` (default 1s).

## Usage in Tests

### Setup

```swift
let config = SpotifyMockAPIServer.Configuration(
    forcedError: nil // Normal operation
)
let server = SpotifyMockAPIServer(configuration: config)
let client = SpotifyClient(
    configuration: .init(
        clientID: "test",
        clientSecret: "test",
        httpClient: server // Inject the mock server
    )
)
```

### Testing OAuth

```swift
// 1. Initiate PKCE flow
let authURL = client.authorizationManager.makeAuthorizationURL(...)
// 2. "User" visits URL (simulate by calling server directly or parsing URL)
// 3. Server redirects with code
// 4. Client exchanges code for token
```

### Testing Rate Limits

```swift
// Configure server to fail
await server.setForcedError(.rateLimitExceeded)

// Make request - Client should retry automatically
let task = Task { try await client.albums.get(...) }

// Advance time or wait for retry logic...
```
