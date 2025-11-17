import Foundation

/// Represents an item that can be played (currently a Track or Episode).
public enum PlayableItem: Sendable, Equatable {
    case track(Track)
    case episode(Episode)
}
