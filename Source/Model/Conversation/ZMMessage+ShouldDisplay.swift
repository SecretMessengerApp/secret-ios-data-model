//
//

import Foundation

@objc extension ZMMessage {
  
    var shouldBeDisplayed: Bool {
        return !hasBeenDeleted && !isZombieObject
    }
    
}
