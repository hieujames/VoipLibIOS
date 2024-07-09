import Foundation
import CallKit

@available(iOS 11.0, *)
public class MFLib {

    let app: ApplicationSetup
    
    private let callFactory = di.resolve(PILCallFactory.self)!
    // private lazy var pushKit: PushKitDelegate = { PushKitDelegate(middleware: app.middleware!) }()
    private lazy var voipLibHelper = { di.resolve(VoIPLibHelper.self)! }()
    internal lazy var platformIntegrator = { di.resolve(PlatformIntegrator.self)! }()
    internal lazy var voipLibEventTranslator = { di.resolve(VoipLibEventTranslator.self)! }()
    internal lazy var contacts = { di.resolve(Contacts.self)! }()
    
    let voipLib: LibModule = di.resolve(LibModule.self)!
    lazy var iOSCallKit = { di.resolve(IOSCallKit.self)! }()
    
    public lazy var actions = { di.resolve(CallActions.self)! }()
    public lazy var audio = { di.resolve(AudioManager.self)! }()
    public lazy var events = { di.resolve(EventsManager.self)! }()
    public lazy var calls = { di.resolve(Calls.self)! }()
    public lazy var iOS = { di.resolve(IOS.self)! }()
    

    
    public var sessionState: CallSessionState {
        get {
            CallSessionState(activeCall: calls.activeCall, inactiveCall: calls.inactiveCall, audioState: audio.state)
        }
    }
    
    static public var isInitialized: Bool {
        get {
            shared != nil
        }
    }
    
    static public var shared: MFLib?
    
    /// The user preferences for the PIL, when this value is updated it will trigger
    /// a full PIL restart and re-register.
    public var preferences = Preferences() {
        didSet {
            iOSCallKit.refresh()
            contacts.clearCache()
        }
    }
    
    /// The authentication details for the PIL, when this value is updated it will
    /// trigger a full re-register.
    public var oauth: OAuth?
    public var auth: Auth?
    
    init(applicationSetup: ApplicationSetup) {
        self.app = applicationSetup
        MFLib.shared = self
        events.listen(delegate: platformIntegrator)
        self.iOS.startListeningForSystemNotifications()
        voipLib.initialize(
            config: VoIPLibConfig(
                callDelegate: voipLibEventTranslator,
                logListener: { message in
                    self.app.logDelegate?.onLogReceived(message: message, level: LogLevel.info)
                }
            )
        )
    }

    /// Check if the PIL is currently configured to successfully register.
    /// Attempt to boot and register to see if user credentials are correct.
    /// - Parameter callback: Called when the registration check has been completed.
    public func performRegistrationCheck(callback: @escaping (Bool) -> Void) {
        self.voipLibHelper.register(callback: callback)
    }
    
    /// Start the PIL, unless the force options are provided, the method will not restart or re-register.
    /// - Parameters:
    ///   - forceInitialize: a Bool to determine if the voipLib will restart.
    ///   - forceReregister: a Bool to determine the voipLib will re-register.
    ///   - completion:  Called with param success when the PIL has been started.
    @available(*, deprecated, message: "Force parameters no longer used, use new start() method instead.")
    public func start(forceInitialize: Bool = false, forceReregister: Bool = false, completion: ((_ success: Bool) -> Void)? = nil) {
        if auth == nil {
            completion?(false)
            log("There are no authentication details provided")
            return
        }
        
        iOSCallKit.initialize()

        voipLibHelper.register { success in
            completion?(success)
        }
    }
    
    public func start(completion: ((_ success: Bool) -> Void)? = nil) {
        start(forceInitialize: false, forceReregister: false, completion: completion)
    }
    
    /// Stop the PIL, this will remove all authentication credentials from memory and destroy the underlying voip lib. This will not destroy the PIL.
    ///
    /// This should be called when a user logs-out (or similar action).
    public func stop() {
        auth = nil
        voipLib.unregister()
    }
    
    /// Place a call to the given number.
    /// This will boot the lib if it is not already booted.
    /// - Parameter number: the String number to call.
    public func call(number: String) {
        print("[OUTGOING_CALL]  \(number)")
        if calls.isInCall {
            events.broadcast(event: .outgoingCallSetupFailed(reason: .inCall))
            return
        }
        
        voipLib.refreshRegistration()
        
        
        
        self.iOSCallKit.startCall(number: number.normalizedForCalling)
    }
    
    internal func writeLog(_ message: String, level: LogLevel = .info) {
        app.logDelegate?.onLogReceived(message: "Voip-Lib-IOS: \(message)", level: level)
    }
    
    /// Check whether the PIL has been initialized and the authentication details are set.
    private var isPreparedToStart: Bool {
        auth != nil && voipLib.isInitialized
        
    }
    
    /// Currently this just defers to ``isPreparedToStart`` as they have the same conditions but this may change in the future.
    internal var isStarted: Bool {
        isPreparedToStart
    }
    
    public func performEchoCancellationCalibration() {
        log("Beginning echo cancellation calibration")
        voipLib.startEchoCancellerCalibration()
    }
}

internal func log(_ message: String, level: LogLevel = .info) {
    if let pil = MFLib.shared {
        pil.writeLog(message, level: level)
    }
}

public enum PILError: Error {
    case alreadyInitialized
}

internal extension String {
    /// Remove - ( ) characters from the number.
    var normalizedForCalling: String {
        let regex = try! NSRegularExpression(pattern: "[-()]")
        
        return regex.stringByReplacingMatches(
            in: self,
            range: NSMakeRange(0, count),
            withTemplate: ""
        )
    }
}

struct InvalidLicenceException: Error {
    let message: String
}