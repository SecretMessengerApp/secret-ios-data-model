//
// 


import XCTest
import WireUtilities
import WireCryptobox
@testable import WireDataModel

class UserClientTests: ZMBaseManagedObjectTest {
        
    func clientWithTrustedClientCount(_ trustedCount: UInt, ignoredClientCount: UInt, missedClientCount: UInt) -> UserClient
    {
        let client = UserClient.insertNewObject(in: self.uiMOC)
        
        func userClientSetWithClientCount(_ count :UInt) -> Set<UserClient>?
        {
            guard count != 0 else { return nil }
            
            var clients = Set<UserClient>()
            for _ in 0..<count {
                clients.insert(UserClient.insertNewObject(in: uiMOC))
            }
            return clients
        }
        
        let trustedClient = userClientSetWithClientCount(trustedCount)
        let ignoredClient = userClientSetWithClientCount(ignoredClientCount)
        let missedClient = userClientSetWithClientCount(missedClientCount)
        
        if let trustedClient = trustedClient { client.trustedClients = trustedClient }
        if let ignoredClient = ignoredClient { client.ignoredClients = ignoredClient }
        client.missingClients = missedClient
        
        return client
    }

    func testThatItCanInitializeClient() {
        let client = UserClient.insertNewObject(in: self.uiMOC)
        XCTAssertEqual(client.type, .permanent, "Client type should be 'permanent'")
    }
    
    func testThatItReturnsTrackedKeys() {
        let client = UserClient.insertNewObject(in: self.uiMOC)
        let trackedKeys = client.keysTrackedForLocalModifications()
        XCTAssertTrue(trackedKeys.contains(ZMUserClientMarkedToDeleteKey), "")
        XCTAssertTrue(trackedKeys.contains(ZMUserClientNumberOfKeysRemainingKey), "")
    }
    
    func testThatItSyncClientsWithNoRemoteIdentifier() {
        let unsyncedClient = UserClient.insertNewObject(in: self.uiMOC)
        let syncedClient = UserClient.insertNewObject(in: self.uiMOC)
        syncedClient.remoteIdentifier = "synced"
        
        XCTAssertTrue(UserClient.predicateForObjectsThatNeedToBeInsertedUpstream().evaluate(with: unsyncedClient))
        XCTAssertFalse(UserClient.predicateForObjectsThatNeedToBeInsertedUpstream().evaluate(with: syncedClient))
    }
    
    func testThatClientCanBeMarkedForDeletion() {
        let client = UserClient.insertNewObject(in: self.uiMOC)
        client.user = ZMUser.selfUser(in: self.uiMOC)
        
        XCTAssertFalse(client.markedToDelete)
        client.markForDeletion()
        
        XCTAssertTrue(client.markedToDelete)
        XCTAssertTrue(client.hasLocalModifications(forKey: ZMUserClientMarkedToDeleteKey))
    }
    
    func testThatItTracksCorrectKeys() {
        let expectedKeys = Set(arrayLiteral: ZMUserClientMarkedToDeleteKey, ZMUserClientNumberOfKeysRemainingKey, ZMUserClientMissingKey, ZMUserClientNeedsToUpdateSignalingKeysKey, "pushToken")
        let client = UserClient.insertNewObject(in: self.uiMOC)

        XCTAssertEqual(client.keysTrackedForLocalModifications() , expectedKeys)
    }
    
    func testThatTrustingClientsRemovesThemFromIgnoredClientList() {
        
        let client = clientWithTrustedClientCount(0, ignoredClientCount:2, missedClientCount:0)
        
        let ignoredClient = client.ignoredClients.first!
        
        client.trustClients(Set(arrayLiteral: ignoredClient))
        
        XCTAssertFalse(client.ignoredClients.contains(ignoredClient))
        XCTAssertTrue(client.trustedClients.contains(ignoredClient))
    }
    
    func testThatIgnoringClientsRemovesThemFromTrustedList() {
        
        let client = clientWithTrustedClientCount(2, ignoredClientCount:1, missedClientCount:0)
        
        let trustedClient = client.trustedClients.first!
        
        client.ignoreClients(Set(arrayLiteral: trustedClient))
        
        XCTAssertFalse(client.trustedClients.contains(trustedClient))
        XCTAssertTrue(client.ignoredClients.contains(trustedClient))
    }
    
