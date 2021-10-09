//
//

import Foundation

extension UserClient {
    
    /// Migrate client sessions from using the client identifier only as session identifier
    /// to new client sessions  useing user identifier + client identifier as session identifier.
    /// These have less chances of collision.
    static func migrateAllSessionsClientIdentifiers(in moc: NSManagedObjectContext) {
        guard let selfClient = ZMUser.selfUser(in: moc).selfClient() else {
            // no client? no migration needed
            return
        }
        guard let request = UserClient.sortedFetchRequest() else { return }
        let allClients = moc.executeFetchRequestOrAssert(request) as! [UserClient]
        selfClient.keysStore.encryptionContext.perform { (session) in
            for client in allClients {
                client.migrateSessionIdentifierFromV1IfNeeded(sessionDirectory: session)
            }
        }
    }
}
