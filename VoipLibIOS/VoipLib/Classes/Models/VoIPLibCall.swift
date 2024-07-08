import Foundation
import linphonesw

public class VoIPLibCall:NSObject {
    public let callId = UUID()
    let mifoneCall: MiFoneCall
    
    public var remoteNumber: String {
        get {
            mifoneCall.remoteAddress?.username ?? ""
        }
    }
    
    public var displayName: String {
        get {
            mifoneCall.remoteAddress?.displayName ?? ""
        }
    }
    
    public var remoteEnvironment: String {
        get {
            mifoneCall.remoteAddress?.domain ?? ""
        }
    }
    
    public var state:VoipLibCallState {
        get {
            VoipLibCallState(rawValue: mifoneCall.state.rawValue) ?? .idle
        }
    }
    
    public var remotePartyId: String {
        get {
            mifoneCall.params?.getCustomHeader(headerName: "Remote-Party-ID") ?? ""
        }
    }
    
    public var pAssertedIdentity: String {
        get {
            mifoneCall.params?.getCustomHeader(headerName: "P-Asserted-Identity") ?? ""
        }
    }
    
    public var durationInSec:Int? {
        mifoneCall.duration
    }
    
    public var isIncoming:Bool {
        return mifoneCall.dir == .Incoming
    }
    
    public var direction: Direction {
        return mifoneCall.dir == .Incoming ? .inbound : .outbound
    }
    
    public var quality: Quality {
        return Quality(average: mifoneCall.averageQuality, current: mifoneCall.currentQuality)
    }
    
    /// This can be used to check if different  objects have the same linphone property.
    public var callHash: Int? {
        return mifoneCall.getCobject?.hashValue
    }
    
    public var reason: String {
        return String.init(describing: mifoneCall.reason)
    }
    
    public var wasMissed: Bool {
        guard let log = mifoneCall.callLog else {
            return false
        }
        
        let missedStatuses = [
            MiFoneCall.Status.Missed,
            MiFoneCall.Status.Aborted,
            MiFoneCall.Status.EarlyAborted,
        ]
        
        return log.dir == MiFoneCall.Dir.Incoming && missedStatuses.contains(log.status)
    }
    
    init?(mifoneCall: MiFoneCall) {
        guard mifoneCall.remoteAddress != nil else { return nil }
        self.mifoneCall = mifoneCall
    }
        
    /// Resumes a .
    /// The  needs to have been paused previously with `pause()`
    public func resume() throws {
        try mifoneCall.resume()
    }
    
    /// Pauses the .
    /// be played to the remote user. The only way to resume a paused  is to  `resume()`
    public func pause() throws {
        try mifoneCall.pause()
    }
}

extension VoIPLibCall {
    public static func == (lhs: VoIPLibCall, rhs: VoIPLibCall) -> Bool {
      return lhs.callId == rhs.callId
    }
}