    func testThatTrustingClientsRemovesTheNeedToNotifyUser() {
        // Given
        let client = clientWithTrustedClientCount(0, ignoredClientCount:1, missedClientCount:0)
        let ignoredClient = client.ignoredClients.first!
        ignoredClient.needsToNotifyUser = true
        
        // When
        client.trustClient(ignoredClient)
        
        // Then
        XCTAssertFalse(ignoredClient.needsToNotifyUser)
    }
    
    func testThatItDeletesASession() {
        self.syncMOC.performGroupedBlockAndWait{
            // given
            let selfClient = self.createSelfClient(onMOC: self.syncMOC)
            
            var preKeys : [(id: UInt16, prekey: String)] = []
            selfClient.keysStore.encryptionContext.perform({ (sessionsDirectory) in
                preKeys = try! sessionsDirectory.generatePrekeys(0 ..< 2)
            })
            
            let otherClient = UserClient.insertNewObject(in: self.syncMOC)
            otherClient.remoteIdentifier = UUID.create().transportString()
            otherClient.user = ZMUser.insertNewObject(in: self.syncMOC)
            otherClient.user?.remoteIdentifier = UUID.create()
            
            guard let preKey = preKeys.first
                else {
                    XCTFail("could not generate prekeys")
                    return
            }
            
            XCTAssertTrue(selfClient.establishSessionWithClient(otherClient, usingPreKey:preKey.prekey))
            XCTAssertTrue(otherClient.hasSessionWithSelfClient)
            
            // when
            UserClient.deleteSession(for:otherClient.sessionIdentifier!, managedObjectContext:self.syncMOC)
            
            // then
            XCTAssertFalse(otherClient.hasSessionWithSelfClient)
        }
        XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }
    
    
    func testThatItDeletesASessionWhenDeletingAClient() {
        self.syncMOC.performGroupedBlockAndWait{
            // given
            let selfClient = self.createSelfClient(onMOC: self.syncMOC)
            var preKeys : [(id: UInt16, prekey: String)] = []
            selfClient.keysStore.encryptionContext.perform({ (sessionsDirectory) in
                preKeys = try! sessionsDirectory.generatePrekeys(0 ..< 2)
            })
            
            let otherClient = UserClient.insertNewObject(in: self.syncMOC)
            otherClient.remoteIdentifier = UUID.create().transportString()
            let otherUser = ZMUser.insertNewObject(in:self.syncMOC)
            otherUser.remoteIdentifier = UUID.create()
            otherClient.user = otherUser
            
            guard let preKey = preKeys.first
                else {
                    XCTFail("could not generate prekeys")
                    return
            }
            
            XCTAssertTrue(selfClient.establishSessionWithClient(otherClient, usingPreKey:preKey.prekey))
            XCTAssertTrue(otherClient.hasSessionWithSelfClient)
            let clientId = otherClient.sessionIdentifier!
            
            // when
            otherClient.deleteClientAndEndSession()
            
            // then
            selfClient.keysStore.encryptionContext.perform {
                XCTAssertFalse($0.hasSession(for: clientId))
            }
            XCTAssertFalse(otherClient.hasSessionWithSelfClient)
            XCTAssertTrue(otherClient.isZombieObject)
        }
        XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }
    
