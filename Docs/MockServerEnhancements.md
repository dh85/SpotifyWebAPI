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
  - `client_credentials`: Simple token issuance (existing behavior)

**Authorization Code Grant**:
```
POST /api/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&code=AUTH_CODE&redirect_uri=REDIRECT_URI&code_verifier=VERIFIER
```

For PKCE flow:
- Validates `code_verifier` against stored `code_challenge`
- Supports both "plain" and "S256" challenge methods
- Returns access_token and refresh_token

For standard flow:
- Requires `client_id` and `client_secret`
- Validates redirect_uri matches original request
- Returns access_token and refresh_token

**Refresh Token Grant**:
```
POST /api/token
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token&refresh_token=REFRESH_TOKEN
```

Returns new access_token while preserving refresh_token.

### 2. Error Injection

Configure the server to inject specific HTTP errors for testing error handling:

```swift
let errorConfig = SpotifyMockAPIServer.ErrorInjectionConfig(
    statusCode: 429,
    errorMessage: "Too many requests",
    affectedEndpoints: ["/v1/me", "/v1/me/playlists"],
    behavior: .once
)

let config = SpotifyMockAPIServer.Configuration(
    errorInjection: errorConfig
)
```

**Error Behaviors**:
- `.once`: Inject error on first matching request only
- `.always`: Inject error on every matching request
- `.nthRequest(n)`: Inject error on the nth request
- `.everyNthRequest(n)`: Inject error on every nth request

**Affected Endpoints**:
- `nil`: Affects all endpoints
- `Set<String>`: Only affects endpoints containing these path patterns

### 3. Rate Limiting

Simulate rate limit enforcement with configurable windows:

```swift
let rateLimitConfig = SpotifyMockAPIServer.RateLimitConfig(
    maxRequestsPerWindow: 5,
    windowDuration: 30,  // seconds
    retryAfterSeconds: 1
)

let config = SpotifyMockAPIServer.Configuration(
    rateLimitConfig: rateLimitConfig
)
```

When rate limit is exceeded:
- Returns HTTP 429 Too Many Requests
- Includes `Retry-After` header with configured wait time
- Resets counter after window duration expires

### 4. OAuth Configuration

```swift
let oauthConfig = SpotifyMockAPIServer.OAuthConfig(
    clientID: "test-client-id",
    clientSecret: "test-client-secret",
    enablePKCE: true,
    enableAuthorizationCode: true,
    refreshTokenExpiry: 7200  // seconds
)

let config = SpotifyMockAPIServer.Configuration(
    oauthConfig: oauthConfig
)
```

## Configuration API

### Complete Configuration Example

```swift
let config = SpotifyMockAPIServer.Configuration(
    port: 0,  // Random available port
    expectedAccessToken: "test-access-token",
    profile: customUserProfile,
    playlists: customPlaylists,
    playlistTracks: customTracks,
    tokenScope: "user-read-email playlist-modify-private",
    tokenExpiresIn: 3600,
    errorInjection: ErrorInjectionConfig(
        statusCode: 500,
        errorMessage: "Internal server error",
        affectedEndpoints: nil,
        behavior: .once
    ),
    rateLimitConfig: RateLimitConfig(
        maxRequestsPerWindow: 10,
        windowDuration: 60,
        retryAfterSeconds: 2
    ),
    oauthConfig: OAuthConfig(
        clientID: "my-client-id",
        clientSecret: "my-client-secret",
        enablePKCE: true,
        enableAuthorizationCode: true,
        refreshTokenExpiry: 3600
    )
)

let server = SpotifyMockAPIServer(configuration: config)
```

## Internal Implementation

### Data Structures

**OAuthState**: Manages OAuth flow state
- `authCodes`: Maps authorization codes to their metadata
- `pkceData`: Maps authorization codes to PKCE challenges
- `refreshTokens`: Maps refresh tokens to access tokens

**ErrorInjectionState**: Tracks error injection behavior
- `injectedOnce`: Flag for `.once` behavior
- `requestCount`: Counter for `.nthRequest` behaviors

**Rate Limiting State**:
- `requestCounter`: Per-endpoint request counts
- `rateLimitWindowStart`: Start time of current window

### Helper Methods

**OAuth Helpers**:
- `generateAuthorizationCode()`: Creates unique auth codes
- `generateAccessToken()`: Creates unique access tokens
- `generateRefreshToken()`: Creates unique refresh tokens
- `verifyPKCEChallenge()`: Validates PKCE code_verifier

**Rate Limit Helpers**:
- `checkRateLimit(for:)`: Checks if endpoint is rate limited
- `incrementRequestCount(for:)`: Increments endpoint counter
- `rateLimitResponse()`: Returns 429 with Retry-After header

**Error Injection Helpers**:
- `shouldInjectError(for:)`: Determines if error should be injected
- `errorResponse(status:message:)`: Creates JSON error response

**Request Parsing**:
- `parseFormURLEncoded(_:)`: Parses form data from body
- `parseQueryParameters(_:)`: Extracts query params from URL

## Testing Use Cases

### Phase 1 Integration Tests Now Possible

With these enhancements, you can now write integration tests for:

1. **OAuth Flows**:
   - PKCE authorization code flow
   - Standard authorization code flow
   - Refresh token rotation
   - Token expiration handling
   - Invalid client credentials
   - Redirect URI validation

2. **Error Handling**:
   - 4xx client errors (400, 401, 403, 404)
   - 5xx server errors (500, 502, 503)
   - Error response parsing
   - Error recovery strategies

3. **Rate Limiting**:
   - Rate limit detection (429 responses)
   - Retry-After header parsing
   - Automatic retry with backoff
   - Rate limit window reset

4. **Network Resilience**:
   - Timeout handling
   - Service unavailable (503)
   - Connection failures
   - Retry logic validation

### Example Test Pattern

```swift
@Test("PKCE flow completes successfully")
func pkceFlowSuccess() async throws {
    let config = SpotifyMockAPIServer.Configuration(
        oauthConfig: .init(
            clientID: "test-client",
            clientSecret: "test-secret",
            enablePKCE: true,
            enableAuthorizationCode: true,
            refreshTokenExpiry: 3600
        )
    )
    let server = SpotifyMockAPIServer(configuration: config)
    
    try await server.withRunningServer { info in
        // 1. Request authorization
        let codeVerifier = "test-verifier-123"
        let codeChallenge = generatePKCEChallenge(from: codeVerifier)
        let authorizeURL = "\(info.authorizeEndpoint)?client_id=test-client&redirect_uri=myapp://callback&state=abc123&code_challenge=\(codeChallenge)&code_challenge_method=S256"
        
        // 2. Extract authorization code from redirect
        let authCode = extractAuthCodeFromRedirect(authorizeURL)
        
        // 3. Exchange code for tokens
        let tokenURL = "\(info.tokenEndpoint)?grant_type=authorization_code&code=\(authCode)&redirect_uri=myapp://callback&code_verifier=\(codeVerifier)"
        let tokens = try await exchangeCodeForTokens(tokenURL)
        
        #expect(tokens.accessToken != nil)
        #expect(tokens.refreshToken != nil)
    }
}
```

## API Compatibility

All existing integration tests remain compatible. The new features are opt-in through configuration.

**Default Behavior** (without new configuration):
- OAuth: Only client_credentials grant type supported
- Errors: No error injection
- Rate Limiting: No limits enforced

## Future Enhancements

Potential future additions:
1. Authorization scopes validation
2. Token introspection endpoint
3. Configurable token lifetimes per flow
4. Multiple client credentials support
5. Webhook simulation for playlist changes
6. More granular rate limiting (per-user, per-endpoint)
