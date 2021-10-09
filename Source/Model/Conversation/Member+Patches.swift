//
//


import Foundation


extension Member {

    // Model version 2.39.0 adds a `remoteIdentifier` attribute to the `Member` entity.
    // The value should be the same as the `remoteIdentifier` of the members user.
    static func migrateRemoteIdentifiers(in context: NSManagedObjectContext) {
        let request = NSFetchRequest<Member>(entityName: Member.entityName())
        context.fetchOrAssert(request: request).forEach(migrateUserRemoteIdentifer)
    }

    static private func migrateUserRemoteIdentifer(for member: Member) {
        member.remoteIdentifier = member.user?.remoteIdentifier
    }
    
}