    func testThatItUpdatesConversationSecurityLevelWhenDeletingClient() {
        
        self.syncMOC.performGroupedBlockAndWait{
            // given
            let selfClient = self.createSelfClient(onMOC: self.syncMOC)
            
            let otherClient1 = UserClient.insertNewObject(in: self.syncMOC)
            otherClient1.remoteIdentifier = UUID.create().transportString()
            
            let otherUser = ZMUser.insertNewObject(in:self.syncMOC)
            otherUser.remoteIdentifier = UUID.create()
            otherClient1.user = otherUser
            let connection = ZMConnection.insertNewSentConnection(to: otherUser)!
            connection.status = .accepted
            
            let conversation = ZMConversation.insertNewObject(in:self.syncMOC)
            conversation.conversationType = .group
            conversation.mutableLastServerSyncedActiveParticipants.add(otherUser)
            
            selfClient.trustClient(otherClient1)
            
            conversation.securityLevel = ZMConversationSecurityLevel.notSecure
            XCTAssertEqual(conversation.allMessages.count, 1)

            let otherClient2 = UserClient.insertNewObject(in: self.syncMOC)
            otherClient2.remoteIdentifier = UUID.create().transportString()
            otherClient2.user = otherUser
            
            selfClient.ignoreClient(otherClient2)

            // when
            otherClient2.deleteClientAndEndSession()
            self.syncMOC.saveOrRollback()
            
            // then
            XCTAssertTrue(otherClient2.isZombieObject)
            XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevel.secure)
            XCTAssertEqual(conversation.allMessages.count, 2)
            if let message = conversation.lastMessage as? ZMSystemMessage {
                XCTAssertEqual(message.systemMessageType, ZMSystemMessageType.conversationIsSecure)
                XCTAssertEqual(message.users, Set(arrayLiteral: otherUser))
            } else {
                XCTFail("Did not insert systemMessage")
            }
        }
        XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }
    
    func testThatItRefetchesMissingFingerprintForUserWithSession() {
        // given
        let otherClientId = UUID.create()
        
        self.syncMOC.performGroupedBlockAndWait {
            let selfClient = self.createSelfClient(onMOC: self.syncMOC)
            
            var preKeys : [(id: UInt16, prekey: String)] = []
            selfClient.keysStore.encryptionContext.perform({ (sessionsDirectory) in
                preKeys = try! sessionsDirectory.generatePrekeys(0 ..< 2)
            })
            
            let otherClient = UserClient.insertNewObject(in: self.syncMOC)
            otherClient.remoteIdentifier = otherClientId.transportString()
            let otherUser = ZMUser.insertNewObject(in:self.syncMOC)
            otherUser.remoteIdentifier = UUID.create()
            otherClient.user = otherUser
            
            guard let preKey = preKeys.first
                else {
                    XCTFail("could not generate prekeys")
                    return }
            
            selfClient.keysStore.encryptionContext.perform({ (sessionsDirectory) in
                try! sessionsDirectory.createClientSession(otherClient.sessionIdentifier!, base64PreKeyString: preKey.prekey)
            })
            
            XCTAssertNil(otherClient.fingerprint)
            otherClient.managedObjectContext?.saveOrRollback()
        }
        XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        self.syncMOC.performGroupedBlockAndWait {
            let fetchRequest = NSFetchRequest<UserClient>(entityName: UserClient.entityName())
            fetchRequest.predicate = NSPredicate(format: "%K == %@", "remoteIdentifier", otherClientId.transportString())
            fetchRequest.fetchLimit = 1
            // when
            do {
                let fetchedClient = try self.syncMOC.fetch(fetchRequest).first
                XCTAssertNotNil(fetchedClient)
                XCTAssertNotNil(fetchedClient!.fingerprint)
            } catch let error{
                XCTFail(error.localizedDescription)
            }
        }
    }
    
    func testThatItPostsANotificationToSendASessionResetMessageWhenResettingSession() {
        var (message, conversation): (ZMGenericMessage?, ZMConversation?)

        let noteExpectation = expectation(description: "GenericMessageScheduleNotification should be fired")
        let token = GenericMessageScheduleNotification.addObserver(managedObjectContext:self.uiMOC)
        { noteMessage, noteConversation in
            message = noteMessage
            conversation = noteConversation
            noteExpectation.fulfill()
        }

        self.syncMOC.performGroupedBlockAndWait {
            // given
            let selfClient = self.createSelfClient(onMOC: self.syncMOC)
            
            let otherClient = UserClient.insertNewObject(in: self.syncMOC)
            otherClient.remoteIdentifier = UUID.create().transportString()
            
            let otherUser = ZMUser.insertNewObject(in:self.syncMOC)
            otherUser.remoteIdentifier = UUID.create()
            otherClient.user = otherUser
            
            let connection = ZMConnection.insertNewSentConnection(to: otherUser)!
            connection.status = .accepted
            
            selfClient.trustClient(otherClient)
            
            // when
            otherClient.resetSession()
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))

        // then
        self.syncMOC.performGroupedBlockAndWait {
            withExtendedLifetime(token) { () -> () in
                XCTAssertNotNil(message)
                XCTAssertNotNil(conversation)
                XCTAssertEqual(message?.hasClientAction(), true)
                XCTAssertEqual(message?.clientAction, .RESETSESSION)
            }
        }
    }

    func testThatItSendsASessionResetMessageForUserInTeamConversation() {
        var (message, conversation): (ZMGenericMessage?, ZMConversation?)

        let noteExpectation = expectation(description: "GenericMessageScheduleNotification should be fired")
        let token = GenericMessageScheduleNotification.addObserver(managedObjectContext: self.uiMOC)
        { noteMessage, noteConversation in
            message = noteMessage
            conversation = noteConversation
            noteExpectation.fulfill()
        }
        
        withExtendedLifetime(token) {
            var expectedConversation: ZMConversation?
            
            self.syncMOC.performGroupedBlockAndWait {
                // given
                let selfClient = self.createSelfClient(onMOC: self.syncMOC)
                
                let otherClient = UserClient.insertNewObject(in: self.syncMOC)
                otherClient.remoteIdentifier = UUID.create().transportString()
                
                let otherUser = ZMUser.insertNewObject(in:self.syncMOC)
                otherUser.remoteIdentifier = UUID.create()
                otherClient.user = otherUser
                
                let team = Team.insertNewObject(in: self.syncMOC)
                let selfMember = Member.insertNewObject(in: self.syncMOC)
                selfMember.permissions = .member
                selfMember.team = team
                selfMember.user = selfClient.user
                
                let otherMember = Member.insertNewObject(in: self.syncMOC)
                otherMember.team = team
                otherMember.user = otherUser
                
                expectedConversation = otherUser.oneToOneConversation
                selfClient.trustClient(otherClient)
                
                // when
                otherClient.resetSession()
            }
            
            XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
            
            // then
            self.syncMOC.performGroupedBlockAndWait {
                XCTAssertNotNil(message)
                XCTAssertNotNil(conversation)
                XCTAssertEqual(expectedConversation?.objectID, conversation?.objectID)
                XCTAssertEqual(message?.hasClientAction(), true)
                XCTAssertEqual(message?.clientAction, .RESETSESSION)
            }
        }
    }
    
    func testThatItAsksForMoreWhenRunningOutOfPrekeys() {
        
        self.syncMOC.performGroupedBlockAndWait {
            // given
            let selfClient = self.createSelfClient(onMOC: self.syncMOC)
            selfClient.numberOfKeysRemaining = 1
            
            // when
            selfClient.decrementNumberOfRemainingKeys()
            
            // then
            XCTAssertTrue(selfClient.modifiedKeys!.contains(ZMUserClientNumberOfKeysRemainingKey))
        }
    }
    
    func testThatItDoesntAskForMoreWhenItStillHasPrekeys() {
        
        self.syncMOC.performGroupedBlockAndWait {
            // given
            let selfClient = self.createSelfClient(onMOC: self.syncMOC)
            selfClient.numberOfKeysRemaining = 2
            
            // when
            selfClient.decrementNumberOfRemainingKeys()
            
            // then
            XCTAssertNil(selfClient.modifiedKeys)
        }
    }
}

