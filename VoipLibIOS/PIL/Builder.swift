import Foundation
import Swinject

let di: Container = {
    register(Container())
}()

public class Builder {

    public var preferences: Preferences?
    public var oauth: OAuth?
    public var auth: Auth?
    var applicationSetup: ApplicationSetup?
    
    internal init() {}

    internal func start() throws -> MFLib {
        if MFLib.isInitialized {
            throw PILError.alreadyInitialized
        }

        let pil = MFLib(applicationSetup: applicationSetup!)
        
        if let oauth = oauth {
            pil.oauth = oauth
        }
        
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
public func startIOSPIL(applicationSetup: ApplicationSetup, oauth: OAuth? = nil, preferences: Preferences? = nil, completion: @escaping (Result<MFLib, Error>) -> Void) {
    
    DispatchQueue.global().async {
        do {
            guard let licenceKey = oauth?.licencesKey, !licenceKey.isEmpty,
                  let accessToken = oauth?.accessToken, !accessToken.isEmpty else {
                throw LicenceError.invalidCredentials
            }

            guard licenceKey == "trial" else {
                throw LicenceError.invalidLicenceKey
            }

            print("[PIL-CHECK] licenceKey: \(licenceKey) accessToken: \(accessToken)")

            fetchUserInfo(oauth: oauth!) { auth in
                guard let auth = auth else {
                    completion(.failure(LicenceError.invalidCredentials))
                    return
                }
                
                DispatchQueue.main.async {
                    let builder = Builder()
                    builder.applicationSetup = applicationSetup
                    builder.oauth = oauth
                    builder.auth = auth
                    builder.preferences = preferences
                    do {
                        let pil = try builder.start()
                        pil.start()
                        completion(.success(pil))
                    } catch {
                        completion(.failure(error))
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                completion(.failure(error))
            }
        }
    }
}

private func fetchUserInfo(oauth: OAuth, completion: @escaping (Auth?) -> Void) {
    var authIndex: [String] = []
    
    let params = ["mi_token": oauth.accessToken]
    HttpClient.shared.postRequest(urlString: "https://api-prod.mipbx.vn/api/v1/mifone/sdk/authen", params: params as [String : Any]) { result in
        switch result {
        case .success(let data):
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print("[JSON] \(String(describing: json["data"]))")
                    guard let stringValue = json["data"] as? String,
                          let stringKey = json["secret"] as? String else {
                        completion(nil)
                        return
                    }
                    if let tripleDecodedToken = ParseString.shared.decodeTokenThreeTimes(stringValue) {
                        let slicedStrings = ParseString.shared.sliceStringWithKeyVoid(tripleDecodedToken, key: stringKey)
                        for part in slicedStrings {
                            if let decodedPart = ParseString.shared.base64Decode(part) {
                                authIndex.append(decodedPart)
                            } else {
                                print("[ERROR] \(part)")
                            }
                        }
                        
                        if authIndex.count >= 6 {
                            let auth = Auth(
                                username: authIndex[3].description,
                                password: authIndex[4].description,
                                domain: authIndex[0].description,
                                proxy: authIndex[2].description,
                                transport: authIndex[5].description,
                                port: Int(authIndex[1]) ?? 5567,
                                secure: true
                            )
                            completion(auth)
                        } else {
                            completion(nil)
                        }
                    } else {
                        completion(nil)
                    }
                } else {
                    completion(nil)
                }
            } catch {
                completion(nil)
            }
        case .failure(let error):
            print("Error fetching user info: \(error.localizedDescription)")
            completion(nil)
        }
    }
}

enum LicenceError: Error {
    case alreadyInitialized
    case invalidCredentials
    case invalidLicenceKey
}
