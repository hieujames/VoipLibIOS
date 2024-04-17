import Foundation

public class EventsManager {
    
    private let mf: MFLib
    private let calls: Calls
    private var listeners = [ObjectIdentifier : EventListener]()
    
    init(mf: MFLib, calls: Calls) {
        self.mf = mf
        self.calls = calls
    }
    
    public func listen(delegate: PILEventDelegate) {
        let id = ObjectIdentifier(delegate)
        listeners[id] = EventListener(listener: delegate)
    }
    
    public func stopListening(delegate: PILEventDelegate) {
        let id = ObjectIdentifier(delegate)
        listeners.removeValue(forKey: id)
    }
    
    internal func broadcast(event: Event) {
        if !mf.isStarted {
            return
        }
        
        for (id, listener) in listeners {
            guard let delegate = listener.listener else {
                listeners.removeValue(forKey: id)
                continue
            }
            
            delegate.onEvent(event: event)
        }
    }

    struct EventListener {
        weak var listener: PILEventDelegate?
    }
}