extension UserClientTests {
    func testThatItStoresFailedToEstablishSessionInformation() {
        self.syncMOC.performGroupedBlockAndWait {
            // given
            let client = UserClient.insertNewObject(in: self.syncMOC)
            
            // when & then
            XCTAssertFalse(client.failedToEstablishSession)
            
            // when
            client.failedToEstablishSession = true
            
            // then
            XCTAssertTrue(client.failedToEstablishSession)
            
            // when
            client.failedToEstablishSession = false
            
            // then
            XCTAssertFalse(client.failedToEstablishSession)
        }
    }
}

extension UserClientTests {
    
    func testThatSelfClientIsTrusted() {
        // given & when
        let selfClient = self.createSelfClient()
    
        //then
        XCTAssertTrue(selfClient.verified)
    }
    
    func testThatSelfClientIsStillVerifiedAfterIgnoring() {
        // given
        let selfClient = self.createSelfClient()
        
        // when
        selfClient.ignoreClient(selfClient);
        
        //then
        XCTAssertTrue(selfClient.verified)
    }
    
    func testThatUnknownClientIsNotVerified() {
        // given & when
        self.createSelfClient()
        
        let otherClient = UserClient.insertNewObject(in: self.uiMOC);
        otherClient.remoteIdentifier = NSString.createAlphanumerical()
        
        // then
        XCTAssertFalse(otherClient.verified)
    }
    
