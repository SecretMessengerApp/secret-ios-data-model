//
//

import Foundation

enum InvalidClientsRemoval {

    /// We had a situation where after merging duplicate users we were not disposing user clients
    /// and this lead to UserClient -> User relationship to be nil. This
    static func removeInvalid(in moc: NSManagedObjectContext) {
        // will skip this during test unless on disk
        do {
            try moc.batchDeleteEntities(named: UserClient.entityName(), matching: NSPredicate(format: "\(ZMUserClientUserKey) == nil"))
        } catch {
            fatalError("Failed to perform batch update: \(error)")
        }
    }
}

