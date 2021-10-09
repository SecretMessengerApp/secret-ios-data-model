//
// 


import CoreData
@testable import WireDataModel

class ZMCallStateTests : ZMBaseManagedObjectTest {
    
    func testThatItReturnsTheSameStateForTheSameConversation() {
        // given
        let sut = ZMCallState()
        let conversationA = ZMConversation.insertNewObject(in: uiMOC)
        let conversationB = ZMConversation.insertNewObject(in: uiMOC)
        uiMOC.saveOrRollback()
        
        // when
        let a1 = sut.stateForConversation(conversationA)
        let a2 = sut.stateForConversation(conversationA)
        let b1 = sut.stateForConversation(conversationB)
        let b2 = sut.stateForConversation(conversationB)
        
        // then
        XCTAssertTrue(a1 === a2)
        XCTAssertTrue(b1 === b2)

        XCTAssertFalse(a1 === b1)
        XCTAssertFalse(a2 === b2)
    }
    
}

// V3 Group calling

extension ZMCallStateTests {
    
    func testThatItDoesMergeIsCallDeviceActive() {
        // given
        let mainSut = ZMConversationCallState()
        let syncSut = ZMConversationCallState()
        syncSut.isCallDeviceActive = false
        mainSut.isCallDeviceActive = true
        
        // when
        syncSut.mergeChangesFromState(mainSut)
        
        // then
        XCTAssertTrue(mainSut.isCallDeviceActive)
        XCTAssertTrue(syncSut.isCallDeviceActive)
    }
    
    func testThatItDoesMergeIsIgnoringCall() {
        // given
        let mainSut = ZMConversationCallState()
        let syncSut = ZMConversationCallState()
        syncSut.isIgnoringCall = false
        mainSut.isIgnoringCall = true
        
        // when
        syncSut.mergeChangesFromState(mainSut)
        
        // then
        XCTAssertTrue(mainSut.isIgnoringCall)
        XCTAssertTrue(syncSut.isIgnoringCall)
    }
}
