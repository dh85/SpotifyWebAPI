# Contributing to SpotifyKit

Thank you for your interest in contributing to SpotifyKit! We welcome contributions from the community to help make this the best Swift SDK for Spotify.

## Getting Started

1. **Fork the repository** on GitHub.
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/SpotifyKit.git
   cd SpotifyKit
   ```
3. **Build the project** to ensure everything is working:
   ```bash
   swift build
   ```

## Development Workflow

1. **Create a new branch** for your feature or bugfix:
   ```bash
   git checkout -b feature/my-awesome-feature
   ```
2. **Make your changes**. Please ensure you follow the existing code style and use Swift 6 structured concurrency patterns (Actors, `async/await`) where appropriate.
3. **Run tests** to ensure no regressions:
   ```bash
   swift test
   ```
   If you are adding a new feature, please add corresponding unit tests in the `Tests` directory.

## Testing

This project relies heavily on unit and integration tests.
- **Unit Tests**: Run fast and use mocks (`MockSpotifyClient`).
- **Integration Tests**: May require network access or specific environment setups.

To run all tests:
```bash
swift test
```

## Pull Requests

1. Push your branch to your fork.
2. Open a Pull Request against the `main` branch.
3. Provide a clear description of the problem you are solving and your solution.
4. Ensure CI passes (GitHub Actions).

## Code Style

- Use **Swift 6** features.
- Prefer `struct` over `class` for data models.
- Use `actor` for shared mutable state.
- Document public APIs using DocC-compatible comments (`///`).

## License

By contributing, you agree that your contributions will be licensed under its MIT License.