    func testThatItIsVerifiedWhenTrusted() {
        // given
        let selfClient = self.createSelfClient()

        let otherClient = UserClient.insertNewObject(in: self.uiMOC);
        otherClient.remoteIdentifier = NSString.createAlphanumerical()
        
        // when
        selfClient.trustClient(otherClient)
        
        // then
        XCTAssertTrue(otherClient.verified)
    }
    
    func testThatItIsNotVerifiedWhenIgnored() {
        // given
        let selfClient = createSelfClient()
        
        let otherClient = UserClient.insertNewObject(in: self.uiMOC);
        otherClient.remoteIdentifier = NSString.createAlphanumerical()
        
        // when
        selfClient.ignoreClient(otherClient)
        
        // then
        XCTAssertFalse(otherClient.verified)
    }
}


// MARK : SignalingStore

extension UserClientTests {

    func testThatItDeletesExistingSignalingKeys() {
        
        // given
        let selfClient = createSelfClient()
        selfClient.apsVerificationKey =  Data()
        selfClient.apsDecryptionKey = Data()
        
        XCTAssertNotNil(selfClient.apsVerificationKey)
        XCTAssertNotNil(selfClient.apsDecryptionKey)
        
        // when
        UserClient.resetSignalingKeysInContext(self.uiMOC)
        
        // then
        XCTAssertNil(selfClient.apsVerificationKey)
        XCTAssertNil(selfClient.apsDecryptionKey)
    }
    
    func testThatItSetsKeysNeedingToBeSynced() {
        
        // given
        let selfClient = createSelfClient()
        
        // when
        UserClient.resetSignalingKeysInContext(self.uiMOC)
        
        // then
        XCTAssertTrue(selfClient.needsToUploadSignalingKeys)
        XCTAssertTrue(selfClient.keysThatHaveLocalModifications.contains(ZMUserClientNeedsToUpdateSignalingKeysKey))
    }
    
}

// MARK : fetchFingerprintOrPrekeys

extension UserClientTests {
        
    func testThatItSetsTheUserWhenInsertingANewSelfUserClient(){
        // given
        _ = createSelfClient()
        let newClientPayload : [String : AnyObject] = ["id": UUID().transportString() as AnyObject,
                                                       "type": "permanent" as AnyObject,
                                                       "time": Date().transportString() as AnyObject]
        // when
        var newClient : UserClient!
        self.performPretendingUiMocIsSyncMoc {
            newClient = UserClient.createOrUpdateSelfUserClient(newClientPayload, context: self.uiMOC)
            XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        }
        
        // then
        XCTAssertNotNil(newClient)
        XCTAssertNotNil(newClient.user)
        XCTAssertEqual(newClient.user, ZMUser.selfUser(in: uiMOC))
        XCTAssertNotNil(newClient.sessionIdentifier)
    }
    
