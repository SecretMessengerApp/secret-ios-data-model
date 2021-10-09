//
//

import Foundation

@objc extension NSManagedObjectContext {
    
    /// Will merge all relevant user info data from another context (e.g. sync to UI, or UI to sync)
    public func mergeUserInfo(fromUserInfo userInfo: [String: Any]) {
        self.mergeSecurityLevelDegradationInfo(fromUserInfo: userInfo)
        self.mergeCallStateChanges(fromUserInfo: userInfo)
    }
}
