//
//

import WireTesting
import WireDataModel

class ZMClientMessageTests_Unarchiving : BaseZMClientMessageTests {

    func testThatItUnarchivesAConversationWhenItWasNotCleared(){
    
        // given
        let conversation = ZMConversation.insertNewObject(in:uiMOC)
        conversation.remoteIdentifier = UUID.create()
        conversation.isArchived = true
        
        let genericMessage = ZMGenericMessage.message(content: ZMText.text(with: "bar"))
        let event = createUpdateEvent(UUID(), conversationID: conversation.remoteIdentifier!, genericMessage: genericMessage)

        // when
        performPretendingUiMocIsSyncMoc {
            XCTAssertNotNil(ZMOTRMessage.createOrUpdate(from: event, in: self.uiMOC, prefetchResult: nil))
        }
        
        // then
        XCTAssertFalse(conversation.isArchived)
    }
    
    func testThatItDoesNotUnarchiveASilencedConversation(){
        
        // given
        let conversation = ZMConversation.insertNewObject(in:uiMOC)
        conversation.remoteIdentifier = UUID.create()
        conversation.isArchived = true
        conversation.mutedMessageTypes = .all

        let genericMessage = ZMGenericMessage.message(content: ZMText.text(with: "bar"))
        let event = createUpdateEvent(UUID(), conversationID: conversation.remoteIdentifier!, genericMessage: genericMessage)
        
        // when
        performPretendingUiMocIsSyncMoc {
            ZMOTRMessage.createOrUpdate(from: event, in: self.uiMOC, prefetchResult: nil)
        }
        
        // then
        XCTAssertTrue(conversation.isArchived)
    }
    
    func testThatItDoesNotUnarchiveAClearedConversation_TimestampForMessageIsOlder(){
        
        // given
        let conversation = ZMConversation.insertNewObject(in:uiMOC)
        conversation.remoteIdentifier = UUID.create()
        conversation.isArchived = true
        uiMOC.saveOrRollback()

        let lastMessage = conversation.append(text: "foo") as! ZMClientMessage
        lastMessage.serverTimestamp = Date().addingTimeInterval(10)
        conversation.lastServerTimeStamp = lastMessage.serverTimestamp!
        conversation.clearMessageHistory()
        
        let genericMessage = ZMGenericMessage.message(content: ZMText.text(with: "bar"))
        let event = createUpdateEvent(UUID(), conversationID: conversation.remoteIdentifier!, genericMessage: genericMessage)
        XCTAssertNotNil(event)
        
        XCTAssertGreaterThan(conversation.clearedTimeStamp!.timeIntervalSince1970, event.timeStamp()!.timeIntervalSince1970)
        
        // when
        performPretendingUiMocIsSyncMoc { 
            ZMOTRMessage.createOrUpdate(from: event, in: self.uiMOC, prefetchResult: nil)
        }
        
        // then
        XCTAssertTrue(conversation.isArchived)
    }
    
    func testThatItUnarchivesAClearedConversation_TimestampForMessageIsNewer(){
        
        // given
        let conversation = ZMConversation.insertNewObject(in:uiMOC)
        conversation.remoteIdentifier = UUID.create()
        conversation.isArchived = true
        uiMOC.saveOrRollback()

        let lastMessage = conversation.append(text: "foo") as! ZMClientMessage
        lastMessage.serverTimestamp = Date().addingTimeInterval(-10)
        conversation.lastServerTimeStamp = lastMessage.serverTimestamp!
        conversation.clearMessageHistory()

        let genericMessage = ZMGenericMessage.message(content: ZMText.text(with: "bar"))
        let event = createUpdateEvent(UUID(), conversationID: conversation.remoteIdentifier!, genericMessage: genericMessage)
        
        XCTAssertLessThan(conversation.clearedTimeStamp!.timeIntervalSince1970, event.timeStamp()!.timeIntervalSince1970)
        
        // when
        performPretendingUiMocIsSyncMoc {
            ZMOTRMessage.createOrUpdate(from: event, in: self.uiMOC, prefetchResult: nil)
        }
        // then
        XCTAssertFalse(conversation.isArchived)
    }

}


