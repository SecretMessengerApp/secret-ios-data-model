//
//


public extension ZMUser {

    @objc static func fetchAndMerge(with remoteIdentifier: UUID, createIfNeeded: Bool, in context: NSManagedObjectContext) -> ZMUser? {
        // We must only ever call this on the sync context. Otherwise, there's a race condition
        // where the UI and sync contexts could both insert the same user (same UUID) and we'd end up
        // having two duplicates of that user, and we'd have a really hard time recovering from that.
        //
        assert(!createIfNeeded || !context.zm_isUserInterfaceContext, "Race condition!")
        if let result = fetchAndMergeDuplicates(with: remoteIdentifier, in: context) {
            return result
        } else if(createIfNeeded) {
            let user = ZMUser.insertNewObject(in: context)
            user.remoteIdentifier = remoteIdentifier
            return user
        } else {
            return nil
        }
    }
}
