//
// Created by Hieu James on 18/02/2024.
//

import Foundation

public typealias LogListener = (String) -> Void

struct VoIPLibConfig {
    init(callDelegate: VoIPLibCallDelegate, logListener: @escaping LogListener) {
        self.callDelegate = callDelegate
        self.logListener = logListener
    }
    
    let callDelegate: VoIPLibCallDelegate
    let logListener: LogListener
}
