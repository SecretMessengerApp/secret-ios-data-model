//
//

import XCTest
import WireTesting
@testable import WireDataModel

class InvalidClientsRemovalTests: DiskDatabaseTest {

    func testThatItDoesNotRemoveValidClients() throws {
        // Given
        let user = ZMUser.insertNewObject(in: self.moc)
        let client = UserClient.insertNewObject(in: self.moc)
        client.user = user
        try self.moc.save()

        // When
        WireDataModel.InvalidClientsRemoval.removeInvalid(in: self.moc)

        // Then
        XCTAssertFalse(client.isDeleted)
        XCTAssertFalse(client.isZombieObject)
    }

    func testThatItDoesRemoveInvalidClient() throws {
        // Given
        let user = ZMUser.insertNewObject(in: self.moc)
        let client = UserClient.insertNewObject(in: self.moc)
        client.user = user
        let otherClient = UserClient.insertNewObject(in: self.moc)
        try self.moc.save()

        // When
        WireDataModel.InvalidClientsRemoval.removeInvalid(in: self.moc)

        // Then
        XCTAssertFalse(client.isDeleted)
        XCTAssertFalse(client.isZombieObject)
        XCTAssertTrue(otherClient.isDeleted)
        XCTAssertTrue(otherClient.isZombieObject)
    }

    func createSelfClient(in moc: NSManagedObjectContext) -> UserClient {
        let selfUser = ZMUser.selfUser(in: moc)
        if selfUser.remoteIdentifier == nil {
            selfUser.remoteIdentifier = .create()
        }
        let selfClient = UserClient.insertNewObject(in: moc)
        selfClient.remoteIdentifier = UUID.create().uuidString
        selfClient.user = selfUser
        moc.setPersistentStoreMetadata(selfClient.remoteIdentifier, key: ZMPersistedClientIdKey)
        moc.saveOrRollback()
        return selfClient
    }

    func testThatItDoesNotDeleteSessionWhenDeletingInvalidClient() {
        let syncMOC = contextDirectory.syncContext!
        syncMOC.performGroupedBlockAndWait {
            // given
            let selfClient = self.createSelfClient(in: syncMOC)
            var preKeys : [(id: UInt16, prekey: String)] = []
            selfClient.keysStore.encryptionContext.perform {
                preKeys = try! $0.generatePrekeys(0 ..< 2)
            }

            let otherClient = UserClient.insertNewObject(in: syncMOC)
            otherClient.remoteIdentifier = UUID.create().transportString()
            let otherUser = ZMUser.insertNewObject(in:syncMOC)
            otherUser.remoteIdentifier = UUID.create()
            otherClient.user = otherUser

            let duplicateClient = UserClient.insertNewObject(in: syncMOC)
            duplicateClient.remoteIdentifier = otherClient.remoteIdentifier
            duplicateClient.user = nil

            guard let preKey = preKeys.first else { XCTFail("could not generate prekeys"); return }

            XCTAssertTrue(selfClient.establishSessionWithClient(otherClient, usingPreKey:preKey.prekey))
            XCTAssertTrue(otherClient.hasSessionWithSelfClient)
            let clientId = otherClient.sessionIdentifier!
            syncMOC.saveOrRollback()
            
            // when
            WireDataModel.InvalidClientsRemoval.removeInvalid(in: syncMOC)


            // then
            selfClient.keysStore.encryptionContext.perform {
                XCTAssertTrue($0.hasSession(for: clientId))
            }
            XCTAssertTrue(otherClient.hasSessionWithSelfClient)
            XCTAssertFalse(otherClient.isZombieObject)
            XCTAssertTrue(duplicateClient.isZombieObject)
        }
    }

}
