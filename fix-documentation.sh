#!/bin/bash

# Script to fix all documentation API usage

echo "Fixing documentation API usage..."

# Files to fix
FILES=(
    "README.md"
    "Sources/SpotifyWebAPI/SpotifyWebAPI.docc/GettingStarted.md"
    "Sources/SpotifyWebAPI/SpotifyWebAPI.docc/Authentication.md"
    "Sources/SpotifyWebAPI/SpotifyWebAPI.docc/Pagination.md"
    "TESTING.md"
    "DOCUMENTATION_EXAMPLES.md"
    "README_DOCUMENTATION.md"
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "Fixing $file..."
        
        # Fix: playlists.my() -> playlists.myPlaylists()
        sed -i 's/client\.playlists\.my()/client.playlists.myPlaylists()/g' "$file"
        
        # Fix: albums.several([...]) -> albums.several(ids: [...])
        sed -i 's/albums\.several(\[/albums.several(ids: [/g' "$file"
        sed -i 's/artists\.several(\[/artists.several(ids: [/g' "$file"
        sed -i 's/tracks\.several(\[/tracks.several(ids: [/g' "$file"
        
        # Fix: player.play() -> player.resume()
        sed -i 's/try await client\.player\.play()/try await client.player.resume()/g' "$file"
        
        # Fix: XCTest -> Swift Testing
        sed -i 's/import XCTest/import Testing/g' "$file"
        sed -i 's/class \(.*\): XCTestCase/@Suite("\1")\nstruct \1/g' "$file"
        sed -i 's/func test\([A-Z][a-zA-Z]*\)() async throws/@Test("\1")\nfunc \L\1() async throws/g' "$file"
        sed -i 's/XCTAssertEqual(\(.*\), \(.*\))/#expect(\1 == \2)/g' "$file"
        sed -i 's/XCTAssertTrue(\(.*\))/#expect(\1)/g' "$file"
        
    fi
done

echo "Done! Please review the changes."
