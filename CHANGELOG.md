# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial release of the modern, thread-safe SpotifyKit.
- Full support for Swift 6 structured concurrency (Actors, Sendable).
- Fluent Search API builder.
- Comprehensive support for Albums, Artists, Player, Playlists, and User Library endpoints.
- Automatic token refreshing and rate limit handling (429 backoff).
- AsyncSequence support for pagination.
- Cross-platform support (iOS, macOS, Linux).

### Changed
- Refactored `DebugLogger` to be instance-based instead of a singleton for better test isolation.

### Fixed
- N/A
