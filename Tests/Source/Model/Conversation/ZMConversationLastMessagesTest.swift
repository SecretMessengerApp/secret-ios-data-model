//
//


import Foundation
import XCTest
import WireTesting
@testable import WireDataModel

public class ZMConversationLastMessagesTest: ZMBaseManagedObjectTest {

    func createConversation(on moc: NSManagedObjectContext? = nil) -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: moc ?? uiMOC)
        conversation.remoteIdentifier = UUID()
        conversation.conversationType = .group
        return conversation
    }
    
    func testThatItFetchesLastMessage() throws {
        // GIVEN
        let conversation = createConversation()
        
        // WHEN
        (0...40).forEach { i in
            conversation.append(text: "\(i)")
        }
        
        // THEN
        XCTAssertEqual(conversation.lastMessage?.textMessageData?.messageText, "40")
    }
    
    func testThatItFetchesLastMessagesWithLimit() throws {
        // GIVEN
        let conversation = createConversation()
        
        // WHEN
        (0...40).forEach { i in
            conversation.append(text: "\(i)")
        }
        
        // THEN
        let lastMessages = conversation.lastMessages(limit: 10)
        XCTAssertEqual(lastMessages.count, 10)
        XCTAssertEqual(lastMessages.last?.textMessageData?.messageText, "31")
        XCTAssertEqual(lastMessages.first?.textMessageData?.messageText, "40")
    }

    func testThatItFetchesLastMessages() throws {
        // GIVEN
        let conversation = createConversation()

        // WHEN
        (0...40).forEach { i in
            conversation.append(text: "\(i)")
        }

        // THEN
        let lastMessages = conversation.lastMessages()
        XCTAssertEqual(lastMessages.count, 41)
        XCTAssertEqual(lastMessages.last?.textMessageData?.messageText, "0")
        XCTAssertEqual(lastMessages.first?.textMessageData?.messageText, "40")
    }

    func testThatItDoesNotIncludeMessagesFromOtherConversations() {
        // GIVEN
        let conversation = createConversation()
        let otherConversation = createConversation()

        // WHEN
        (1...10).forEach { i in
            conversation.append(text: "\(i)")
        }

        (1...10).forEach { i in
            otherConversation.append(text: "Other \(i)")
        }

        // THEN
        let lastMessages = conversation.lastMessages()
        XCTAssertEqual(lastMessages.count, 10)
        XCTAssertEqual(lastMessages.last?.textMessageData?.messageText, "1")

        let otherLastMessages = otherConversation.lastMessages()
        XCTAssertEqual(otherLastMessages.last?.textMessageData?.messageText, "Other 1")

    }
    
}
