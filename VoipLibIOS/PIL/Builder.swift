import Foundation
import Swinject

let di: Container = {
    register(Container())
}()

public class Builder {

    public var preferences: Preferences?
    public var auth: Auth?
    var applicationSetup: ApplicationSetup?
    
    internal init() {}

    internal func start() throws -> MFLib {
        if MFLib.isInitialized {
            throw PILError.alreadyInitialized
        }

        let pil = MFLib(applicationSetup: applicationSetup!)
        
        if let auth = auth {
            pil.auth = auth
        }
        
        if let preferences = preferences {
            pil.preferences = preferences
        } else {
            pil.preferences = Preferences()
        }
        
        return pil
    }
}

/// Initialise the iOS PIL, this should be called in your AppDelegate's didFinishLaunchingWithOptions method.
public func startIOSPIL(applicationSetup: ApplicationSetup, auth: Auth? = nil, preferences: Preferences? = nil) throws -> MFLib {
    let builder = Builder()
    builder.applicationSetup = applicationSetup
    builder.auth = auth
    builder.preferences = preferences
    let pil = try builder.start()
    pil.start()
    return pil
}
