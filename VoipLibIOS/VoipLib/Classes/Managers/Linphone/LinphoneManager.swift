import Foundation
import linphonesw
import AVFoundation

typealias LinphoneCall = linphonesw.Call
public typealias RegistrationCallback = (RegistrationState) -> Void
typealias LinphoneLogLevel = linphonesw.LogLevel

class LinphoneManager: linphonesw.LoggingServiceDelegate {
   
    private(set) var config: VoIPLibConfig?
    var isInitialized: Bool {
        linphoneCore != nil
    }
    
    internal var linphoneCore: Core!
    private lazy var linphoneListener = { LinphoneListener(manager: self) }()
    private lazy var registrationListener = { LinphoneRegistrationListener(manager: self) }()
    internal lazy var linphoneAudio = { LinphoneAudio(manager: self) }()
    
    var isMicrophoneMuted: Bool {
        return !linphoneCore.micEnabled
    }
    
    /**
     * We're going to store the auth object that we used to authenticate with successfully, so we
     * know we need to re-register if it has changed.
     */
    private var lastRegisteredCredentials: Auth? = nil
    
    var pil: MFLib {
        return MFLib.shared!
    }
    
    init() {
        registrationListener = LinphoneRegistrationListener(manager: self)
        linphoneListener = LinphoneListener(manager: self)
    }
    
    func initialize(config: VoIPLibConfig) -> Bool {
        self.config = config

        if isInitialized {
            log("Linphone already init")
            return true
        }

        do {
            try startLinphone()
            return true
        } catch {
            log("Failed to start Linphone \(error.localizedDescription)")
            linphoneCore = nil
            return false
        }
    }
    
    private func startLinphone() throws {
        LoggingService.Instance.logLevel = .Debug
        linphoneCore = try Factory.Instance.createCore(configPath: "", factoryConfigPath: "", systemContext: nil)
        linphoneCore.addDelegate(delegate: linphoneListener)
        // try applyPreStartConfiguration(core: linphoneCore)
        try linphoneCore.start()
        // applyPostStartConfiguration(core: linphoneCore)
        // configureCodecs(core: linphoneCore)
    }

    private func applyPreStartConfiguration(core: Core) throws {
        if let transports = core.transports {
            transports.tlsPort = 0
            transports.udpPort = 0
            transports.tcpPort = 0
        }
        core.setUserAgent(name: pil.app.userAgent, version: nil)
        core.ringback = ringbackPath        
        core.pushNotificationEnabled = true
        core.callkitEnabled = true
        core.ipv6Enabled = false
        core.dnsSrvEnabled = false
        core.dnsSearchEnabled = false
        core.maxCalls = 2
        core.uploadBandwidth = 0
        core.downloadBandwidth = 0
        core.mtu = 1300
        core.guessHostname = true
        core.incTimeout = 60
        core.audioPort = -1
        core.nortpTimeout = 30
        core.avpfMode = AVPFMode.Disabled
        core.audioJittcomp = 100
        
        if let transports = linphoneCore.transports {
            transports.tlsPort = -1
            transports.udpPort = 0
            transports.tcpPort = 0
            try linphoneCore.setTransports(newValue: transports)
        }

        try linphoneCore.setMediaencryption(newValue: MediaEncryption.SRTP)
        linphoneCore.mediaEncryptionMandatory = true
    }
    
    func applyPostStartConfiguration(core: Core) {
        core.useInfoForDtmf = true
        core.useRfc2833ForDtmf = true
        core.adaptiveRateControlEnabled = true

        if core.hasBuiltinEchoCanceller() {
            core.echoCancellationEnabled = false
            log("Built-in echo cancellation detected, disabling software.")
        } else {
            core.echoCancellationEnabled = true
            log("This device does not have built-in echo cancellation, enabled software.")
        }
    }
    
    internal var registrationCallbacks: [RegistrationCallback] = []
    
