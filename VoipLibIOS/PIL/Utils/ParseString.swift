//
//  ParseString.swift
//  Alamofire
//
//  Created by James Ho on 5/24/24.
//

import Foundation

public class ParseString {
    
    static let shared = ParseString()

    private init() {}
    
    func base64Encode(_ input: String) -> String? {
        guard let data = input.data(using: .utf8) else { return nil }
        return data.base64EncodedString()
    }

    func encodeTokenThreeTimes(_ token: String) -> String? {
        var encodedToken = token
        
        for _ in 1...3 {
            if let base64Encoded = base64Encode(encodedToken) {
                encodedToken = base64Encoded
            } else {
                return nil
            }
        }
        
        return encodedToken
    }

    func sliceStringWithKey(_ input: String, key: String) -> [String] {
        var slicedStrings: [String] = []
        var currentIndex = input.startIndex
        
        for character in key {
            let length = Int(character.asciiValue! - Character("a").asciiValue! + 1)
            let endIndex = input.index(currentIndex, offsetBy: length, limitedBy: input.endIndex) ?? input.endIndex
            
            let substring = String(input[currentIndex..<endIndex])
            slicedStrings.append(substring)
            
            currentIndex = endIndex
            if currentIndex == input.endIndex { break }
        }
        
        if currentIndex < input.endIndex {
            slicedStrings.append(String(input[currentIndex...]))
        }
        
        return slicedStrings
    }

    func sliceStringWithKeyVoid(_ input: String, key: String) -> [String] {
        return input.components(separatedBy: key)
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
    
    public func loadConfig() -> [String: Any]? {
        guard let url = Bundle.main.url(forResource: "Config", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        
        do {
            let config = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            return config
        } catch {
            print("Error loading config: \(error.localizedDescription)")
            return nil
        }
    }

}
