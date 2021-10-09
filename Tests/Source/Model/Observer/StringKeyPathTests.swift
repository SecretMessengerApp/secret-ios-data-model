// 
// 


import Foundation

class StringKeyPathTests: ZMBaseManagedObjectTest {

    func testThatItCreatesASimpleKeyPath() {
        let sut = StringKeyPath.keyPathForString("name")
        XCTAssertEqual(sut.rawValue, "name")
        XCTAssertEqual(sut.count, 1)
        XCTAssertFalse(sut.isPath)
    }

    func testThatItCreatesKeyPathThatIsAPath() {
        let sut = StringKeyPath.keyPathForString("foo.name")
        XCTAssertEqual(sut.rawValue, "foo.name")
        XCTAssertEqual(sut.count, 2)
        XCTAssertTrue(sut.isPath)
    }
    
    func testThatItDecomposesSimpleKeys() {
        let sut = StringKeyPath.keyPathForString("name")
        if let (a, b) = sut.decompose {
            XCTAssertEqual(a, StringKeyPath.keyPathForString("name"))
            XCTAssertEqual(b, nil)
        } else {
            XCTFail("Did not decompose")
        }
    }
    
    func testThatItDecomposesKeyPaths() {
        let sut = StringKeyPath.keyPathForString("foo.name")
        if let (a, b) = sut.decompose {
            XCTAssertEqual(a, StringKeyPath.keyPathForString("foo"))
            XCTAssertEqual(b, StringKeyPath.keyPathForString("name"))
        } else {
            XCTFail("Did not decompose")
        }
    }
}
