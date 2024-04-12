import Foundation

public struct AudioState {
    public let currentRoute: AudioRoute
    public let availableRoutes: [AudioRoute]
    public let bluetoothDeviceName: String?
    public let isMicrophoneMuted: Bool
}
