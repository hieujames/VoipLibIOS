import Foundation
import Swinject
import CallKit
import AVFoundation

// Resolves the current preferences from the [PIL] that doesn't require depending on the whole
// [PIL] object.
typealias CurrentPreferencesResolver = () -> Preferences

var register: (Container) -> Container = {
    
    $0.register(MFLib.self) { _ in
        MFLib.shared!
    }.inObjectScope(.container)
        
    $0.register(CallActions.self) { c in
        CallActions(
            controller: CXCallController(),
            pil: c.resolve(MFLib.self)!,
            voipLib: c.resolve(LibModule.self)!
        )
    }.inObjectScope(.container)
    
    $0.register(EventsManager.self) { c in
        EventsManager(
            mf: c.resolve(MFLib.self)!,
            calls: c.resolve(Calls.self)!
        )
    }.inObjectScope(.container)
    
    $0.register(Calls.self) { c in
        Calls(factory: c.resolve(PILCallFactory.self)!)
    }.inObjectScope(.container)
    
    $0.register(AudioManager.self) { c in AudioManager(
        pil: c.resolve(MFLib.self)!,
        voipLib: c.resolve(LibModule.self)!,
        audioSession: AVAudioSession.sharedInstance(),
        callActions: c.resolve(CallActions.self)!
    ) }.inObjectScope(.container)
    
    $0.register(CurrentPreferencesResolver.self) { c in
        {c.resolve(MFLib.self)!.preferences}
    }.inObjectScope(.container)
    
    $0.register(Contacts.self) { c in Contacts(
        preferences: c.resolve(CurrentPreferencesResolver.self)!
    ) }.inObjectScope(.container)
    
    $0.register(PILCallFactory.self) { c in
        PILCallFactory(contacts: c.resolve(Contacts.self)!)
    }.inObjectScope(.container)
    
    $0.register(LibModule.self) { _ in LibModule.shared }.inObjectScope(.container)
    
    $0.register(VoipLibEventTranslator.self) { c in
        VoipLibEventTranslator(pil: c.resolve(MFLib.self)!)
    }.inObjectScope(.container)
    
    $0.register(PlatformIntegrator.self) { c in
        PlatformIntegrator(
            pil: c.resolve(MFLib.self)!,
            missedCallNotification: c.resolve(MissedCallNotification.self)!,
            callFactory: c.resolve(PILCallFactory.self)!
        )
    }.inObjectScope(.container)
    
    $0.register(IOS.self) { c in
        IOS(pil: c.resolve(MFLib.self)!)
    }.inObjectScope(.container)
    
    $0.register(VoIPLibHelper.self) { c in
        VoIPLibHelper(
            voipLib: c.resolve(LibModule.self)!,
            pil: c.resolve(MFLib.self)!
        )
    }.inObjectScope(.container)
    
    $0.register(IOSCallKit.self) { c in
        IOSCallKit(
            pil: c.resolve(MFLib.self)!,
            voipLib: c.resolve(LibModule.self)!
        )
    }.inObjectScope(.container)
    
    $0.register(MissedCallNotification.self) { c in
        MissedCallNotification(
            center: UNUserNotificationCenter.current()
        )
    }.inObjectScope(.container)
    
    return $0
}




