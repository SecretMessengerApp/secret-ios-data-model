//
//

import Foundation

public extension NSManagedObjectContext {
    
    private static let ServerTimeDeltaKey = "ServerTimeDeltaKey"
    
    @objc
    var serverTimeDelta : TimeInterval {
        
        get {
            precondition(!zm_isUserInterfaceContext, "serverTimeDelta can only be accessed on the sync context")
            return userInfo[NSManagedObjectContext.ServerTimeDeltaKey] as? TimeInterval ?? 0
        }
        
        set {
            precondition(!zm_isUserInterfaceContext, "serverTimeDelta can only be accessed on the sync context")
            userInfo[NSManagedObjectContext.ServerTimeDeltaKey] = newValue
        }
        
    }
        
}

