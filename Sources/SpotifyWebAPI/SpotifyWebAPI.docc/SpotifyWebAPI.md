# ``SpotifyWebAPI``

A modern Swift library for the Spotify Web API with comprehensive async/await support.

## Overview

SpotifyWebAPI provides a complete, type-safe interface to the Spotify Web API. Built with modern Swift concurrency, it offers:

- **Three authentication flows**: PKCE, Authorization Code, and Client Credentials
- **Complete API coverage**: All Spotify endpoints including playback, playlists, search, and user data
- **Modern async/await**: Native Swift concurrency throughout
- **Type safety**: Strongly-typed models for all Spotify resources
- **Automatic pagination**: Stream large collections efficiently
- **Batch operations**: Convenient methods for bulk operations
- **Rate limit handling**: Automatic retry with exponential backoff

## Topics

### Getting Started

- <doc:GettingStarted>
- <doc:Authentication>
- <doc:Pagination>

### Core Types

- ``SpotifyClient``
- ``SpotifyClientConfiguration``
- ``UserSpotifyClient``
- ``AppSpotifyClient``

### Authentication

- ``SpotifyPKCEAuthenticator``
- ``SpotifyAuthorizationCodeAuthenticator``
- ``SpotifyClientCredentialsAuthenticator``
- ``SpotifyAuthConfig``

### Services

- ``PlaylistsService``
- ``AlbumsService``
- ``TracksService``
- ``PlayerService``
- ``SearchService``
- ``UsersService``
- ``ArtistsService``
- ``BrowseService``

### Models

- ``Playlist``
- ``Album``
- ``Track``
- ``Artist``
- ``PlaybackState``
- ``SearchResults``

### Advanced Features

- ``RequestInterceptor``
- ``TokenExpirationCallback``
- ``MockSpotifyClient``
