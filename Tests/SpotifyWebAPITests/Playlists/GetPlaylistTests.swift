import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite
struct GetPlaylistTests {

    private func makePlaylistJSON() -> Data {
            let json: [String: Any] = [
                "collaborative": false,
                "description": "Chill vibes",
                "external_urls": [
                    "spotify": "https://open.spotify.com/playlist/abc"
                ],
                "href": "https://api.spotify.com/v1/playlists/abc",
                "id": "abc",
                "images": [],
                "name": "My Playlist",
                "owner": [
                    "id": "owner123",
                    "display_name": "Owner User",
                    "href": "https://api.spotify.com/v1/users/owner123",
                    "uri": "spotify:user:owner123",
                    "type": "user",
                    "external_urls": [
                        "spotify": "https://open.spotify.com/user/owner123"
                    ],
                ],
                "public": true,
                "snapshot_id": "snapshot123",
                "tracks": [
                    "href": "https://api.spotify.com/v1/playlists/abc/tracks",
                    "items": [
                        [
                            "added_at": "2019-08-24T14:15:22Z",
                            "added_by": [
                                "id": "adder123",
                                "display_name": "Adder User",
                                "href": "https://api.spotify.com/v1/users/adder123",
                                "uri": "spotify:user:adder123",
                                "type": "user",
                                "external_urls": [
                                    "spotify":
                                        "https://open.spotify.com/user/adder123"
                                ],
                            ],
                            "is_local": false,
                            "track": [
                                "id": "track1",
                                "name": "Track One",
                                "duration_ms": 123000,
                                "explicit": false,
                                "href": "https://api.spotify.com/v1/tracks/track1",
                                "uri": "spotify:track:track1",
                                "type": "track",
                                "external_urls": [
                                    "spotify":
                                        "https://open.spotify.com/track/track1"
                                ],
                                // --- FIXED ALBUM OBJECT ---
                                "album": [
                                    "id": "album1",
                                    "name": "Album One",
                                    "href": "https://api.spotify.com/v1/albums/album1",
                                    "uri": "spotify:album:album1",
                                    "album_type": "album",
                                    "total_tracks": 10,
                                    "images": [],
                                    "external_urls": [
                                        "spotify":
                                            "https://open.spotify.com/album/album1"
                                    ],
                                    // Added missing fields required by SimplifiedAlbum:
                                    "available_markets": ["GB", "US"],
                                    "release_date": "2024-01-01",
                                    "release_date_precision": "day",
                                    "type": "album",
                                    "album_group": "album",
                                    "artists": [
                                        [
                                            "id": "artist1",
                                            "name": "Artist One",
                                            "href": "https://api.spotify.com/v1/artists/artist1",
                                            "uri": "spotify:artist:artist1",
                                            "type": "artist",
                                            "external_urls": [
                                                "spotify": "https://open.spotify.com/artist/artist1"
                                            ]
                                        ]
                                    ]
                                ],
                                "artists": [
                                    [
                                        "id": "artist1",
                                        "name": "Artist One",
                                        "href":
                                            "https://api.spotify.com/v1/artists/artist1",
                                        "external_urls": [
                                            "spotify":
                                                "https://open.spotify.com/artist/artist1"
                                        ],
                                    ]
                                ],
                            ],
                        ]
                    ],
                    "limit": 100,
                    "next": NSNull(),
                    "offset": 0,
                    "previous": NSNull(),
                    "total": 1,
                ],
                "type": "playlist",
                "uri": "spotify:playlist:abc",
            ]

            return try! JSONSerialization.data(withJSONObject: json, options: [])
        }

    private func makeClient() -> (UserSpotifyClient, SequencedMockHTTPClient) {
        let data = makePlaylistJSON()
        let httpClient = SequencedMockHTTPClient(
            responses: [
                .init(data: data, statusCode: 200)
            ]
        )

        let tokenStore = InMemoryTokenStore(
            tokens: SpotifyTokens(
                accessToken: "ACCESS",
                refreshToken: "REFRESH",
                expiresAt: Date().addingTimeInterval(3600),
                scope: nil,
                tokenType: "Bearer"
            )
        )

        let client = UserSpotifyClient.authorizationCode(
            clientID: "TEST_CLIENT",
            clientSecret: "TEST_SECRET",
            redirectURI: URL(string: "app://callback")!,
            scopes: [.playlistReadPrivate],
            tokenStore: tokenStore,
            httpClient: httpClient
        )

        return (client, httpClient)
    }

    @Test
    func playlistDecodesAndBuildsCorrectURL() async throws {
        let (client, http) = makeClient()
        let playlist = try await client.playlists.get(
            "abc",
            market: "GB",
            fields: "id,name",
            additionalTypes: ["track", "episode"]
        )

        #expect(playlist.id == "abc")
        #expect(playlist.name == "My Playlist")
        #expect(playlist.description == "Chill vibes")
        #expect(playlist.isPublic == true)
        #expect(playlist.snapshotId == "snapshot123")

        #expect(playlist.tracks.total == 1)
        #expect(playlist.tracks.items.count == 1)

        let item = playlist.tracks.items.first!
        #expect(item.isLocal == false)
        #expect(item.addedBy?.id == "adder123")
        #expect(item.addedBy?.displayName == "Adder User")
        
        if case .track(let track) = item.track {
            #expect(track.name == "Track One")
            #expect(track.durationMs == 123000)
            #expect(track.album?.name == "Album One")
            #expect(track.artists?.first?.name == "Artist One")
        } else {
            Issue.record("Expected track, got episode or nil")
        }

        #expect(http.requests.count == 1)
        let request = http.requests[0]
        #expect(request.url?.path == "/v1/playlists/abc")

        if let url = request.url,
            let components = URLComponents(
                url: url,
                resolvingAgainstBaseURL: false
            ),
            let items = components.queryItems
        {
            func value(_ name: String) -> String? {
                items.first(where: { $0.name == name })?.value
            }

            #expect(value("market") == "GB")
            #expect(value("fields") == "id,name")
            #expect(value("additional_types") == "track,episode")
        } else {
            Issue.record("Missing or invalid URL components in request")
        }
    }
}
