import Foundation

struct CommandLineParser {
  struct Arguments {
    let playlistURL: String?
    let unformatted: Bool
  }
  
  static func parse(_ args: [String]) -> Arguments {
    var playlistURL: String?
    var unformatted = false
    
    var i = 1
    while i < args.count {
      let arg = args[i]
      
      switch arg {
      case "-u", "--unformatted":
        unformatted = true
      case let url where url.contains("spotify") || url.contains("playlist"):
        playlistURL = url
      default:
        break
      }
      
      i += 1
    }
    
    return Arguments(playlistURL: playlistURL, unformatted: unformatted)
  }
}
