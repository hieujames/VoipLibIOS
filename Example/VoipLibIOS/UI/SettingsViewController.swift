import Foundation
import QuickTableViewController
import VoipLibIOS

final class SettingsViewController: QuickTableViewController {

    private let defaults = UserDefaults.standard

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let useApplicationRingtone = MFLib.shared != nil ? MFLib.shared!.preferences.useApplicationRingtone : false
        let includesCallsInRecents = MFLib.shared != nil ? MFLib.shared!.preferences.includesCallsInRecents : false
        
        tableContents = [

            Section(title: "Authentication", rows: [
                TapActionRow(text: "Authentication", action: { row in
                    let pil = MFLib.shared!
                    pil.performRegistrationCheck { (success) in
                        DispatchQueue.main.async {
                            let alert = UIAlertController(title: "Authentication Test", message: success ? "Authenticated successfully!" : "Authentication failed :(", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                            self.present(alert, animated: true)
                        }
                    }
                })
            ]),
            
            Section(title: "Preferences", rows: [
                SwitchRow(text: "Use Application Ringtone", switchValue: useApplicationRingtone, action: { row in
                    if let switchRow = row as? SwitchRowCompatible {
                        if let pil = MFLib.shared {
                            pil.preferences = Preferences.init(useApplicationRingtone: switchRow.switchValue, includesCallsInRecents: includesCallsInRecents)
                        }
                    }
                }),
                SwitchRow(text: "Show calls in native recents", switchValue: includesCallsInRecents, action: { row in
                    if let switchRow = row as? SwitchRowCompatible {
                        if let pil = MFLib.shared {
                            pil.preferences = Preferences.init(useApplicationRingtone: useApplicationRingtone, includesCallsInRecents: switchRow.switchValue)
                        }
                    }
                }),
            ])
        ]
    }
    
    private func promptUserWithTextField(row: Row, title: String, key: String) {
        let alert = UIAlertController(title: title, message: "", preferredStyle: UIAlertController.Style.alert)
        let action = UIAlertAction(title: "Save", style: .default) { (alertAction) in
            let textField = alert.textFields![0] as UITextField
            self.defaults.set(textField.text, forKey: key)
            
            if key.contains("voipgrid") {
                SettingsViewController.attemptVoipgridLogin { apiToken in
                    self.viewDidLoad()
                }
            } else {
                self.viewDidLoad()
            }
        }
        alert.addTextField { (textField) in
            textField.text = self.userDefault(key: key)
        }
        alert.addAction(action)
        self.present(alert, animated:true, completion: nil)
    }
    
    static func attemptVoipgridLogin(completion: @escaping (String?) -> Void) {
        let voipgridLogin = VoIPGRIDLogin()
        voipgridLogin.login { apiToken in
            guard let apiToken = apiToken else {
                UserDefaults.standard.removeObject(forKey: "voipgrid_api_token")
                SettingsViewController.unregisterMiddleware(completion: nil)
                completion(apiToken)
                return
            }
            print("[API_TOKEN]  \(apiToken)")
//            if let pil = MFLib.shared {
//                if let tripleEncodedToken = pil.decodeTokenThreeTimes(apiToken) {
//                    print("[RETURN] Token đã mã hóa 3 lần: \(tripleEncodedToken)")
//                    
//                    let slicedStrings = pil.sliceStringWithKeyVoid(tripleEncodedToken, key: "b6aed9ab7cdf85432c321757b4d48153")
//                    print("[RETURN] Chuỗi đã cắt: \(slicedStrings)")
//                    
//                    var decodedParts: [String] = []
//                    for part in slicedStrings {
//                        if let decodedPart = pil.base64Decode(part) {
//                            decodedParts.append(decodedPart)
//                        } else {
//                            print("[RETURN] Giải mã thất bại cho phần tử: \(part)")
//                        }
//                    }
//                    
//                    print("[RETURN] Các phần tử đã giải mã: \(decodedParts)")
//                    
//                    for (index, part) in decodedParts.enumerated() {
//                        print("[RETURN] Phần tử \(index): \(part)")
//                    }
//                    
//                } else {
//                    print("[RETURN] Mã hóa thất bại")
//                }
//            }
            
            UserDefaults.standard.set(apiToken, forKey: "voipgrid_api_token")
            completion(apiToken)
        }
    }
    
    private func attemptVoIPAccountEncryptionChangeTo(encryption: Bool) {
        let middleware = VoIPGRIDMiddleware()
        middleware.setVoIPAccountEncryption(encryption: encryption, completion: { _ in
            self.viewDidLoad()
        })
    }
    
    static func registerMiddleware(completion: ((Bool) -> Void)?) {
        let middleware = VoIPGRIDMiddleware()
        middleware.register { success in
            if success {
                UserDefaults.standard.set(true, forKey: "middleware_is_registered")
            }
            completion?(success)
        }
    }
    
    static func unregisterMiddleware(completion: ((Bool) -> Void)?) {
        let middleware = VoIPGRIDMiddleware()
        middleware.unregister { success in
            if success {
                UserDefaults.standard.set(false, forKey: "middleware_is_registered")
            }
            completion?(success)
        }
    }

    private func userDefault(key: String) -> String {
        defaults.object(forKey: key) as? String ?? ""
    }
}

