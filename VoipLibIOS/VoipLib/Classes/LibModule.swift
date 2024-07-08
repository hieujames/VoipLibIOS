import Foundation

class LibModule {
    
    static public let shared = LibModule()
    
    var isInitialized: Bool {
        get { mifone.isInitialized }
    }
    
    var config: VoIPLibConfig? {
        mifone.config
    }
    
    var audio: MiFoneAudio {
        mifone.mifoneAudio
    }
    
    let mifone: MiFoneManager
    
    init() {
        mifone = MiFoneManager()
    }
    
    func initialize(config: VoIPLibConfig) {
        if (!isInitialized) {
            _ = mifone.initialize(config: config)
        }
    }
    
    /// This `registers` your user on SIP. You need this before placing a call.
    /// - Returns: Bool containing register result
    func register(callback: @escaping RegistrationCallback) {
        mifone.register(callback: callback)
    }
    
    func refreshRegistration() {
        mifone.refreshRegistration()
    }
    
    func terminateAllCalls() {
        mifone.terminateAllCalls()
    }
    
    /// This `unregisters` your user on SIP.
    ///
    /// - Parameters:
    ///     - finished: Called async when unregistering is done.
    func unregister() {
        mifone.unregister()
    }
    
    /// Call a phone number
    ///
    /// - Parameters:
    ///     - number: The phone number to call
    /// - Returns: Returns true when call succeeds, false when the number is an empty string or the phone service isn't ready.
    func call(to number: String) -> Bool {
        return mifone.call(to: number) != nil
    }
    
    var isMicrophoneMuted:Bool {
        get {
            mifone.isMicrophoneMuted
        }
        
        set(muted) {
            mifone.setMicrophone(muted: muted)
        }
    }
    
    func actions(call: VoIPLibCall) -> Actions {
        Actions(mifoneManager: mifone, call: call)
    }
    
    func startEchoCancellerCalibration() {
        do {
            try mifone.mifoneCore.startEchoCancellerCalibration()
        } catch {}
    }
    
    private func checkLicenceKey(_ licenceKey: String, completion: @escaping (Bool) -> Void) {
            DispatchQueue.global().async {
                let isValid = licenceKey == "trial"
                DispatchQueue.main.async {
                    completion(isValid)
                }
            }
        }
}
