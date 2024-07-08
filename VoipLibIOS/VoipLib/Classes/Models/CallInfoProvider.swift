import Foundation
import linphonesw

class CallInfoProvider {
    
    let VoIPLibCall: VoIPLibCall
    
    init(VoIPLibCall: VoIPLibCall){
        self.VoIPLibCall = VoIPLibCall
    }
    
    func provide() -> String {
        let audio = provideAudioInfo()
        let advancedSettings = provideAdvancedSettings()
        let toAddressInfo = provideToAddressInfo()
        let remoteParams = provideRemoteParams()
        let params = provideParams()
        let VoIPLibCallProperties = provideVoIPLibCallProperties()
        let errorInfo = provideErrorInfo()
        
        let VoIPLibCallInfo: [String: Any] = [
            "Audio": audio.map{"  \($0): \($1)"}.sorted().joined(separator: "\n"),
            "Advanced Settings": advancedSettings.map{"  \($0): \($1)"}.sorted().joined(separator: "\n"),
            "To Address": toAddressInfo.map{"  \($0): \($1)"}.sorted().joined(separator: "\n"),
            "Remote Params": remoteParams.map{"  \($0): \($1)"}.sorted().joined(separator: "\n"),
            "Params": params.map{"  \($0): \($1)"}.sorted().joined(separator: "\n"),
            "VoIPLibCall": VoIPLibCallProperties.map{"  \($0): \($1)"}.sorted().joined(separator: "\n"),
            "Error": errorInfo.map{"  \($0): \($1)"}.sorted().joined(separator: "\n")
        ]
        
        return VoIPLibCallInfo.map{"\($0)\n\($1)\n"}.sorted().joined(separator: "\n")
    }
    
    private func provideAudioInfo() -> [String:Any] {
        guard let codec = VoIPLibCall.mifoneCall.currentParams?.usedAudioPayloadType?.description,
        let codecChannels = VoIPLibCall.mifoneCall.currentParams?.usedAudioPayloadType?.channels,
        let downloadBandwidth = VoIPLibCall.mifoneCall.getStats(type: .Audio)?.downloadBandwidth,
        let estimatedDownloadBandwidth = VoIPLibCall.mifoneCall.getStats(type: .Audio)?.estimatedDownloadBandwidth,
        let jitterBufferSizeMs = VoIPLibCall.mifoneCall.getStats(type: .Audio)?.jitterBufferSizeMs,
              let loVoIPLibCallateRate = VoIPLibCall.mifoneCall.getStats(type: .Audio)?.localLateRate,
        let loVoIPLibCallossRate = VoIPLibCall.mifoneCall.getStats(type: .Audio)?.localLossRate,
        let receiverInterarrivalJitter = VoIPLibCall.mifoneCall.getStats(type: .Audio)?.receiverInterarrivalJitter,
        let receiverLossRate = VoIPLibCall.mifoneCall.getStats(type: .Audio)?.receiverLossRate,
        let roundTripDelay = VoIPLibCall.mifoneCall.getStats(type: .Audio)?.roundTripDelay,
        let rtcpDownloadBandwidth = VoIPLibCall.mifoneCall.getStats(type: .Audio)?.rtcpDownloadBandwidth,
        let rtcpUploadBandwidth = VoIPLibCall.mifoneCall.getStats(type: .Audio)?.rtcpUploadBandwidth,
        let senderInterarrivalJitter = VoIPLibCall.mifoneCall.getStats(type: .Audio)?.senderInterarrivalJitter,
        let senderLossRate = VoIPLibCall.mifoneCall.getStats(type: .Audio)?.senderLossRate,
        let iceState = VoIPLibCall.mifoneCall.getStats(type: .Audio)?.iceState,
        let uploadBandwidth = VoIPLibCall.mifoneCall.getStats(type: .Audio)?.uploadBandwidth else {return ["":""]}
        
        let audio: [String:Any] = [
            "codec": codec,
            "codecChannels": codecChannels,
            "downloadBandwidth": downloadBandwidth,
            "estimatedDownloadBandwidth": estimatedDownloadBandwidth,
            "jitterBufferSizeMs": jitterBufferSizeMs,
            "loVoIPLibCallateRate": loVoIPLibCallateRate,
            "loVoIPLibCallossRate": loVoIPLibCallossRate,
            "receiverInterarrivalJitter": receiverInterarrivalJitter,
            "receiverLossRate": receiverLossRate,
            "roundTripDelay": roundTripDelay,
            "rtcpDownloadBandwidth": rtcpDownloadBandwidth,
            "rtcpUploadBandwidth": rtcpUploadBandwidth,
            "senderInterarrivalJitter": senderInterarrivalJitter,
            "senderLossRate": senderLossRate,
            "iceState": iceState,
            "uploadBandwidth": uploadBandwidth
        ]
        
        return audio
    }
        
