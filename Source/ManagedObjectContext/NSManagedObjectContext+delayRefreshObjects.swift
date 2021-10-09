

import Foundation

extension NSManagedObjectContext {
    
    static let RefreshObjectsTimeStampKey = "RefreshObjectsTimeStampKey"
    
    static let INTERVAl_MINUTE: Double = 3 * 60
    
    @objc
    public var shouldRefreshObjects: Bool {
        if let lastRefreshDate = self.refreshObjectsTimeStamp {
            let seconds = NSDate().timeIntervalSince(lastRefreshDate)
            if seconds > NSManagedObjectContext.INTERVAl_MINUTE {
                resetRefreshObjectsTimeStamp()
                return true
            }
            return false
        }
        resetRefreshObjectsTimeStamp()
        return true
    }
    
    var refreshObjectsTimeStamp: Date? {
        set {
            guard let date = newValue else {return}
            self.setPersistentStoreMetadata(date, key: NSManagedObjectContext.RefreshObjectsTimeStampKey)
        }
        get {
            if let date = self.persistentStoreMetadata(forKey: NSManagedObjectContext.RefreshObjectsTimeStampKey) as? Date {
                return date
            }
            return nil
        }
    }
    
    private func resetRefreshObjectsTimeStamp() {
        self.refreshObjectsTimeStamp = Date()
        self.saveOrRollback()
    }
    
}
