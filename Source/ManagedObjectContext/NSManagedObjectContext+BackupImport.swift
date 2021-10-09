//
//

import Foundation

extension NSManagedObjectContext {
    
    /// Prepare a backed up database for being imported, deleting self client, push token etc.
    func prepareToImportBackup() {
        require(!self.zm_isUserInterfaceContext, "can't to be run on ui Context to avoid race conditions")
        setPersistentStoreMetadata(nil as Data?, key: ZMPersistedClientIdKey)
        setPersistentStoreMetadata(nil as Data?, key: PersistentMetadataKey.importedFromBackup.rawValue)
        setPersistentStoreMetadata(nil as Data?, key: PersistentMetadataKey.pushToken.rawValue)
        setPersistentStoreMetadata(nil as Data?, key: PersistentMetadataKey.pushKitToken.rawValue)
        setPersistentStoreMetadata(nil as Data?, key: PersistentMetadataKey.lastUpdateEventID.rawValue)
        self.zm_lastHugeNotificationID = nil
        self.zm_lastNotificationID = nil
        saveOrRollback()
    }
    
}