    private func provideAdvancedSettings() -> [String:Any] {
        guard let mtu = VoIPLibCall.mifoneCall.core?.mtu,
        let echoCancellationEnabled = VoIPLibCall.mifoneCall.core?.echoCancellationEnabled,
        let adaptiveRateControlEnabled = VoIPLibCall.mifoneCall.core?.adaptiveRateControlEnabled,
        let audioAdaptiveJittcompEnabled = VoIPLibCall.mifoneCall.core?.audioAdaptiveJittcompEnabled,
        let rtpBundleEnabled = VoIPLibCall.mifoneCall.core?.rtpBundleEnabled,
        let adaptiveRateAlgorithm = VoIPLibCall.mifoneCall.core?.adaptiveRateAlgorithm else {return ["":""]}
        
        let advancedSettings: [String:Any] = [
            "mtu": mtu,
            "echoCancellationEnabled": echoCancellationEnabled,
            "adaptiveRateControlEnabled": adaptiveRateControlEnabled,
            "audioAdaptiveJittcompEnabled": audioAdaptiveJittcompEnabled,
            "rtpBundleEnabled": rtpBundleEnabled,
            "adaptiveRateAlgorithm": adaptiveRateAlgorithm
        ]
        
        return advancedSettings
    }
    
    private func provideToAddressInfo() -> [String:Any] {
        guard let transport = VoIPLibCall.mifoneCall.toAddress?.transport,
              let domain = VoIPLibCall.mifoneCall.toAddress?.domain else {return ["":""]}
        
        let toAddressInfo: [String:Any] = [
            "transport": transport,
            "domain": domain,
        ]
        
        return toAddressInfo
    }
    
    private func provideRemoteParams() -> [String:Any] {
        guard let remoteEncryption = VoIPLibCall.mifoneCall.remoteParams?.mediaEncryption,
              let remoteSessionName = VoIPLibCall.mifoneCall.remoteParams?.sessionName,
              let remotePartyId = VoIPLibCall.mifoneCall.remoteParams?.getCustomHeader(headerName: "Remote-Party-ID"),
              let pAssertedIdentity = VoIPLibCall.mifoneCall.remoteParams?.getCustomHeader(headerName: "P-Asserted-Identity") else {return ["":""]}
        
        let remoteParams: [String:Any] = [
            "encryption": remoteEncryption,
            "sessionName": remoteSessionName,
            "remotePartyId": remotePartyId,
            "pAssertedIdentity": pAssertedIdentity,
        ]
        
        return remoteParams
    }
    
    private func provideParams() -> [String:Any] {
        guard let encryption = VoIPLibCall.mifoneCall.params?.mediaEncryption,
              let sessionName = VoIPLibCall.mifoneCall.params?.sessionName else {return ["":""]}
        
        let params: [String:Any] = [
            "encryption": encryption,
            "sessionName": sessionName
        ]
        
        return params
    }

    private func provideVoIPLibCallProperties() -> [String:Any] {
        let reason = VoIPLibCall.mifoneCall.reason
        let duration = VoIPLibCall.mifoneCall.duration
        
        guard let VoIPLibCallId = VoIPLibCall.mifoneCall.callLog?.callId,
              let refKey = VoIPLibCall.mifoneCall.callLog?.refKey,
              let status = VoIPLibCall.mifoneCall.callLog?.status,
              let direction = VoIPLibCall.mifoneCall.callLog?.dir,
              let quality = VoIPLibCall.mifoneCall.callLog?.quality,
              let startDate = VoIPLibCall.mifoneCall.callLog?.startDate
        else { return ["reason": reason, "duration": duration]}
        
        let VoIPLibCallProperties: [String:Any] = [
            "VoIPLibCallId": VoIPLibCallId,
            "refKey": refKey,
            "status": status,
            "direction": direction,
            "quality": quality,
            "startDate": startDate,
            "reason": reason,
            "duration": duration
        ]
        
        return VoIPLibCallProperties
    }
    
    private func provideErrorInfo() -> [String:Any] {
        guard let phrase = VoIPLibCall.mifoneCall.errorInfo?.phrase,
            let errorProtocol = VoIPLibCall.mifoneCall.errorInfo?.proto,
            let errorReason = VoIPLibCall.mifoneCall.errorInfo?.reason,
            let protocolCode = VoIPLibCall.mifoneCall.errorInfo?.protocolCode else {return ["":""]}
        
        let errorInfo: [String:Any] = [
            "phrase": phrase,
            "protocol": errorProtocol,
            "reason": errorReason,
            "protocolCode": protocolCode
        ]
        
        return errorInfo
    }
}
