import Foundation

public class Actions {
    
    let mifone: MiFoneManager
    let call: VoIPLibCall
    
    init(mifoneManager: MiFoneManager, call: VoIPLibCall) {
        self.mifone = mifoneManager
        self.call = call
    }
    
    /// Accept an incoming VoIPLibCall
    ///
    /// - Parameters:
    ///     - VoIPLibCall: The accepting VoIPLibCall
    /// - Returns: `Bool` Whether accepting went successfully
    public func accept() -> Bool {
        mifone.acceptCall(for: call)
    }
    
    /// End an VoIPLibCall.
    ///
    /// - Parameters:
    ///     - VoIPLibCall: The accepting VoIPLibCall
    /// - Returns: `Bool` Whether ending went successfully
    public func end() -> Bool {
        mifone.endCall(for: call)
    }
    
    /// Enable/disable the audio VoIPLibCall.
    /// This is a `VoIPLibCallKit` support function. Which must be VoIPLibCalled by the `CXProviderDelegate` on `didActivate` and `didDeactivate`.
    ///
    /// - Parameters:
    ///     - enabled: State of audio
    public func setAudio(enabled:Bool) {
        mifone.setAudio(enabled: enabled)
    }
    
    /// Set a VoIPLibCall on (un)hold
    ///
    /// - Parameters:
    ///     - VoIPLibCall: The VoIPLibCall
    ///     - onHold: The new hold state
    /// - Returns: `Bool` Whether the change was successful.
    public func hold(onHold hold:Bool) -> Bool {
        mifone.setHold(call: call, onHold: hold)
    }
    
    /// Transfer a VoIPLibCall. This is unattended.
    ///
    /// - Parameters:
    ///     - VoIPLibCall: The active VoIPLibCall
    ///     - number: Transfer to number
    /// - Returns: `Bool` Whether the transfer was successful.
    public func transfer(to number:String) -> Bool {
        mifone.transfer(call: call, to: number)
    }
    
    /// Begin process of attended transfer by VoIPLibCalling the transfer target's number.
    ///
    /// - Parameters:
    ///     - VoIPLibCall: The active VoIPLibCall
    ///     - number: The transfer target's number
    /// - Returns: `AttendedTransferVoIPLibCall` The struct with the two VoIPLibCalls.
    public func beginAttendedTransfer(to number:String) -> AttendedTransferSession? {
        mifone.beginAttendedTransfer(call: call, to:number)
    }
    
    /// Finish process of attended transfer by merging the VoIPLibCalls.
    ///
    /// - Parameter:
    ///     - attendedTransferVoIPLibCall: The struct with the two VoIPLibCalls.
    /// - Returns: `Bool` Whether the transfer was successful.
    public func finishAttendedTransfer(attendedTransferSession:AttendedTransferSession) -> Bool {
        mifone.finishAttendedTransfer(attendedTransferSession:attendedTransferSession)
    }
    
    /// Send Dtmf.
    ///
    /// - Parameter:
    ///     - VoIPLibCall: The VoIPLibCall with the active VoIPLibCall.
    ///     - dtmf: The string with the dtmf digits.
    public func sendDtmf(dtmf: String) {
        mifone.sendDtmf(call: call, dtmf: dtmf)
    }
    
    /// Get VoIPLibCall information.
    ///
    /// - Returns: A string with the VoIPLibCall info, empty when could not get any.
    public func VoIPLibCallInfo() -> String {
        mifone.provideCallInfo(call: call)
    }
}