    func register(callback: @escaping RegistrationCallback) {
        do {
            guard let auth = pil.auth else {
                throw InitializationError.noConfigurationProvided
            }
            
            if lastRegisteredCredentials != auth && lastRegisteredCredentials != nil {
                log("Auth appears to have changed, unregistering old.")
                unregister()
            }

            linphoneCore.removeDelegate(delegate: self.registrationListener)
            linphoneCore.addDelegate(delegate: self.registrationListener)

            self.registrationCallbacks.append(callback)

            if (!linphoneCore.accountList.isEmpty) {
                log("We are already registered, refreshing registration.")
                linphoneCore.refreshRegisters()
                return
            }
            
            log("No valid registrations, registering for the first time.")

//            let account = try createAccount(core: linphoneCore, auth: auth)
//            try linphoneCore.addAccount(account: account)
//            try linphoneCore.addAuthInfo(info: createAuthInfo(auth: auth))
//            linphoneCore.defaultAccount = account
            initSipAccount(ext: auth.username, password: auth.password, domain: auth.domain, proxy: auth.proxy, port: auth.port.description, transportType: TransportType.Tls)
        } catch (let error) {
            log("Linphone registration failed: \(error)")
            callback(.failed)
        }
    }
    
    private func initSipAccount(ext: String, password: String, domain: String, proxy: String, port: String, transportType: TransportType) {
        do {
            let authInfo = try Factory.Instance.createAuthInfo(username: ext, userid: "", passwd: password, ha1: "", realm: "", domain: domain)
            // Account object replaces deprecated ProxyConfig object
            // Account object is configured through an AccountParams object that we can obtain from the Core
            let accountParams = try linphoneCore.createAccountParams()
            
            // A SIP account is identified by an identity address that we can construct from the username and domain
            let identity = try Factory.Instance.createAddress(addr: String("sip:" + ext + "@" + domain))
            try! accountParams.setIdentityaddress(newValue: identity)
            
            // We also need to configure where the proxy server is located
            let address = try Factory.Instance.createAddress(addr: String("sip:" + proxy + ":" + port))
            
            // We use the Address object to easily set the transport protocol
            try address.setTransport(newValue: transportType)
            try accountParams.setServeraddress(newValue: address)
            accountParams.outboundProxyEnabled = true
            // And we ensure the account will start the registration process
            accountParams.registerEnabled = true
            
            // Now that our AccountParams is configured, we can create the Account object
            let account = try linphoneCore.createAccount(params: accountParams)
            
            // Now let's add our objects to the Core
            linphoneCore.addAuthInfo(info: authInfo)
            try linphoneCore.addAccount(account: account)
            
            // Also set the newly added account as default
            linphoneCore.defaultAccount = account
        } catch {
            NSLog(error.localizedDescription)
        }
    }

    private func createAuthInfo(auth: Auth) throws -> AuthInfo {
        return try Factory.Instance.createAuthInfo(
            username: auth.username,
            userid: auth.username,
            passwd: auth.password,
            ha1: "",
            realm: "",
            domain: auth.domain
        )
    }

    private func createAccount(core: Core, auth: Auth) throws -> Account {
        let params = try core.createAccountParams()
        
        let identityUrl = "sip:\(auth.username)@\(auth.domain)"
        guard let identityAddress = core.interpretUrl(url: identityUrl) else {
            log("Unable to create account, failed to interpret identity URL: \(identityUrl)", level: .error)
            throw InitializationError.noConfigurationProvided
            }
        try params.setIdentityaddress(newValue: identityAddress)
        
        params.registerEnabled = true
        
        let serverUrl = "sip:\(auth.proxy):\(auth.port);transport=tls"
        guard let serverAddress = core.interpretUrl(url: serverUrl) else {
            log("Unable to create account, failed to interpret server URL: \(serverUrl)", level: .error)
            throw InitializationError.noConfigurationProvided
        }
        try params.setServeraddress(newValue: serverAddress)
        
        return try linphoneCore.createAccount(params: params)
    }
    
    func unregister() {
        linphoneCore.clearAccounts()
        linphoneCore.clearAllAuthInfo()
        log("Unregister complete")
    }

    func terminateAllCalls() {
        do {
           try linphoneCore.terminateAllCalls()
        } catch {
            
        }
    }
    
