import Foundation

public class CallSessionState {
    
    public var activeCall: Call?
    public var inactiveCall: Call?
    public var audioState: AudioState
    
    init(activeCall: Call?, inactiveCall: Call?, audioState: AudioState){
        self.activeCall = activeCall
        self.inactiveCall = inactiveCall
        self.audioState = audioState
    }
}
