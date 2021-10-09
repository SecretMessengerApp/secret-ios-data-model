//
//

import XCTest
import WireUtilities
@testable import WireDataModel
import WireLinkPreview


class ZMOTRMessage_SecurityDegradationTests : BaseZMClientMessageTests {
    
    func testThatAtCreationAMessageIsNotCausingDegradation_UIMoc() {
        
        // GIVEN
        let convo = createConversation(moc: self.uiMOC)
        
        // WHEN
        let message = convo.append(text: "Foo")!
        self.uiMOC.saveOrRollback()
        
        // THEN
        XCTAssertFalse(message.causedSecurityLevelDegradation)
        XCTAssertTrue(convo.messagesThatCausedSecurityLevelDegradation.isEmpty)
        XCTAssertFalse(self.uiMOC.zm_hasChanges)
    }
    
    func testThatAtCreationAMessageIsNotCausingDegradation_SyncMoc() {
        
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let convo = self.createConversation(moc: self.syncMOC)
            
            // WHEN
            let message = convo.append(text: "Foo")!
            
            // THEN
            XCTAssertFalse(message.causedSecurityLevelDegradation)
            XCTAssertTrue(convo.messagesThatCausedSecurityLevelDegradation.isEmpty)
        }
    }
    
    func testThatItSetsMessageAsCausingDegradation() {
        
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let convo = self.createConversation(moc: self.syncMOC)
            let message = convo.append(text: "Foo") as! ZMOTRMessage
            self.syncMOC.saveOrRollback()

            // WHEN
            message.causedSecurityLevelDegradation = true
            
            // THEN
            XCTAssertTrue(message.causedSecurityLevelDegradation)
            XCTAssertTrue(convo.messagesThatCausedSecurityLevelDegradation.contains(message))
            XCTAssertTrue(self.syncMOC.zm_hasChanges)

        }
    }
    
    func testThatItDoesNotSetDeliveryReceiptAsCausingDegradation() {
        
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let convo = self.createConversation(moc: self.syncMOC)
            let message = convo.append(text: "Foo") as! ZMClientMessage
            message.markAsSent()
            convo.securityLevel = .secure
            self.syncMOC.saveOrRollback()
            
            let confirmation = convo.append(message: ZMConfirmation.confirm(messageId: message.nonce!, type: .DELIVERED), hidden: true)!

            // WHEN
            let newClient = UserClient.insertNewObject(in: self.syncMOC)
            convo.decreaseSecurityLevelIfNeededAfterDiscovering(clients: [newClient], causedBy: confirmation)
            self.syncMOC.saveOrRollback()
            
            // THEN
            XCTAssertEqual(convo.securityLevel, .secureWithIgnored)
            XCTAssertFalse(message.causedSecurityLevelDegradation)
            XCTAssertFalse(confirmation.causedSecurityLevelDegradation)
            XCTAssertFalse(convo.messagesThatCausedSecurityLevelDegradation.contains(confirmation))
            XCTAssertFalse(self.syncMOC.zm_hasChanges)
        }
    }
    
    func testThatItResetsMessageAsCausingDegradation() {
        
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let convo = self.createConversation(moc: self.syncMOC)
            let message = convo.append(text: "Foo") as! ZMOTRMessage
            message.causedSecurityLevelDegradation = true
            self.syncMOC.saveOrRollback()
            
            // WHEN
            message.causedSecurityLevelDegradation = false

            
            // THEN
            XCTAssertFalse(message.causedSecurityLevelDegradation)
            XCTAssertTrue(convo.messagesThatCausedSecurityLevelDegradation.isEmpty)
            XCTAssertTrue(self.syncMOC.zm_hasChanges)

        }
    }
    
    func testThatItResetsDegradedConversationWhenRemovingAllMessages() {
        
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let convo = self.createConversation(moc: self.syncMOC)
            let message1 = convo.append(text: "Foo") as! ZMOTRMessage
            message1.causedSecurityLevelDegradation = true
            let message2 = convo.append(text: "Foo") as! ZMOTRMessage
            message2.causedSecurityLevelDegradation = true
            
            // WHEN
            message1.causedSecurityLevelDegradation = false
            
            // THEN
            XCTAssertFalse(message1.causedSecurityLevelDegradation)
            XCTAssertFalse(convo.messagesThatCausedSecurityLevelDegradation.contains(message1))
            XCTAssertTrue(convo.messagesThatCausedSecurityLevelDegradation.contains(message2))

            // and WHEN
            self.syncMOC.saveOrRollback()
            message2.causedSecurityLevelDegradation = false
            
            // THEN
            XCTAssertFalse(message2.causedSecurityLevelDegradation)
            XCTAssertTrue(convo.messagesThatCausedSecurityLevelDegradation.isEmpty)
            XCTAssertTrue(self.syncMOC.zm_hasChanges)
            
        }
    }
    
    func testThatItResetsDegradedConversationWhenClearingDegradedMessagesOnConversation() {
        
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let convo = self.createConversation(moc: self.syncMOC)
            let message1 = convo.append(text: "Foo") as! ZMOTRMessage
            message1.causedSecurityLevelDegradation = true
            let message2 = convo.append(text: "Foo") as! ZMOTRMessage
            message2.causedSecurityLevelDegradation = true
            
            // WHEN
            convo.clearMessagesThatCausedSecurityLevelDegradation()

            // THEN
            XCTAssertFalse(message1.causedSecurityLevelDegradation)
            XCTAssertFalse(message2.causedSecurityLevelDegradation)
            XCTAssertTrue(convo.messagesThatCausedSecurityLevelDegradation.isEmpty)
            XCTAssertTrue(self.syncMOC.zm_hasUserInfoChanges)
        }
    }
    
    func testThatItResetsOnlyDegradedConversationWhenClearingDegradedMessagesOnThatConversation() {
        
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let convo = self.createConversation(moc: self.syncMOC)
            let message1 = convo.append(text: "Foo") as! ZMOTRMessage
            message1.causedSecurityLevelDegradation = true
            let message2 = convo.append(text: "Foo") as! ZMOTRMessage
            message2.causedSecurityLevelDegradation = true
            
            let otherConvo = self.createConversation(moc: self.syncMOC)
            let otherMessage = otherConvo.append(text: "Foo") as! ZMOTRMessage
            otherMessage.causedSecurityLevelDegradation = true
            
            // WHEN
            convo.clearMessagesThatCausedSecurityLevelDegradation()
            
            // THEN
            XCTAssertFalse(message1.causedSecurityLevelDegradation)
            XCTAssertFalse(message2.causedSecurityLevelDegradation)
            XCTAssertTrue(convo.messagesThatCausedSecurityLevelDegradation.isEmpty)
            XCTAssertTrue(self.syncMOC.zm_hasUserInfoChanges)
            
            XCTAssertFalse(otherConvo.messagesThatCausedSecurityLevelDegradation.isEmpty)
            XCTAssertTrue(otherMessage.causedSecurityLevelDegradation)
        }
    }

}