    func call(to number: String) -> VoIPLibCall? {
        do {
            linphoneCore.configureAudioSession()
            let domain: String? = pil.auth!.domain
            if (domain == nil) {
                NSLog("Can't create sip uri")
            }

            let sipUri = String("sip:" + number + "@" + domain!)
            let remoteAddress = try Factory.Instance.createAddress(addr: sipUri)

            // We also need a CallParams object
            // Create call params expects a Call object for incoming calls, but for outgoing we must use null safely
            let params = try linphoneCore.createCallParams(call: nil)

            // We can now configure it
            // Here we ask for no encryption but we could ask for ZRTP/SRTP/DTLS
            params.mediaEncryption = MediaEncryption.None
            let call = linphoneCore.inviteAddressWithParams(addr: remoteAddress, params: params)

            return VoIPLibCall(linphoneCall: call!)
        } catch (let error) {
            log("Transfer failed: \(error)")
            return nil
        }

    }

    
    func acceptCall(for call: VoIPLibCall) -> Bool {
        do {
            try call.linphoneCall.accept()
            return true
        } catch {
            return false
        }
    }
    
    func endCall(for call: VoIPLibCall) -> Bool {
        do {
            try call.linphoneCall.terminate()
            return true
        } catch {
            return false
        }
    }
    
    private func configureCodecs(core: Core) {
        let codecs = [Codec.PCMU]
        
        linphoneCore?.videoPayloadTypes.forEach { payload in
            _ = payload.enable(enabled: false)
        }
        
        linphoneCore?.audioPayloadTypes.forEach { payload in
            let enable = !codecs.filter { selectedCodec in
                selectedCodec.rawValue.uppercased() == payload.mimeType.uppercased()
            }.isEmpty
            
            _ = payload.enable(enabled: enable)
        }
        
        guard let enabled = linphoneCore?.audioPayloadTypes.filter({ payload in payload.enabled() }).map({ payload in payload.mimeType }).joined(separator: ", ") else {
            log("Unable to log codecs, no core")
            return
        }
        
        log("Enabled codecs: \(enabled)")
    }

    
    func setMicrophone(muted: Bool) {
        linphoneCore.micEnabled = !muted
    }
    
    func setAudio(enabled:Bool) {
        log("Linphone set audio: \(enabled)")
        linphoneCore.activateAudioSession(actived: enabled)
    }
    
    func setHold(call: VoIPLibCall, onHold hold:Bool) -> Bool {
        do {
            if hold {
                log("Pausing VoIPLibCall.")
                try call.pause()
            } else {
                log("Resuming VoIPLibCall.")
                try call.resume()
            }
            return true
        } catch {
            return false
        }
    }
    
    func transfer(call: VoIPLibCall, to number: String) -> Bool {
        do {
            try call.linphoneCall.transferTo(referTo: linphoneCore.createAddress(address: number))
            log("Transfer was successful")
            return true
        } catch (let error) {
            log("Transfer failed: \(error)")
            return false
        }
    }
    
    func beginAttendedTransfer(call: VoIPLibCall, to number:String) -> AttendedTransferSession? {
        guard let destinationVoIPLibCall = self.call(to: number) else {
            log("Unable to make VoIPLibCall for target VoIPLibCall")
            return nil
        }
        
        return AttendedTransferSession(from: call, to: destinationVoIPLibCall)
    }
    
    func finishAttendedTransfer(attendedTransferSession: AttendedTransferSession) -> Bool {
        do {
            try attendedTransferSession.from.linphoneCall.transferToAnother(dest: attendedTransferSession.to.linphoneCall)
            log("Transfer was successful")
            return true
        } catch (let error) {
            log("Transfer failed: \(error)")
            return false
        }
    }
    
    func sendDtmf(call: VoIPLibCall, dtmf: String) {
        do {
            try call.linphoneCall.sendDtmfs(dtmfs: dtmf)
        } catch (let error) {
            log("Sending dtmf failed: \(error)")
            return
        }
    }
    
    func provideCallInfo(call: VoIPLibCall) -> String {
        return CallInfoProvider(VoIPLibCall: call).provide()
    }
    
    func onLogMessageWritten(logService: LoggingService, domain: String, level: LogLevel, message: String) {
        config?.logListener(message)
    }
    
    internal func refreshRegistration() {
        linphoneCore.refreshRegisters()
    }
    
    private var ringbackPath: String {
        Bundle.main.path(forResource: "ringback", ofType: "wav") ?? ""
    }
}
