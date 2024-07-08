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

            print("[start_IOS_PIL] licenceKey: \(licenceKey) accessToken: \(accessToken)")

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
    
    print("[LICENCE_KEY]  \(String(describing: oauth.licencesKey))")
    print("[ACCESS_TOKEN]  \(String(describing: oauth.accessToken))")
    
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
                        print("[RETURN] Token đã mã hóa 3 lần: \(tripleDecodedToken)")
                        let slicedStrings = ParseString.shared.sliceStringWithKeyVoid(tripleDecodedToken, key: stringKey)
                        print("[RETURN] sliceStringWithKeyVoid: \(slicedStrings)")
                        for part in slicedStrings {
                            if let decodedPart = ParseString.shared.base64Decode(part) {
                                authIndex.append(decodedPart)
                            } else {
                                print("[RETURN] Giải mã thất bại cho phần tử: \(part)")
                            }
                        }
                        
                        if authIndex.count >= 6 {
//                            let auth = Auth(
//                                username: decodedParts[3].description,
//                                password: decodedParts[4].description,
//                                domain: decodedParts[0].description,
//                                proxy: decodedParts[2].description,
//                                transport: decodedParts[5].description,
//                                port: 5567,
//                                secure: true
//                            )
                            
                            let auth = Auth(
                                username: "8007",
                                password: "f047a4946620e0782e805893a39c7a23",
                                domain: "pbx57.mipbx.vn",
                                proxy: "sipproxy01-2020.mipbx.vn",
                                transport: "tls",
                                port: 5567,
                                secure: true
                            )
                            print("[AUTH] extension:\(auth.username)  password:\(auth.password)  domain:\(auth.domain)  proxy:\(auth.proxy)  transport:\(auth.transport)")
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

func base64Decode(_ input: String) -> String? {
    guard let data = Data(base64Encoded: input),
          let decodedString = String(data: data, encoding: .utf8) else { return nil }
    return decodedString
}

func decodeTokenThreeTimes(_ token: String) -> String? {
    var decodedToken = token
    
    for _ in 1...3 {
        if let base64Decoded = base64Decode(decodedToken) {
            decodedToken = base64Decoded
        } else {
            return nil
        }
    }
    
    return decodedToken
}

func sliceStringWithKeyVoid(_ input: String, key: String) -> [String] {
    return input.components(separatedBy: key)
}

enum LicenceError: Error {
    case alreadyInitialized
    case invalidCredentials
    case invalidLicenceKey
}
