//
//


import Foundation

private let analyticsUserInfoKey = "AnalyticsUserInfoKey"

public extension NSManagedObjectContext {

    /// Set when initializing the user session from the UI, used for easier tracking on SE
    @objc var analytics: AnalyticsType? {
        get {
            guard !zm_isUserInterfaceContext else { preconditionFailure("Analytics can only be accessed on sync context") }
            return userInfo[analyticsUserInfoKey] as? AnalyticsType
        }

        set {
            guard !zm_isUserInterfaceContext else { preconditionFailure("Analytics can only be accessed on sync context") }
            userInfo[analyticsUserInfoKey] = newValue
        }
    }
}
