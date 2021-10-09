//
//


import Foundation



class NSManagedObjectContextDebuggingTests : ZMBaseManagedObjectTest {

    func testThatItInvokesCallbackWhenFailedToSave() {
        
        // GIVEN
        self.makeChangeThatWillCauseRollback()
        let expectation = self.expectation(description: "callback invoked")
        self.uiMOC.errorOnSaveCallback = { (moc, error) in
            XCTAssertEqual(moc, self.uiMOC)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        
        // WHEN
        self.performIgnoringZMLogError {
            self.uiMOC.saveOrRollback()
        }
        
        // THEN
        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
    }
}

// MARK: - Helper

private let longString = (0..<50).reduce("") { (prev, next) -> String in
    return prev + "AaAaAaAaAa"
}

extension NSManagedObjectContextDebuggingTests {
    
    func makeChangeThatWillCauseRollback() {
        let user = ZMUser.selfUser(in: self.uiMOC)
        // this user name is too long and will fail validation
        user.name = longString
    }
}
