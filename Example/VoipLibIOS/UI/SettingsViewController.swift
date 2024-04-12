import Foundation
import QuickTableViewController
import VoipLibIOS

final class SettingsViewController: QuickTableViewController {

    private let defaults = UserDefaults.standard

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let useApplicationRingtone = PIL.shared != nil ? PIL.shared!.preferences.useApplicationRingtone : false
        let includesCallsInRecents = PIL.shared != nil ? PIL.shared!.preferences.includesCallsInRecents : false
        
        tableContents = [

            Section(title: "Authentication", rows: [
                NavigationRow(text: "Username", detailText: .subtitle(userDefault(key: "username")), action: { [weak self] in self?.promptUserWithTextField(row: $0, title: "Username", key: "username") }),
                NavigationRow(text: "Password", detailText: .subtitle(userDefault(key: "password")), action: { [weak self] in self?.promptUserWithTextField(row: $0, title: "Password", key: "password") }),
                NavigationRow(text: "Domain", detailText: .subtitle(userDefault(key: "domain")), action: { [weak self] in self?.promptUserWithTextField(row: $0, title: "Domain", key: "domain") }),
                NavigationRow(text: "Port", detailText: .subtitle(userDefault(key: "port")), action: { [weak self] in self?.promptUserWithTextField(row: $0, title: "Port", key: "port") }),
                NavigationRow(text: "Proxy", detailText: .subtitle(userDefault(key: "proxy")), action: { [weak self] in self?.promptUserWithTextField(row: $0, title: "Proxy", key: "proxy") }),
                NavigationRow(text: "Transport", detailText: .subtitle(userDefault(key: "transport")), action: { [weak self] in self?.promptUserWithTextField(row: $0, title: "Transport", key: "transport") }),
                TapActionRow(text: "Authentication", action: { row in
                    let pil = PIL.shared!
                    pil.auth = Auth(
                        username: self.userDefault(key: "username"),
                        password: self.userDefault(key: "password"),
                        domain: self.userDefault(key: "domain"),
                        proxy: self.userDefault(key: "proxy"),
                        transport: self.userDefault(key: "transport"),
                        port: Int(self.userDefault(key: "port")) ?? 0,
                        secure: self.defaults.bool(forKey: "encryption")
                    )
                    pil.performRegistrationCheck { (success) in
                        DispatchQueue.main.async {
                            let alert = UIAlertController(title: "Authentication Test", message: success ? "Authenticated successfully!" : "Authentication failed :(", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                            self.present(alert, animated: true)
                        }
                    }
                })
            ]),

            Section(title: "Authorize", rows: [
                NavigationRow(text: "Username", detailText: .subtitle(userDefault(key: "voipgrid_username")), action: { [weak self] in self?.promptUserWithTextField(row: $0, title: "Username", key: "voipgrid_username") }),
                NavigationRow(text: "Password", detailText: .subtitle(userDefault(key: "voipgrid_password")), icon: .named("gear"), action: { [weak self] in self?.promptUserWithTextField(row: $0, title: "Password", key: "voipgrid_password") }),
                
                NavigationRow(text: "VoIPGRID Token", detailText: .subtitle(userDefault(key: "voipgrid_api_token")), action: nil),
                NavigationRow(text: "Push Kit Token", detailText: .subtitle(userDefault(key: "push_kit_token")), action: nil),
                //NavigationRow(text: "Middleware", detailText: .subtitle(defaults.bool(forKey: "middleware_is_registered") ? "Registered" : "Not Registered"), action: nil),
                TapActionRow(text: "Register with Account", action: { _ in SettingsViewController.registerMiddleware { success in self.viewDidLoad() } }),
                
            ]),
            
            Section(title: "Preferences", rows: [
                SwitchRow(text: "Use Application Ringtone", switchValue: useApplicationRingtone, action: { row in
                    if let switchRow = row as? SwitchRowCompatible {
                        if let pil = PIL.shared {
                            pil.preferences = Preferences.init(useApplicationRingtone: switchRow.switchValue, includesCallsInRecents: includesCallsInRecents)
                        }
                    }
                }),
                SwitchRow(text: "Show calls in native recents", switchValue: includesCallsInRecents, action: { row in
                    if let switchRow = row as? SwitchRowCompatible {
                        if let pil = PIL.shared {
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

