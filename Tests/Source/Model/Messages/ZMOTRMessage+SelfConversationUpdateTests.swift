//
// 

import XCTest

class ZMOTRMessage_SelfConversationUpdateEventTests: BaseZMClientMessageTests {
    
    
    func testThatWeIgnoreClearedEventNotSentFromSelfUser() {
        
        syncMOC.performGroupedBlockAndWait {
            // given
            let nonce = UUID()
            let clearedDate = Date()
            let selfConversation = ZMConversation.selfConversation(in: self.syncMOC)
            let message = ZMGenericMessage.message(content: ZMCleared(timestamp: clearedDate, conversationRemoteID: self.syncConversation.remoteIdentifier!), nonce: nonce)
            let event = self.createUpdateEvent(nonce, conversationID: selfConversation.remoteIdentifier!, timestamp: Date(), genericMessage: message, senderID: UUID(), eventSource: ZMUpdateEventSource.download)
            
            // when
            ZMOTRMessage.createOrUpdate(from: event, in: self.syncMOC, prefetchResult: nil)
            
            // then
            XCTAssertNil(self.syncConversation.clearedTimeStamp)
        }
        
    }
    
    func testThatWeIgnoreLastReadEventNotSentFromSelfUser() {
        
        syncMOC.performGroupedBlockAndWait {
            // given
            let nonce = UUID()
            let lastReadDate = Date()
            let selfConversation = ZMConversation.selfConversation(in: self.syncMOC)
            let message = ZMGenericMessage.message(content: ZMLastRead(timestamp: lastReadDate, conversationRemoteID: self.syncConversation.remoteIdentifier!), nonce: nonce)
            let event = self.createUpdateEvent(nonce, conversationID: selfConversation.remoteIdentifier!, timestamp: Date(), genericMessage: message, senderID: UUID(), eventSource: ZMUpdateEventSource.download)
            self.syncConversation.lastReadServerTimeStamp = nil
            
            // when
            ZMOTRMessage.createOrUpdate(from: event, in: self.syncMOC, prefetchResult: nil)
            
            // then
            XCTAssertNil(self.syncConversation.lastReadServerTimeStamp)
        }
        
    }
    
    func testThatWeIgnoreHideMessageEventNotSentFromSelfUser() {
        
        syncMOC.performGroupedBlockAndWait {
            // given
            let nonce = UUID()
            let selfConversation = ZMConversation.selfConversation(in: self.syncMOC)
            let toBehiddenMessage = self.syncConversation.append(text: "hello") as! ZMClientMessage
            let hideMessage = ZMMessageHide.hide(conversationId: self.syncConversation.remoteIdentifier!, messageId: toBehiddenMessage.nonce!)
            let message = ZMGenericMessage.message(content: hideMessage, nonce: nonce)
            let event = self.createUpdateEvent(nonce, conversationID: selfConversation.remoteIdentifier!, timestamp: Date(), genericMessage: message, senderID: UUID(), eventSource: ZMUpdateEventSource.download)
            
            // when
            ZMOTRMessage.createOrUpdate(from: event, in: self.syncMOC, prefetchResult: nil)
            
            // then
            XCTAssertFalse(toBehiddenMessage.hasBeenDeleted)
        }
        
    }
    
}
