import Foundation

public struct Auth: Equatable {
    public let username: String
    public let password: String
    public let domain: String
    public let proxy: String
    public let transport: String
    public let port: Int
    public let secure: Bool

    public var isValid: Bool {
        get {
            !username.isEmpty && !password.isEmpty && !domain.isEmpty && port != 0 && !proxy.isEmpty
        }
    }

    public init(username: String, password: String, domain: String, proxy: String, transport: String, port: Int, secure: Bool) {
        self.username = username
        self.password = password
        self.domain = domain
        self.proxy = proxy
        self.transport = transport
        self.port = port
        self.secure = secure
    }

    public static func ==(lhs: Self, rhs: Self) -> Bool {
        lhs.username == rhs.username && lhs.password == rhs.password && lhs.domain == rhs.domain && lhs.proxy == rhs.proxy && lhs.transport == rhs.transport && lhs.port == rhs.port && lhs.secure == rhs.secure
    }
}
