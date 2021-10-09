//
//


import Foundation
import XCTest

@testable import WireDataModel

class MentionTests: ZMBaseManagedObjectTest {
    
    func createMention(start: Int = 0, length: Int = 1, userId: String = UUID().transportString()) -> ZMMention {
        // Make user mentioned user exists
        if let remoteIdentifier = UUID(uuidString: userId) {
            let user = ZMUser.insertNewObject(in: uiMOC)
            user.remoteIdentifier = remoteIdentifier
        }
        
        let builder = ZMMentionBuilder()
        
        builder.setStart(Int32(start))
        builder.setLength(Int32(length))
        builder.setUserId(userId)
        
        return builder.build()
    }
    
    func testConstructionOfValidMention() {
        // given
        let buffer = createMention()
        
        // when
        let mention = Mention(buffer, context: uiMOC)
        
        // then
        XCTAssertNotNil(mention)
    }
    
    func testConstructionOfInvalidMentionRangeCase1() {
        // given
        let buffer = createMention(start: 5, length: 0)
        
        // when
        let mention = Mention(buffer, context: uiMOC)
        
        // then
        XCTAssertNil(mention)
    }
    
    func testConstructionOfInvalidMentionRangeCase2() {
        // given
        let buffer = createMention(start: 1, length: 0)
        
        // when
        let mention = Mention(buffer, context: uiMOC)
        
        // then
        XCTAssertNil(mention)
    }
    
    func testConstructionOfInvalidMentionRangeCase3() {
        // given
        let buffer = createMention(start: -1, length: 1)
        
        // when
        let mention = Mention(buffer, context: uiMOC)
        
        // then
        XCTAssertNil(mention)
    }
    
    func testConstructionOfInvalidMentionRangeCase4() {
        // given
        let buffer = createMention(start: 1, length: -1)
        
        // when
        let mention = Mention(buffer, context: uiMOC)
        
        // then
        XCTAssertNil(mention)
    }
    
    func testConstructionOfInvalidMentionUserId() {
        // given
        let buffer = createMention(userId: "not-a-valid-uuid")
        
        // when
        let mention = Mention(buffer, context: uiMOC)
        
        // then
        XCTAssertNil(mention)
    }
    
}
