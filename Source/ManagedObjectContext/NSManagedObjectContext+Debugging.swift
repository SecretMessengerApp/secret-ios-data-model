//
//

import Foundation

private let errorOnSaveCallbackKey = "zm_errorOnSaveCallback"

extension NSManagedObjectContext {
    
    public typealias ErrorOnSaveCallback = (NSManagedObjectContext, NSError)->()
    
    // Callback invoked when an error is generated during save
    public var errorOnSaveCallback : ErrorOnSaveCallback? {
        get {
            return self.userInfo[errorOnSaveCallbackKey] as? ErrorOnSaveCallback
        }
        set {
            self.userInfo[errorOnSaveCallbackKey] = newValue
        }
    }
    
    /// Report an error during save
    @objc public func reportSaveError(error: NSError) {
        if let callback = self.errorOnSaveCallback {
            callback(self, error)
        }
    }
}
