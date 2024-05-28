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
                   print("[RESULT]  \(value)")
                if let json = value as? [String: Any] {
                    print("[RESULT] 2 \(json)")
                    
                    if let data = json["data"] as? String {
                        completion(data)
                    } else {
                        print("Không tìm thấy trường 'data' hoặc kiểu dữ liệu không đúng")
                        completion(nil)
                    }
                } else {
                    print("Phản hồi không phải là JSON Dictionary")
                    completion(nil)
                }
                case .failure(let error):
                    print(error)
                    completion(nil)
                }
        }
    }
    
}
