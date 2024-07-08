import Foundation
import linphonesw
import AVFoundation

typealias MiFoneCall = linphonesw.Call
public typealias RegistrationCallback = (RegistrationState) -> Void
typealias MiFoneLogLevel = linphonesw.LogLevel

class MiFoneManager: linphonesw.LoggingServiceDelegate {
   
    private(set) var config: VoIPLibConfig?
    var isInitialized: Bool {
        mifoneCore != nil
    }
    
    internal var mifoneCore: Core!
    private lazy var mifoneListener = { MiFoneListener(manager: self) }()
    private lazy var registrationListener = { MiFoneRegistrationListener(manager: self) }()
    internal lazy var mifoneAudio = { MiFoneAudio(manager: self) }()
    
    var isMicrophoneMuted: Bool {
        return !mifoneCore.micEnabled
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
        registrationListener = MiFoneRegistrationListener(manager: self)
        mifoneListener = MiFoneListener(manager: self)
    }
    
    func initialize(config: VoIPLibConfig) -> Bool {
        self.config = config

        if isInitialized {
            log("MiFone already init")
            return true
        }

        do {
            try startMF()
            return true
        } catch {
            log("Failed to start MiFone \(error.localizedDescription)")
            mifoneCore = nil
            return false
        }
    }
    
