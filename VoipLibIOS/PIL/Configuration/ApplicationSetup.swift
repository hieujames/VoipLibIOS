import Foundation

public struct ApplicationSetup {
    public let requestCallUi: () -> Void
    public let userAgent: String
    public let logDelegate: LogDelegate?
    public let notifyOnMissedCall: Bool
    public let pushKitPhoneNumberKey: String
    public let pushKitCallerNameKey: String
    public let ringtonePath: String
    
    public init(
        requestCallUi: @escaping () -> Void,
        userAgent: String = "Voip-Lib-IOS",
        logDelegate: LogDelegate? = nil,
        notifyOnMissedCall: Bool = true,
        pushKitPhoneNumberKey: String = "phonenumber",
        pushKitCallerNameKey: String = "caller_id",
        ringtonePath: String = ""
    ) {
        self.userAgent = userAgent
        self.requestCallUi = requestCallUi
        self.logDelegate = logDelegate
        self.notifyOnMissedCall = notifyOnMissedCall
        self.pushKitPhoneNumberKey = pushKitPhoneNumberKey
        self.pushKitCallerNameKey = pushKitCallerNameKey
        self.ringtonePath = ringtonePath
    }
}