// MARK: - Propagation across contexes
extension ZMOTRMessage_SecurityDegradationTests {
    
    func testThatMessageIsNotMarkedOnUIMOCBeforeMerge() {
        // GIVEN
        let convo = createConversation(moc: self.uiMOC)
        let message = convo.append(text: "Foo")! as! ZMOTRMessage
        self.uiMOC.saveOrRollback()
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait { 
            let syncMessage = try! self.syncMOC.existingObject(with: message.objectID) as! ZMOTRMessage
            syncMessage.causedSecurityLevelDegradation = true
            self.syncMOC.saveOrRollback()
        }
        
        // THEN
        XCTAssertFalse(message.causedSecurityLevelDegradation)
    }
    
    func testThatMessageIsMarkedOnUIMOCAfterMerge() {
        // GIVEN
        let convo = createConversation(moc: self.uiMOC)
        let message = convo.append(text: "Foo")! as! ZMOTRMessage
        self.uiMOC.saveOrRollback()
        var userInfo : [String: Any] = [:]
        self.syncMOC.performGroupedBlockAndWait {
            let syncMessage = try! self.syncMOC.existingObject(with: message.objectID) as! ZMOTRMessage
            syncMessage.causedSecurityLevelDegradation = true
            self.syncMOC.saveOrRollback()
            userInfo = self.syncMOC.userInfo.asDictionary() as! [String: Any]
        }
        
        // WHEN
        self.uiMOC.mergeUserInfo(fromUserInfo: userInfo)
        
        // THEN
        XCTAssertTrue(message.causedSecurityLevelDegradation)
    }
    
    func testThatItPreservesMessagesMargedOnSyncMOCAfterMerge() {
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let convo = self.createConversation(moc: self.syncMOC)
            let message = convo.append(text: "Foo")! as! ZMOTRMessage
            message.causedSecurityLevelDegradation = true
            
            // WHEN
            self.syncMOC.mergeUserInfo(fromUserInfo: [:])
            
            // THEN
            XCTAssertTrue(message.causedSecurityLevelDegradation)
        }
    }
}

// MARK: - Helper
extension ZMOTRMessage_SecurityDegradationTests {
    
    /// Creates a group conversation with two users
    func createConversation(moc: NSManagedObjectContext) -> ZMConversation {
        let user1 = ZMUser.insertNewObject(in: moc)
        user1.remoteIdentifier = UUID.create()
        let user2 = ZMUser.insertNewObject(in: moc)
        user2.remoteIdentifier = UUID.create()
        let convo = ZMConversation.insertGroupConversation(into: moc, withParticipants: [user1, user2])!
        return convo
    }
    
}
