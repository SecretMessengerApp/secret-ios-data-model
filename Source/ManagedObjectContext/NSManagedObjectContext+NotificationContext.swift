//
//

import Foundation

@objc
public protocol NotificationContext : NSObjectProtocol { }

extension NSPersistentStoreCoordinator : NotificationContext {}

public extension NSManagedObjectContext {
    
    @objc
    var notificationContext : NotificationContext {
        return persistentStoreCoordinator!
    }
    
}
