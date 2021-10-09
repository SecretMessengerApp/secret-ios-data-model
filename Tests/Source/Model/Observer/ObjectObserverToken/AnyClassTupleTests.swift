// 
// 


import Foundation
import XCTest

class AnyClassTupleTests: ZMBaseManagedObjectTest {

    func testThatTwoTuplesAreEqual() {
        
        // given
        let classOfObject : AnyClass = AnyClassTupleTests.self
        let tuple1 = AnyClassTuple<String>(classOfObject: classOfObject, secondElement: "Foo")
        let tuple2 = AnyClassTuple<String>(classOfObject: classOfObject, secondElement: "Foo")
        
        // then
        XCTAssertEqual(tuple1, tuple2)
        
    }

    func testThatTwoTuplesHaveTheSameHash() {
        
        // given
        let classOfObject : AnyClass = AnyClassTupleTests.self
        let tuple1 = AnyClassTuple<String>(classOfObject: classOfObject, secondElement: "Foo")
        let tuple2 = AnyClassTuple<String>(classOfObject: classOfObject, secondElement: "Foo")
        
        // then
        XCTAssertEqual(tuple1.hashValue, tuple2.hashValue)
        
    }

    func testThatTwoTuplesAreNotEqualOnString() {
        
        // given
        let classOfObject : AnyClass = AnyClassTupleTests.self
        let tuple1 = AnyClassTuple<String>(classOfObject: classOfObject, secondElement: "Foo")
        let tuple2 = AnyClassTuple<String>(classOfObject: classOfObject, secondElement: "Bar")
        
        // then
        XCTAssertNotEqual(tuple1, tuple2)
        
    }
    
    func testThatTwoTuplesDoNotHaveTheSameHashOnString() {
        
        // given
        let classOfObject : AnyClass = AnyClassTupleTests.self
        let tuple1 = AnyClassTuple<String>(classOfObject: classOfObject, secondElement: "Foo")
        let tuple2 = AnyClassTuple<String>(classOfObject: classOfObject, secondElement: "Bar")
        
        // then
        XCTAssertNotEqual(tuple1.hashValue, tuple2.hashValue)
        
    }
    
    func testThatTwoTuplesAreNotEqualOnClass() {
        
        // given
        let classOfObject : AnyClass = AnyClassTupleTests.self
        let tuple1 = AnyClassTuple<String>(classOfObject: classOfObject, secondElement: "Foo")
        let tuple2 = AnyClassTuple<String>(classOfObject: NSArray.self, secondElement: "Foo")
        
        // then
        XCTAssertNotEqual(tuple1, tuple2)
        
    }
    
    func testThatTwoTuplesDoNotHaveTheSameHashOnClass() {
        
        // given
        let classOfObject : AnyClass = AnyClassTupleTests.self
        let tuple1 = AnyClassTuple<String>(classOfObject: classOfObject, secondElement: "Foo")
        let tuple2 = AnyClassTuple<String>(classOfObject: NSArray.self, secondElement: "Foo")
        
        // then
        XCTAssertNotEqual(tuple1.hashValue, tuple2.hashValue)
        
    }
}