    func testThatItSetsTheUserWhenInsertingANewSelfUserClient_NoExistingSelfClient(){
        // given
        let newClientPayload : [String : AnyObject] = ["id": UUID().transportString() as AnyObject,
                                                       "type": "permanent" as AnyObject,
                                                       "time": Date().transportString() as AnyObject]
        // when
        var newClient : UserClient!
        self.performPretendingUiMocIsSyncMoc {
            newClient = UserClient.createOrUpdateSelfUserClient(newClientPayload, context: self.uiMOC)
            XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        }
        
        // then
        XCTAssertNotNil(newClient)
        XCTAssertNotNil(newClient.user)
        XCTAssertEqual(newClient.user, ZMUser.selfUser(in: uiMOC))
        XCTAssertNil(newClient.sessionIdentifier)
    }
    
    
    func testThatItDoNothingWhenHasAFingerprint() {
        // GIVEN
        let fingerprint = Data(base64Encoded: "cmVhZGluZyB0ZXN0cyBpcyBjb29s")
        
        let client = UserClient.insertNewObject(in: self.uiMOC)
        client.fingerprint = fingerprint
        
        self.uiMOC.saveOrRollback()
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.05))
        
        // WHEN
        client.fetchFingerprintOrPrekeys()
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.05))
        
        // THEN
        XCTAssertTrue(client.keysThatHaveLocalModifications.isEmpty)
        XCTAssertEqual(client.fingerprint, fingerprint)
    }
    
    func testThatItLoadsFingerprintForSelfClient() {
        
        // GIVEN
        var selfClient: UserClient!
        var newFingerprint : Data?

        self.syncMOC.performGroupedBlockAndWait {
            
            selfClient = self.createSelfClient(onMOC: self.syncMOC)
            selfClient.fingerprint = .none
            
            self.syncMOC.zm_cryptKeyStore.encryptionContext.perform { (sessionsDirectory) in
                newFingerprint = sessionsDirectory.localFingerprint
            }
            
            self.syncMOC.saveOrRollback()
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.05))
            
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            selfClient.fetchFingerprintOrPrekeys()
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.05))
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertTrue(selfClient.keysThatHaveLocalModifications.isEmpty)
            XCTAssertEqual(selfClient.fingerprint!, newFingerprint)
        }
    }
    
    func testThatItLoadsFingerprintForExistingSession() {
        var client: UserClient!
        
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let selfClient = self.createSelfClient(onMOC: self.syncMOC)
            
            var preKeys : [(id: UInt16, prekey: String)] = []
            
            selfClient.keysStore.encryptionContext.perform({ (sessionsDirectory) in
                preKeys = try! sessionsDirectory.generatePrekeys(0 ..< 2)
            })
        
            guard let preKey = preKeys.first
                else {
                    XCTFail("could not generate prekeys")
                    return }
            
            client = UserClient.insertNewObject(in: self.syncMOC)
            let otherUser = ZMUser.insertNewObject(in:self.syncMOC)
            otherUser.remoteIdentifier = UUID.create()
            client.user = otherUser
            client.remoteIdentifier = "badf00d"
            
            self.syncMOC.zm_cryptKeyStore.encryptionContext.perform { (sessionsDirectory) in
                try! sessionsDirectory.createClientSession(client.sessionIdentifier!, base64PreKeyString: preKey.prekey)
            }
            
            // WHEN
            client.fetchFingerprintOrPrekeys()
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.05))
            
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertTrue(client.keysThatHaveLocalModifications.isEmpty)
            XCTAssertNotEqual(client.fingerprint!.count, 0)
        }
    }
    
    func testThatItMarksMissingWhenNoSession() {
        var client: UserClient!
        var selfClient: UserClient!
        
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            selfClient = self.createSelfClient(onMOC: self.syncMOC)
            client = UserClient.insertNewObject(in: self.syncMOC)
            let otherUser = ZMUser.insertNewObject(in:self.syncMOC)
            otherUser.remoteIdentifier = UUID.create()
            client.user = otherUser
            client.remoteIdentifier = "badf00d"

            self.syncMOC.saveOrRollback()
            
            // WHEN
            client.fetchFingerprintOrPrekeys()
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.05))
            
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertTrue(selfClient.hasLocalModifications(forKey: ZMUserClientMissingKey))
            XCTAssertEqual(client.fingerprint, .none)
        }
    }
    
    func testThatItCreatesUserClientIfNeeded() {
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)
            otherUser.remoteIdentifier = UUID.create()
            // WHEN
            let client = UserClient.fetchUserClient(withRemoteId: "badf00d", forUser: otherUser, createIfNeeded: true)
            
            // THEN
            XCTAssertNotNil(client)
            XCTAssertEqual(client?.remoteIdentifier, "badf00d")
            XCTAssertEqual(client?.user, otherUser)
        }
    }
    
    func testThatItFetchesUserClientWithoutSave() {
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)
            otherUser.remoteIdentifier = UUID.create()
            // WHEN
            let client1 = UserClient.fetchUserClient(withRemoteId: "badf00d", forUser: otherUser, createIfNeeded: true)
            let client2 = UserClient.fetchUserClient(withRemoteId: "badf00d", forUser: otherUser, createIfNeeded: true)
            
            // THEN
            XCTAssertNotNil(client1)
            XCTAssertNotNil(client2)
            
            XCTAssertEqual(client1, client2)
        }
    }
    
    func testThatItFetchesUserClient_OtherMOC() {
        var clientSync: UserClient?
        let userUI = ZMUser.insertNewObject(in: self.uiMOC)
        userUI.remoteIdentifier = UUID.create()

        self.uiMOC.saveOrRollback()
        
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let userSync = try! self.syncMOC.existingObject(with: userUI.objectID) as! ZMUser
            // WHEN
            clientSync = UserClient.fetchUserClient(withRemoteId: "badf00d", forUser: userSync, createIfNeeded: true)
            clientSync?.label = "test"
            // THEN
            XCTAssertNotNil(clientSync)
            self.syncMOC.saveOrRollback()
        }
        
        // WHEN
        let clientUI: UserClient? = UserClient.fetchUserClient(withRemoteId: "badf00d", forUser: userUI, createIfNeeded: false)
        
        // THEN
        XCTAssertNotNil(clientUI)
        XCTAssertEqual(clientUI?.remoteIdentifier, "badf00d")
        XCTAssertEqual(clientUI?.label, "test")
    }
    
    func testThatItFetchesUserClientWithSave() {
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)
            otherUser.remoteIdentifier = UUID.create()
            // WHEN
            let client1 = UserClient.fetchUserClient(withRemoteId: "badf00d", forUser: otherUser, createIfNeeded: true)
            
            // AND THEN
            self.syncMOC.saveOrRollback()
            
            // WHEN
            let client2 = UserClient.fetchUserClient(withRemoteId: "badf00d", forUser: otherUser, createIfNeeded: true)
            
            // THEN
            XCTAssertNotNil(client1)
            XCTAssertNotNil(client2)
            
            XCTAssertEqual(client1, client2)
        }
    }
}

