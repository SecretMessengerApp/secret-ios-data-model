//
//


import Foundation


class ManagedObjectContextChangeObserverTests : ZMBaseManagedObjectTest {


    func testThatItCallsTheCallbackWhenObjectsAreInserted() {
        // given
        let changeExpectation = expectation(description: "The callback should be called")
        let sut = ManagedObjectContextChangeObserver(context: uiMOC) {
            changeExpectation.fulfill()
        }

        // when
        uiMOC.perform {
            _ = ZMMessage(nonce: UUID(), managedObjectContext: self.uiMOC)
        }

        // then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.1))
        _ = sut
    }

    func testThatItCallsTheCallbackWhenObjectsAreDeleted() {
        // given
        let message = ZMMessage(nonce: UUID(), managedObjectContext: uiMOC)
        XCTAssert(uiMOC.saveOrRollback())

        let changeExpectation = expectation(description: "The callback should be called")
        let sut = ManagedObjectContextChangeObserver(context: uiMOC) {
            changeExpectation.fulfill()
        }

        // when
        uiMOC.perform {
            self.uiMOC.delete(message)
        }

        // then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.1))
        _ = sut
    }

    func testThatItCallsTheCallbackWhenObjectsAreUpdated() {
        // given
        let message = ZMMessage(nonce: UUID(), managedObjectContext: uiMOC)
        XCTAssert(uiMOC.saveOrRollback())

        let changeExpectation = expectation(description: "The callback should be called")
        let sut = ManagedObjectContextChangeObserver(context: uiMOC) {
            changeExpectation.fulfill()
        }

        // when
        uiMOC.perform {
            message.markAsSent()
        }

        // then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.1))
        _ = sut
    }

    func testThatItRemovesItselfAsObserverWhenReleased() {
        // given
        var called = false
        var sut: ManagedObjectContextChangeObserver? = ManagedObjectContextChangeObserver(context: uiMOC) {
            called = true
        }

        // when
        _ = sut
        sut = nil
        uiMOC.perform {
            _ = ZMMessage(nonce: UUID(), managedObjectContext: self.uiMOC)
        }

        // then
        spinMainQueue(withTimeout: 0.05)
        XCTAssertFalse(called)
    }

}
