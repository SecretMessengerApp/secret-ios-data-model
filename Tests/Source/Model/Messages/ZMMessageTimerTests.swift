//
//

import XCTest
@testable import WireDataModel
import WireTransport

class ZMMessageTimerTests: BaseZMMessageTests {
    
    var sut: ZMMessageTimer!
    
    override func setUp() {
        super.setUp()
        sut = ZMMessageTimer(managedObjectContext: uiMOC)!
    }
    
    override func tearDown() {
        sut.tearDown()
        sut = nil
        super.tearDown()
    }
    
    func testThatItDoesNotCreateBackgroundActivityWhenTimerStarted() {
        // given
        XCTAssertFalse(BackgroundActivityFactory.shared.isActive)
        let message = createClientTextMessage(withText: "hello")
        
        // when
        sut.start(forMessageIfNeeded: message, fire: Date(timeIntervalSinceNow: 1.0), userInfo: [:])
        
        // then
        let timer = sut.timer(for: message)
        XCTAssertNotNil(timer)
        
        XCTAssertFalse(BackgroundActivityFactory.shared.isActive)
    }
    
    func testThatItRemovesTheInternalTimerAfterTimerFired() {
        // given
        let message = createClientTextMessage(withText: "hello")
        let expectation = self.expectation(description: "timer fired")
        sut.timerCompletionBlock = { _, _ in expectation.fulfill() }
        
        // when
        sut.start(forMessageIfNeeded: message, fire: Date(), userInfo: [:])
        _ = waitForCustomExpectations(withTimeout: 0.5)
        
        // then
        XCTAssertNil(sut.timer(for: message))
    }

    func testThatItRemovesTheInternalTimerWhenTimerStopped() {
        // given
        let message = createClientTextMessage(withText: "hello")
        sut.start(forMessageIfNeeded: message, fire: Date(), userInfo: [:])
        
        // when
        sut.stop(for: message)
        
        // then
        XCTAssertNil(sut.timer(for: message))
    }
}
