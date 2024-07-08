import Foundation
import AVFoundation
import AVKit
import linphonesw

@available(iOS 11.0, *)
public class AudioManager {
    
    private let voipLib: LibModule
    private let audioSession: AVAudioSession
    private let pil: MFLib
    private let callActions: CallActions
    
    private var mifoneAudio: MiFoneAudio {
        voipLib.mifone.mifoneAudio
    }
    
    public var state: AudioState {
        AudioState(
            currentRoute: mifoneAudio.currentRoute,
            availableRoutes: mifoneAudio.availableRoutes,
            bluetoothDeviceName: findBluetoothName(),
            isMicrophoneMuted: isMicrophoneMuted
        )
    }
    
    private lazy var routePickerView: AVRoutePickerView = {
        let routePickerView = AVRoutePickerView()
        routePickerView.isHidden = true
        return routePickerView
    }()
    
    init(pil: MFLib, voipLib: LibModule, audioSession: AVAudioSession, callActions: CallActions) {
        self.pil = pil
        self.voipLib = voipLib
        self.audioSession = audioSession
        self.callActions = callActions
        
        listenForAudioRouteChangesFromOS()
        setAppropriateDefaults()
    }
    
    public var isMicrophoneMuted: Bool {
        voipLib.isMicrophoneMuted
    }
    
    public func routeAudio(_ route: AudioRoute) {
        // The echo limiter is a brute-force method to prevent echo, it should only be used
        // when it is really necessary, such as when the user is using the phone's speaker.
        if (route == AudioRoute.speaker) {
            pil.calls.list.callArray.forEach { call in
                call.mifoneCall.echoLimiterEnabled = true
                call.mifoneCall.echoCancellationEnabled = false
            }
        } else {
            pil.calls.list.callArray.forEach { call in
                call.mifoneCall.echoLimiterEnabled = false
                call.mifoneCall.echoCancellationEnabled = true
            }
        }
        
        mifoneAudio.routeAudio(to: route)
        
        log("Routed audio to \(route)")
    }
    
    /// Launch a native UI dialog box that allows the user to choose from a list of inputs.
    public func launchAudioRoutePicker() {
        log("Launching native Audio Route Picker")
        
        if let routePickerButton = routePickerView.subviews.first(where: { $0 is UIButton }) as? UIButton {
            routePickerButton.sendActions(for: .touchUpInside)
        }
    }
    
    private func isRouteAvailable(_ route: AudioRoute) -> Bool {
        return mifoneAudio.hasAudioRouteAvailable(.phone)
    }
    
    private func findBluetoothName() -> String? {
        if mifoneAudio.currentRoute == .bluetooth {
            if let currentDevice = mifoneAudio.currentAudioDevice {
                return currentDevice.deviceName
            }
        }
        
        return mifoneAudio.findDevice(.bluetooth)?.deviceName
    }
    
    public func mute() { callActions.mute() }
    
    public func unmute() { callActions.unmute() }
    
    public func toggleMute() { callActions.toggleMute() }
    
    private func setAppropriateDefaults() {
        let route = isRouteAvailable(.bluetooth) ? AudioRoute.bluetooth : .phone
        
        mifoneAudio.routeAudio(
            to: route,
            onlySetDefaults: true
        )
        
        log("Set default audio route to \(route)")
    }
    
    private func listenForAudioRouteChangesFromOS() {
//        NotificationCenter.default.addObserver(
//            self,
//            selector: #selector(handleRouteChange),
//            name: AVAudioSession.routeChangeNotification,
//            object: nil
//        )
    }
    
    @objc func handleRouteChange(notification: Notification) {
        setAppropriateDefaults()
        log("Detected audio route change from the OS: \(mifoneAudio.audioDevicesAsString)")
        pil.events.broadcast(event: .audioStateUpdated(state: pil.sessionState))
    }
}
