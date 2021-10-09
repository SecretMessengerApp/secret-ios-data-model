//
//

import Foundation

@testable import WireDataModel

class ZMConversationObservationHelperTests: NotificationDispatcherTestBase {
    
    
    func testThatOnCreatedRemotelyIsCalledWhenRemoteIdentifierIsModified() {
        // given
        let createdRemotely = expectation(description: "Created remotely")
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        uiMOC.saveOrRollback()
        
        // expect
        var token = conversation.onCreatedRemotely {
            createdRemotely.fulfill()
        }
        
        // when
        conversation.remoteIdentifier = UUID.create()
        uiMOC.saveOrRollback()
        XCTAssertNotNil(token)
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        token = nil
    }
    
    func testTHatOnCreatedRemotelyIsCalledIfConversationAlreadyHasRemoteIdentifier() {
        // given
        let createdRemotely = expectation(description: "Created remotely")
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID.create()
        uiMOC.saveOrRollback()
        
        // expect
        var token = conversation.onCreatedRemotely {
            createdRemotely.fulfill()
        }
        
        XCTAssertNil(token)
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        token = nil
    }
    
}
