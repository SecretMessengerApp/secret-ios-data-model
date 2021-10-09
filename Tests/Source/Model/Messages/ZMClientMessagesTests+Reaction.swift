//
//

import WireTesting

class ZMClientMessageTests_Reaction: BaseZMClientMessageTests {
    
}

extension ZMClientMessageTests_Reaction {
    
    func insertMessage() ->  ZMMessage {
        let sender = ZMUser.insertNewObject(in: uiMOC)
        sender.remoteIdentifier = .create()
        
        let message = conversation.append(text: "JCVD, full split please") as! ZMMessage
        message.sender = sender
        uiMOC.saveOrRollback()

        return message
    }
    
    func updateEventForAddingReaction(to message: ZMMessage, sender: ZMUser? = nil) -> ZMUpdateEvent {
        let sender = sender ?? message.sender!
        let genericMessage = ZMGenericMessage.message(content: ZMReaction(emoji: "❤️", messageID: message.nonce!))
        let event = createUpdateEvent(UUID(), conversationID: conversation.remoteIdentifier!, genericMessage: genericMessage, senderID: sender.remoteIdentifier!)
        return event
    }
    
    func updateEventForRemovingReaction(to message: ZMMessage, sender: ZMUser? = nil) -> ZMUpdateEvent {
        let sender = sender ?? message.sender!
        let genericMessage = ZMGenericMessage.message(content: ZMReaction(emoji: "", messageID: message.nonce!))
        let event = createUpdateEvent(UUID(), conversationID: conversation.remoteIdentifier!, genericMessage: genericMessage, senderID: sender.remoteIdentifier!)
        return event
    }
    
    func testThatItAppendsAReactionWhenReceivingUpdateEventWithValidReaction() {
        
        let message = insertMessage()
        let event = updateEventForAddingReaction(to: message)
        
        // when
        performPretendingUiMocIsSyncMoc {
            ZMClientMessage.createOrUpdate(from: event, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        
        XCTAssertEqual(message.reactions.count, 1)
        XCTAssertEqual(message.usersReaction.count, 1)
    }
    
    func testThatItUpdatesTheCategoryWhenAddingAReaction(){
        let message = insertMessage()
        XCTAssertTrue(message.cachedCategory.contains(.text))
        XCTAssertFalse(message.cachedCategory.contains(.liked))
        
        let event = updateEventForAddingReaction(to: message, sender: ZMUser.selfUser(in: uiMOC))
        
        // when
        performPretendingUiMocIsSyncMoc {
            ZMClientMessage.createOrUpdate(from: event, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        XCTAssertTrue(message.cachedCategory.contains(.text))
        XCTAssertTrue(message.cachedCategory.contains(.liked))
    }
    
    func testThatItDoesNOTAppendsAReactionWhenReceivingUpdateEventWithValidReaction() {
        
        let message = insertMessage()
        let genericMessage = ZMGenericMessage.message(content: ZMReaction(emoji: "TROP BIEN", messageID: message.nonce!))
        let event = createUpdateEvent(UUID(), conversationID: conversation.remoteIdentifier!, genericMessage: genericMessage, senderID: message.sender!.remoteIdentifier!)
        
        // when
        performPretendingUiMocIsSyncMoc {
            ZMClientMessage.createOrUpdate(from: event, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        
        XCTAssertEqual(message.reactions.count, 0)
        XCTAssertEqual(message.usersReaction.count, 0)
    }
    
    func testThatItRemovesAReactionWhenReceivingUpdateEventWithValidReaction() {
        
        let message = insertMessage()
        message.addReaction("❤️", forUser: message.sender!)
        uiMOC.saveOrRollback()
        
        let event = updateEventForRemovingReaction(to: message)
        
        // when
        performPretendingUiMocIsSyncMoc {
            ZMClientMessage.createOrUpdate(from: event, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        XCTAssertEqual(message.usersReaction.count, 0)
    }

    func testThatItUpdatesTheCategoryWhenRemovingAReaction(){

        // given
        let message = insertMessage()
        message.addReaction("❤️", forUser: ZMUser.selfUser(in: uiMOC))
        uiMOC.saveOrRollback()
        XCTAssertTrue(message.cachedCategory.contains(.text))
        XCTAssertTrue(message.cachedCategory.contains(.liked))
        
        let event = updateEventForRemovingReaction(to: message, sender: ZMUser.selfUser(in: uiMOC))
        
        // when
        performPretendingUiMocIsSyncMoc {
            ZMClientMessage.createOrUpdate(from: event, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        XCTAssertTrue(message.cachedCategory.contains(.text))
        XCTAssertFalse(message.cachedCategory.contains(.liked))
    }
}
