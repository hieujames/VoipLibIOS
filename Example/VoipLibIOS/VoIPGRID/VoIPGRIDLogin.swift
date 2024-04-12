import Foundation
import Alamofire

class VoIPGRIDLogin {
    
    private let defaults = UserDefaults.standard
    
    public func login(completion: @escaping (String?) -> Void) {
    
        let username = defaults.object(forKey: "voipgrid_username") as? String ?? ""
        let password = defaults.object(forKey: "voipgrid_password") as? String ?? ""
        
        AF.request(
            "https://api-prod.mipbx.vn/api/v1/users/login",
            method: .post,
            parameters: ["email" : username, "password" : password, "type": "sf"],
            encoder: JSONParameterEncoder.default
        ).responseJSON { response in
            debugPrint(response)
            
            switch response.result {
                case .success(let value):
                    guard let json = value as? Dictionary<String, String> else {
                        completion(nil)
                        return
                    }
                    completion(json["api_token"]!)
                case .failure(let error):
                    print(error)
                    completion(nil)
                }
        }
    }
    
}
