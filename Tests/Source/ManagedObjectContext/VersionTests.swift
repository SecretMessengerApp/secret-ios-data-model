//
//

final class VersionTests: XCTestCase {
  
    func testThatItComparesCorrectly() {
        let version1 = Version(string: "0.1")
        let version2 = Version(string: "1.0")
        let version3 = Version(string: "1.0")
        let version4 = Version(string: "1.0.1")
        let version5 = Version(string: "1.1")
        
        XCTAssertLessThan(version1, version2)
        XCTAssertLessThan(version1, version3)
        XCTAssertLessThan(version1, version4)
        XCTAssertLessThan(version1, version5)
        
        XCTAssertGreaterThan(version2, version1)
        XCTAssertEqual(version2, version3)
        XCTAssertEqual(version2.compare(with: version3), .orderedSame)
        XCTAssertLessThan(version2, version4)
        XCTAssertLessThan(version2, version5)
        
        XCTAssertGreaterThan(version3, version1)
        XCTAssertEqual(version3, version2)
        XCTAssertEqual(version3.compare(with: version2), .orderedSame)
        XCTAssertLessThan(version3, version4)
        XCTAssertLessThan(version3, version5)
        
        XCTAssertGreaterThan(version4, version1)
        XCTAssertGreaterThan(version4, version2)
        XCTAssertGreaterThan(version4, version3)
        XCTAssertLessThan(version4, version5)
        
        XCTAssertGreaterThan(version5, version1)
        XCTAssertGreaterThan(version5, version2)
        XCTAssertGreaterThan(version5, version3)
        XCTAssertGreaterThan(version5, version4)
    }
    
}
