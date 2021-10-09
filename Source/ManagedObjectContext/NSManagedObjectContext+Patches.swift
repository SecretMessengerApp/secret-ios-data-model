//
//

import Foundation

extension NSManagedObjectContext {
    
    /// Applies the required patches for the current version of the persisted data
    public func applyPersistedDataPatchesForCurrentVersion() {
        PersistedDataPatch.applyAll(in: self)
    }
}


extension NSManagedObjectContext {
    public func batchDeleteEntities(named entityName: String, matching predicate: NSPredicate) throws {
        // will skip this during test unless on disk
        guard self.persistentStoreCoordinator!.persistentStores.first!.type != NSInMemoryStoreType else { return }
        
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetch.predicate = predicate
        let request = NSBatchDeleteRequest(fetchRequest: fetch)
        request.resultType = .resultTypeObjectIDs
        let result = try self.execute(request) as? NSBatchDeleteResult
        let objectIDArray = result?.result ?? []
        let changes = [NSDeletedObjectsKey : objectIDArray]
        // Deletion happens on persistance layer, we need to notify contexts of the changes manually
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self])
    }
}
