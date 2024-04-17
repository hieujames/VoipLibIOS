import Foundation
import UIKit
import VoipLibIOS
import Contacts

class InCallDialpadViewController: UIViewController {
    
    // MARK: Properties
    @IBOutlet weak var numberPreview: UITextField!
        
    private let defaults = UserDefaults.standard
    
    let pil = MFLib.shared!

    // MARK: Life circle
    override func viewDidLoad() {
        super.viewDidLoad()

        numberPreview.text = ""
    }
    
    // MARK: UI
    @IBAction func hideButtonWasPressed(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func keypadButtonWasPressed(_ sender: UIButton) {
        let currentNumberPreview = numberPreview.text ?? ""
        let buttonNumber = sender.currentTitle ?? ""
        
        pil.actions.sendDtmf(buttonNumber)
        
        numberPreview.text = currentNumberPreview + buttonNumber
    }
}

