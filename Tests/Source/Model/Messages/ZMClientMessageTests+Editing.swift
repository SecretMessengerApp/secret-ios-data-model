//
//

import XCTest

class ZMClientMessageTests_TextMessageData : BaseZMClientMessageTests {
    
    func testThatItUpdatesTheMesssageText_WhenEditing(){
        
        // given
        let conversation = ZMConversation.insertNewObject(in:uiMOC)
        conversation.remoteIdentifier = UUID.create()
        
        let message = conversation.append(text: "hello") as! ZMClientMessage
        message.delivered = true
        
        // when
        message.textMessageData?.editText("good bye", mentions: [], fetchLinkPreview: false)
        
        // then
        XCTAssertEqual(message.textMessageData?.messageText, "good bye")
    }
    
    func testThatItClearReactions_WhenEditing(){
        
        // given
        let conversation = ZMConversation.insertNewObject(in:uiMOC)
        conversation.remoteIdentifier = UUID.create()
        
        let message = conversation.append(text: "hello") as! ZMClientMessage
        message.delivered = true
        message.addReaction("🤠", forUser: selfUser)
        XCTAssertFalse(message.reactions.isEmpty)
        
        // when
        message.textMessageData?.editText("good bye", mentions: [], fetchLinkPreview: false)
        
        // then
        XCTAssertTrue(message.reactions.isEmpty)
    }
    
    func testThatItKeepsQuote_WhenEditing(){
        
        // given
        let conversation = ZMConversation.insertNewObject(in:uiMOC)
        conversation.remoteIdentifier = UUID.create()
        
        let quotedMessage = conversation.append(text: "Let's grab some lunch") as! ZMClientMessage
        let message = conversation.append(text: "Yes!", replyingTo: quotedMessage) as! ZMClientMessage
        message.delivered = true
        XCTAssertTrue(message.hasQuote)
        
        // when
        message.textMessageData?.editText("good bye", mentions: [], fetchLinkPreview: false)
        
        // then
        XCTAssertTrue(message.hasQuote)
    }
    
}