    private func startMF() throws {
        LoggingService.Instance.logLevel = .Debug
        mifoneCore = try Factory.Instance.createCore(configPath: "", factoryConfigPath: "", systemContext: nil)
        mifoneCore.addDelegate(delegate: mifoneListener)
        try mifoneCore.start()

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
        
        if let transports = mifoneCore.transports {
            transports.tlsPort = -1
            transports.udpPort = 0
            transports.tcpPort = 0
            try mifoneCore.setTransports(newValue: transports)
        }

        try mifoneCore.setMediaencryption(newValue: MediaEncryption.SRTP)
        mifoneCore.mediaEncryptionMandatory = true
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

            mifoneCore.removeDelegate(delegate: self.registrationListener)
            mifoneCore.addDelegate(delegate: self.registrationListener)

            self.registrationCallbacks.append(callback)

            if (!mifoneCore.accountList.isEmpty) {
                log("We are already registered, refreshing registration.")
                mifoneCore.refreshRegisters()
                return
            }
            
            log("No valid registrations, registering for the first time.")
            
            initSipAccount(ext: auth.username, password: auth.password, domain: auth.domain, proxy: auth.proxy, port: auth.port.description, transportType: auth.transport)


        } catch (let error) {
            log("MiFone registration failed: \(error)")
            callback(.failed)
        }
    }
    
    private func initSipAccount(ext: String, password: String, domain: String, proxy: String, port: String, transportType: String) {
        do {
            let authInfo = try Factory.Instance.createAuthInfo(username: ext, userid: "", passwd: password, ha1: "", realm: "", domain: domain)
            // Account object replaces deprecated ProxyConfig object
            // Account object is configured through an AccountParams object that we can obtain from the Core
            let accountParams = try mifoneCore.createAccountParams()
            
            // A SIP account is identified by an identity address that we can construct from the username and domain
            let identity = try Factory.Instance.createAddress(addr: String("sip:" + ext + "@" + domain))
            try! accountParams.setIdentityaddress(newValue: identity)
            
            // We also need to configure where the proxy server is located
            let address = try Factory.Instance.createAddress(addr: String("sip:" + proxy + ":" + port))
            if(transportType == "tls"){
                try address.setTransport(newValue: TransportType.Tls)
            }else if (transportType == "tcp"){
                try address.setTransport(newValue: TransportType.Udp)
            }else {
                try address.setTransport(newValue: TransportType.Tcp)
            }
            try accountParams.setServeraddress(newValue: address)
            accountParams.outboundProxyEnabled = true
            accountParams.registerEnabled = true
            
            // Now that our AccountParams is configured, we can create the Account object
            let account = try mifoneCore.createAccount(params: accountParams)
            
            // Now let's add our objects to the Core
            mifoneCore.addAuthInfo(info: authInfo)
            try mifoneCore.addAccount(account: account)
            
            // Also set the newly added account as default
            mifoneCore.defaultAccount = account
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
                
        let identityUrl = "sip:\(auth.username)@\(auth.domain):\(auth.port)"
        guard let identityAddress = core.interpretUrl(url: identityUrl, applyInternationalPrefix: false) else {
            log("Unable to create account, failed to interpret identity URL: \(identityUrl)", level: .error)
            throw InitializationError.noConfigurationProvided
            }
        try params.setIdentityaddress(newValue: identityAddress)
        
        params.registerEnabled = true
        
        let serverUrl = "sip:\(auth.domain);transport=tls"
        guard let serverAddress = core.interpretUrl(url: serverUrl, applyInternationalPrefix: false) else {
            log("Unable to create account, failed to interpret server URL: \(serverUrl)", level: .error)
            throw InitializationError.noConfigurationProvided
        }
        try params.setServeraddress(newValue: serverAddress)
        
        return try mifoneCore.createAccount(params: params)
    }
    
    func unregister() {
        mifoneCore.clearAccounts()
        mifoneCore.clearAllAuthInfo()
        log("Unregister complete")
    }

    func terminateAllCalls() {
        do {
           try mifoneCore.terminateAllCalls()
        } catch {
            
        }
    }
    
    func call(to number: String) -> VoIPLibCall? {
        do {
            print("MAKE CALL OUT:   \(number)")
            mifoneCore.configureAudioSession()
            let domain: String? = pil.auth!.domain
            if (domain == nil) {
                NSLog("Can't create sip uri")
            }

            let sipUri = String("sip:" + number + "@" + domain!)
            let remoteAddress = try Factory.Instance.createAddress(addr: sipUri)

            // We also need a CallParams object
            // Create call params expects a Call object for incoming calls, but for outgoing we must use null safely
            let params = try mifoneCore.createCallParams(call: nil)

            // We can now configure it
            // Here we ask for no encryption but we could ask for ZRTP/SRTP/DTLS
            params.mediaEncryption = MediaEncryption.None
            let call = mifoneCore.inviteAddressWithParams(addr: remoteAddress, params: params)

            return VoIPLibCall(mifoneCall: call!)
        } catch (let error) {
            log("Transfer failed: \(error)")
            return nil
        }

    }

    
    func acceptCall(for call: VoIPLibCall) -> Bool {
        do {
            try call.mifoneCall.accept()
            return true
        } catch {
            return false
        }
    }
    
    func endCall(for call: VoIPLibCall) -> Bool {
        do {
            try call.mifoneCall.terminate()
            return true
        } catch {
            return false
        }
    }
    
    private func configureCodecs(core: Core) {
        let codecs = [Codec.PCMU]
        
        mifoneCore?.videoPayloadTypes.forEach { payload in
            _ = payload.enable(enabled: false)
        }
        
        mifoneCore?.audioPayloadTypes.forEach { payload in
            let enable = !codecs.filter { selectedCodec in
                selectedCodec.rawValue.uppercased() == payload.mimeType.uppercased()
            }.isEmpty
            
            _ = payload.enable(enabled: enable)
        }
        
        guard let enabled = mifoneCore?.audioPayloadTypes.filter({ payload in payload.enabled() }).map({ payload in payload.mimeType }).joined(separator: ", ") else {
            log("Unable to log codecs, no core")
            return
        }
        
        log("Enabled codecs: \(enabled)")
    }

    
    func setMicrophone(muted: Bool) {
        mifoneCore.micEnabled = !muted
    }
    
    func setAudio(enabled:Bool) {
        log("MiFone set audio: \(enabled)")
        mifoneCore.activateAudioSession(actived: enabled)
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
            try call.mifoneCall.transferTo(referTo: mifoneCore.createAddress(address: number))
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
            try attendedTransferSession.from.mifoneCall.transferToAnother(dest: attendedTransferSession.to.mifoneCall)
            log("Transfer was successful")
            return true
        } catch (let error) {
            log("Transfer failed: \(error)")
            return false
        }
    }
    
    func sendDtmf(call: VoIPLibCall, dtmf: String) {
        do {
            try call.mifoneCall.sendDtmfs(dtmfs: dtmf)
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
        mifoneCore.refreshRegisters()
    }
    
    private var ringbackPath: String {
        Bundle.main.path(forResource: "ringback", ofType: "wav") ?? ""
    }
}
