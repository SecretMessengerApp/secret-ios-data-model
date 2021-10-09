//
//

import XCTest
@testable import WireDataModel

class ZMClientMessagesTests_Replies: BaseZMClientMessageTests {
    
    func testQuoteRelationshipIsEstablishedWhenSendingMessage() {
        let quotedMessage = conversation.append(text: "I have a proposal", mentions: [], replyingTo: nil, fetchLinkPreview: false, nonce: UUID()) as! ZMClientMessage
        
        let message = conversation.append(text: "That's fine", mentions: [], replyingTo: quotedMessage, fetchLinkPreview: false, nonce: UUID()) as! ZMTextMessageData
        
        XCTAssertEqual(message.quote, quotedMessage)
    }
    
    func testQuoteRelationshipIsEstablishedWhenReceivingMessage() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC); conversation.remoteIdentifier = UUID.create()
        let quotedMessage = conversation.append(text: "The sky is blue") as? ZMClientMessage
        let replyMessage = ZMGenericMessage.message(content: ZMText.text(with: "I agree", replyingTo: quotedMessage))
        let data = ["sender": NSString.createAlphanumerical(), "text": replyMessage.data()?.base64EncodedString()]
        let payload = payloadForMessage(in: conversation, type: EventConversationAddOTRMessage, data: data)!
        let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)!
        
        // when
        var sut: ZMClientMessage! = nil
        performPretendingUiMocIsSyncMoc {
            sut = ZMClientMessage.createOrUpdate(from: event, in: self.uiMOC, prefetchResult: nil)
        }
        
        // then
        XCTAssertNotNil(sut);
        XCTAssertEqual(sut.quote, quotedMessage)
    }
    
    func testQuoteRelationshipIsEstablishedWhenReceivingEphemeralMessage() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC); conversation.remoteIdentifier = UUID.create()
        let quotedMessage = conversation.append(text: "The sky is blue") as? ZMClientMessage
        let replyMessage = ZMGenericMessage.message(content: ZMEphemeral.ephemeral(content: ZMText.text(with: "I agree", replyingTo: quotedMessage), expiresAfter: 1000))
        let data = ["sender": NSString.createAlphanumerical(), "text": replyMessage.data()?.base64EncodedString()]
        let payload = payloadForMessage(in: conversation, type: EventConversationAddOTRMessage, data: data)!
        let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)!
        
        // when
        var sut: ZMClientMessage! = nil
        performPretendingUiMocIsSyncMoc {
            sut = ZMClientMessage.createOrUpdate(from: event, in: self.uiMOC, prefetchResult: nil)
        }
        
        // then
        XCTAssertNotNil(sut);
        XCTAssertEqual(sut.quote, quotedMessage)
    }
}
