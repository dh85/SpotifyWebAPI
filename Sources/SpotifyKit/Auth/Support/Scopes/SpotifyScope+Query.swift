extension Set where Element == SpotifyScope {
    /// Creates the space-separated list Spotify expects in OAuth requests.
    public var spotifyQueryValue: String {
        map(\.rawValue).sorted().joined(separator: " ")
    }
}
