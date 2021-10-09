//
//

import Foundation
@testable import WireDataModel


class ZMConversationPrepareToSendTests : ZMConversationTestsBase {
    
    func testThatMessagesAddedToDegradedConversationAreExpiredAndFlaggedAsCauseDegradation() {
        // GIVEN
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.securityLevel = .secureWithIgnored
        
        // WHEN
        let message = conversation.append(text: "Foo") as! ZMMessage
        self.uiMOC.saveOrRollback()
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            let message = self.syncMOC.object(with: message.objectID) as! ZMMessage
            XCTAssertTrue(message.isExpired)
            XCTAssertTrue(message.causedSecurityLevelDegradation)
        }
    }
    
    func testThatMessagesResentToDegradedConversationAreExpiredAndFlaggedAsCauseDegradation() {
        // GIVEN
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.securityLevel = .secure
        let message = conversation.append(text: "Foo") as! ZMMessage
        message.expire()
        self.uiMOC.saveOrRollback()

        // WHEN
        conversation.securityLevel = .secureWithIgnored
        message.resend()
        self.uiMOC.saveOrRollback()

        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            let message = self.syncMOC.object(with: message.objectID) as! ZMMessage
            XCTAssertTrue(message.isExpired)
            XCTAssertTrue(message.causedSecurityLevelDegradation)
        }
    }

}
