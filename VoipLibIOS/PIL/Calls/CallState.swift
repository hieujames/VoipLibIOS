import Foundation

public enum CallState {
    case initializing
    case ringing
    case connected
    case heldByLocal
    case heldByRemote
    case ended
    case error
}
