import Foundation
import SpotifyKit

// MARK: - Internal Loader

private func loadJSON<T: Decodable>(named name: String, subdirectory: String) -> T {
    // The resources are copied into the bundle.
    // Since we used .process("Resources"), the folder structure might be flattened or preserved depending on SwiftPM.
    // Usually .process preserves the structure if it's a folder.
    // Let's try to find it.

    let resourceName = name
    // SwiftPM resource handling can be tricky.
    // If we used .copy("Resources"), it would be at root/Resources/...
    // With .process("Resources"), it might be flattened if they are just files, but since it's a folder, it's likely preserved.

    guard
        let url = Bundle.module.url(
            forResource: resourceName, withExtension: "json",
            subdirectory: "Resources/\(subdirectory)")
    else {
        fatalError(
            "Failed to locate \(name).json in subdirectory Resources/\(subdirectory) in bundle \(Bundle.module.bundlePath)"
        )
    }

    do {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    } catch {
        fatalError("Failed to decode \(name).json: \(error)")
    }
}

// MARK: - Track

extension Track {
    /// A mock `Track` instance for previews and testing.
    public static var mock: Track {
        loadJSON(named: "track_full", subdirectory: "Tracks")
    }
}

// MARK: - Album

extension Album {
    /// A mock `Album` instance for previews and testing.
    public static var mock: Album {
        loadJSON(named: "album_full", subdirectory: "Albums")
    }
}

// MARK: - Artist

extension Artist {
    /// A mock `Artist` instance for previews and testing.
    public static var mock: Artist {
        loadJSON(named: "artist_full", subdirectory: "Artists")
    }
}

// MARK: - Playlist

extension Playlist {
    /// A mock `Playlist` instance for previews and testing.
    public static var mock: Playlist {
        loadJSON(named: "playlist_full", subdirectory: "Playlists")
    }
}

// MARK: - Episode

extension Episode {
    /// A mock `Episode` instance for previews and testing.
    public static var mock: Episode {
        loadJSON(named: "episode_full", subdirectory: "Episodes")
    }
}

// MARK: - Show

extension Show {
    /// A mock `Show` instance for previews and testing.
    public static var mock: Show {
        loadJSON(named: "show_full", subdirectory: "Shows")
    }
}

// MARK: - Audiobook

extension Audiobook {
    /// A mock `Audiobook` instance for previews and testing.
    public static var mock: Audiobook {
        loadJSON(named: "audiobook_full", subdirectory: "Audiobooks")
    }
}

// MARK: - User

extension SpotifyPublicUser {
    /// A mock `SpotifyPublicUser` (public profile) instance for previews and testing.
    public static var mock: SpotifyPublicUser {
        loadJSON(named: "public_user_profile", subdirectory: "Users")
    }
}
