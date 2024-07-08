import Foundation
import linphonesw

internal class MiFoneListener: CoreDelegate {
    
    private let headersToPreserve = ["Remote-Party-ID", "P-Asserted-Identity"]
    
    let mifoneManager:MiFoneManager
    
    init(manager:MiFoneManager) {
        mifoneManager = manager
    }
    
    func onCallStateChanged(core: Core, call: MiFoneCall, state: MiFoneCall.State, message: String) {
        log("OnVoIPLibCallStateChanged, state:\(state) with message:\(message).")

        guard let voipLibCall = VoIPLibCall(mifoneCall: call) else {
            log("Unable to create VoIPLibCall, no remote address")
            return
        }

        guard let delegate = self.mifoneManager.config?.callDelegate else {
            log("Unable to send events as no VoIPLibCall delegate")
            return
        }
        
        print("STATE:  \(state)   MESSAGE:  \(message)")
        

        DispatchQueue.main.async {
            switch state {
                case .OutgoingInit:
                    delegate.outgoingCallCreated(voipLibCall)
                case .IncomingReceived:
                    self.preserveHeaders(mifoneCall: call)
                    delegate.incomingCallReceived(voipLibCall)
                case .Connected:
                    delegate.callConnected(voipLibCall)
                case .End, .Error:
                    delegate.callEnded(voipLibCall)
                case .Released:
                    delegate.callReleased(voipLibCall)
                default:
                    delegate.callUpdated(voipLibCall, message: message)
            }
        }
    }
    
    func onTransferStateChanged(core: Core, transfered: MiFoneCall, VoIPLibCallState: MiFoneCall.State) {
        guard let delegate = self.mifoneManager.config?.callDelegate else {
            log("Unable to send VoIPLibCall transfer event as no VoIPLibCall delegate")
            return
        }
        
        guard let voipLibVoIPLibCall = VoIPLibCall(mifoneCall: transfered) else {
            log("Unable to create VoIPLibCall, no remote address")
            return
        }
        
        delegate.attendedTransferMerged(voipLibVoIPLibCall)
    }
    
    /**
            Some headers only appear in the initial invite, this will check for any headers we have flagged to be preserved
     and retain them across all iterations of the LinphoneVoIPLibCall.
     */
    private func preserveHeaders(mifoneCall: MiFoneCall) {
        headersToPreserve.forEach { key in
            let value = mifoneCall.getToHeader(headerName: key)
            mifoneCall.params?.addCustomHeader(headerName: key, headerValue: value)
        }
    }
    
    func onAudioDevicesListUpdated(core: Core) {
        log("onAudioDevicesListUpdated: \(core.audioDevicesAsString)")
    }
}
