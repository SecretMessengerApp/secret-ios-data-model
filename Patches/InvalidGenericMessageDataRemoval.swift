//
//

import Foundation

final class InvalidGenericMessageDataRemoval {
    static func removeInvalid(in moc: NSManagedObjectContext) {
        do {
            try moc.batchDeleteEntities(named: ZMGenericMessageData.entityName(),
                                        matching: NSPredicate(format: "\(ZMGenericMessageDataAssetKey) == nil AND \(ZMGenericMessageDataMessageKey) == nil"))
        } catch {
            fatalError("Failed to perform batch update: \(error)")
        }
    }
}
