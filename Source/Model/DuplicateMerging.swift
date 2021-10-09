//
//

import Foundation

protocol DuplicateMerging {
    associatedtype T: ZMManagedObject
    static func remoteIdentifierDataKey() -> String?
    static func merge(_ items: [T]) -> T?
}

extension DuplicateMerging {
    static func fetchAndMergeDuplicates(with remoteIdentifier: UUID, in moc: NSManagedObjectContext) -> T? {
        let result = fetchAll(with: remoteIdentifier, in: moc)
        let merged = merge(result)
        return merged
    }

    static func fetchAll(with remoteIdentifier: UUID, in moc: NSManagedObjectContext) -> [T] {
        let fetchRequest = NSFetchRequest<T>(entityName: T.entityName())
        let data = (remoteIdentifier as NSUUID).data() as NSData
        fetchRequest.predicate = NSPredicate(format: "%K = %@", remoteIdentifierDataKey()!, data)
        let result = moc.fetchOrAssert(request: fetchRequest)
        return result
    }
}

extension ZMUser: DuplicateMerging {}