extension UserClientTests {
    func testThatClientHasNoPushTokenWhenCreated() {
        // given
        let client = UserClient.insertNewObject(in: self.uiMOC)

        // then
        XCTAssertNil(client.pushToken)
    }

    func testThatWeCanAccessPushTokenAfterCreation() {
        syncMOC.performGroupedAndWait { _ in
            // given
            let client = UserClient.insertNewObject(in: self.syncMOC)
            let token = PushToken(deviceToken: Data(), appIdentifier: "one", transportType: "two", isRegistered: false)

            // when
            client.pushToken = token

            // then
            XCTAssertEqual(client.pushToken, token)
        }
    }

    func testThatWeCanAccessPushTokenFromAnotherContext() throws {
        // given
        let client = UserClient.insertNewObject(in: self.uiMOC)
        let token = PushToken(deviceToken: Data(), appIdentifier: "one", transportType: "two", isRegistered: false)
        self.uiMOC.saveOrRollback()

        self.syncMOC.performGroupedBlockAndWait {
            let syncClient = try? self.syncMOC.existingObject(with: client.objectID) as? UserClient

            // when
            syncClient?.pushToken = token
            self.syncMOC.saveOrRollback()
        }

        // then
        self.uiMOC.refreshAllObjects()
        XCTAssertEqual(client.pushToken, token)
    }
}

// MARK: - Update from payload

extension UserClientTests {
    
    func testThatItUpdatesDeviceClassFromPayload() {
        // given
        let allCases: [DeviceClass] = [.desktop, .phone, .tablet, .legalHold]
        let client = UserClient.insertNewObject(in: uiMOC)
        client.user = createUser(in: uiMOC)
        
        for deviceClass in allCases {
            // when
            client.update(with: ["class": deviceClass.rawValue])
            
            // then
            XCTAssertEqual(client.deviceClass, deviceClass)
        }
    }
    
    func testThatItSelfClientsAreNotUpdatedFromPayload() {
        // given
        let deviceClass = DeviceClass.desktop
        let selfClient = createSelfClient()
        
        // when
        selfClient.update(with: ["class": deviceClass.rawValue])
        
        // then
        XCTAssertNotEqual(selfClient.deviceClass, deviceClass)
    }
    
    func testThatItResetsNeedsToBeUpdatedFromBackend() {
        // given
        let client = UserClient.insertNewObject(in: uiMOC)
        client.user = createUser(in: uiMOC)
        client.needsToBeUpdatedFromBackend = true
        
        // when
        client.update(with: [:])
        
        // then
        XCTAssertFalse(client.needsToBeUpdatedFromBackend)
    }
        
}

