//
//

import XCTest
@testable import WireDataModel

class ZMMovedIndexTests: XCTestCase {
    func testThatItGeneratesAHash() {
        // GIVEN
        let index = ZMMovedIndex(from: 0, to: 0)
        // WHEN
        let hash = index.hash
        // THEN
        XCTAssertEqual(hash, 0)
    }
    
    func testThatItGeneratesSameHashForSameObject() {
        // GIVEN
        let index = ZMMovedIndex(from: 10, to: 7)
        let index2 = ZMMovedIndex(from: 10, to: 7)
        // WHEN & THEN
        XCTAssertEqual(index.hash, index2.hash)
    }
    
    func testThatItGeneratesDistinctHash() {
        // GIVEN
        let index = ZMMovedIndex(from: 10, to: 7)
        let index2 = ZMMovedIndex(from: 7, to: 10)
        // WHEN & THEN
        XCTAssertNotEqual(index.hash, index2.hash)
    }
}
