import Foundation

struct AppConfig: Sendable {
  let clientID: String
  let redirectURI: URL
  
  enum ConfigError: Error, LocalizedError {
    case missingClientID
    case invalidRedirectURI(String)
    
    var errorDescription: String? {
      switch self {
      case .missingClientID:
        return "SPOTIFY_CLIENT_ID environment variable is not set. Set it with: export SPOTIFY_CLIENT_ID=\"your_client_id\""
      case .invalidRedirectURI(let uri):
        return "Invalid SPOTIFY_REDIRECT_URI: \(uri)"
      }
    }
  }
  
  static func load() throws -> AppConfig {
    guard let clientID = ProcessInfo.processInfo.environment["SPOTIFY_CLIENT_ID"],
          !clientID.isEmpty else {
      throw ConfigError.missingClientID
    }
    
    let redirectURIString = ProcessInfo.processInfo.environment["SPOTIFY_REDIRECT_URI"] 
      ?? "spotifyplaylistformatter://callback"
    
    guard let redirectURI = URL(string: redirectURIString) else {
      throw ConfigError.invalidRedirectURI(redirectURIString)
    }
    
    return AppConfig(clientID: clientID, redirectURI: redirectURI)
  }
}
