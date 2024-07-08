//
//  Licenses.swift
//  VoipLibIOS_Example
//
//  Created by James Ho on 7/1/24.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation

public struct OAuth: Equatable {
    public let licencesKey: String
    public let accessToken: String

    public var isValid: Bool {
        !licencesKey.isEmpty && !accessToken.isEmpty
    }

    public init(licencesKey: String, accessToken: String) {
        self.licencesKey = licencesKey
        self.accessToken = accessToken
    }

    public static func ==(lhs: Self, rhs: Self) -> Bool {
        lhs.licencesKey == rhs.licencesKey && lhs.accessToken == rhs.accessToken
    }
}
