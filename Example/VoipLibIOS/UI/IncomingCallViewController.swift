import Foundation
import UIKit
import VoipLibIOS

@available(iOS 13.0.0, *)
class IncomingCallViewController: UIViewController, PILEventDelegate {
    
    @IBOutlet weak var callTitle: UILabel!
    @IBOutlet weak var callSubtitle: UILabel!
    
    let pil = MFLib.shared!
    
    private var event: Event?
    private var callSessionState: CallSessionState?
    
    override func viewWillAppear(_ animated: Bool) {
        render()
        pil.events.listen(delegate: self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        pil.events.stopListening(delegate: self)
    }
    
    // MARK: Ui/Ux
    func onEvent(event: Event) {
        self.event = event
        
        switch event {
        case .callEnded(_):
            self.dismiss(animated: true)
        case .incomingCallReceived(let state),
             .outgoingCallStarted(let state),
             .callDurationUpdated(let state),
             .callConnected(let state),
             .callStateUpdated(let state),
             .attendedTransferAborted(let state),
             .attendedTransferEnded(let state),
             .attendedTransferConnected(let state),
             .attendedTransferStarted(let state),
             .audioStateUpdated(let state):
            self.callSessionState = state
            fallthrough
        default:
            self.render()
        }
    }
    
    private func render() {
        guard let call = callSessionState?.activeCall ?? pil.calls.activeCall else {
            self.dismiss(animated: true)
            return
        }
        
        DispatchQueue.main.async {
            self.renderCallInfo(call: call)
            //self.renderCallButtons(call: call)
        }
        
        //renderForEventStatus(call: call)
    }
    
    private func renderCallInfo(call: Call) {
        self.callTitle.text = "\(call.remotePartyHeading) - \(call.remotePartySubheading)"
        self.callSubtitle.text = String(describing: call.direction)
    }
    
    @IBAction func hangUpButtonWasPressed(_ sender: Any) {
//        guard let call = callManager.activeCall else {
//            self.dismiss(animated: true)
//            return
//        }
//        _ = voipLib.actions(call: call).end()
        pil.actions.decline()
    }
    
    @IBAction func answerButtonWasPressed(_ sender: Any) {
//        guard let call = callManager.activeCall else {
//            self.dismiss(animated: true)
//            return
//        }
//        _ = voipLib.actions(call: call).accept()
//        
//        self.dismiss(animated: false)
//        
//        let appDelegate = UIApplication.shared.delegate as! AppDelegate
//        if let nav = appDelegate.window?.rootViewController as? UITabBarController {
//            nav.performSegue(withIdentifier: "LaunchCallSegue", sender: nav)
//        }
        pil.actions.answer()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if let nav = appDelegate.window?.rootViewController as? UITabBarController {
            nav.performSegue(withIdentifier: "LaunchCallSegue", sender: nav)
        }
    }
    
}
