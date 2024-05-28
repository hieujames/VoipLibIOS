//
//  ParseString.swift
//  Alamofire
//
//  Created by James Ho on 5/24/24.
//

import Foundation

public class ParseString {
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

}
