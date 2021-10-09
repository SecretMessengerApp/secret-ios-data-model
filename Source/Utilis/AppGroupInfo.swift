

import Foundation

@objcMembers public class AppGroupInfo: NSObject {
    
    public static let appGroupIdentifier = Bundle.main.infoDictionary?["ApplicationGroupIdentifier"] as! String
    
    public static let instance: AppGroupInfo = AppGroupInfo()
    
    public var sharedUserDefaults: UserDefaults {
        return UserDefaults(suiteName: AppGroupInfo.appGroupIdentifier)!
    }
    
    
}
