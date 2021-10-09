//
//

import Foundation
import XCTest
@testable import WireDataModel

class ZMManagedObjectGroupingTests: DatabaseBaseTest {

    var mocs: ManagedObjectContextDirectory!
    
    public override func setUp() {
        super.setUp()
        self.mocs = self.createStorageStackAndWaitForCompletion()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 1))
    }
    
    public override func tearDown() {
        self.mocs = nil
        super.tearDown()
    }
    
    public func testThatItFindsNoDuplicates_None() {
        // WHEN
        let duplicates: [String: [UserClient]] = self.mocs.uiContext.findDuplicated(by: #keyPath(UserClient.remoteIdentifier))
        
        // THEN
        XCTAssertEqual(duplicates.keys.count, 0)
    }

    public func testThatItFindsNoDuplicates_One() {
        // GIVEN
        let remoteIdentifier = UUID().transportString()
        
        let client = UserClient.insertNewObject(in: self.mocs.uiContext)
        client.remoteIdentifier = remoteIdentifier
        
        self.mocs.uiContext.saveOrRollback()
        
        // WHEN
        let duplicates: [String: [UserClient]] = self.mocs.uiContext.findDuplicated(by: #keyPath(UserClient.remoteIdentifier))
        
        // THEN
        XCTAssertEqual(duplicates.keys.count, 0)
    }

    public func testThatItFindsDuplicates_ManyCommon() {
        // GIVEN
        let remoteIdentifier = UUID().transportString()
        
        for _ in 1...10 {
            let client = UserClient.insertNewObject(in: self.mocs.uiContext)
            client.remoteIdentifier = remoteIdentifier
        }
        
        self.mocs.uiContext.saveOrRollback()
        
        // WHEN
        let duplicates: [String: [UserClient]] = self.mocs.uiContext.findDuplicated(by: #keyPath(UserClient.remoteIdentifier))
        
        // THEN
        XCTAssertEqual(duplicates.keys.count, 1)
        XCTAssertEqual(duplicates[remoteIdentifier]?.count, 10)
    }
    
    public func testThatItGroupsByPropertyValue_One() {
        // GIVEN
        let client = UserClient.insertNewObject(in: self.mocs.uiContext)
        client.remoteIdentifier = UUID().transportString()
        client.user = ZMUser.insert(in: self.mocs.uiContext, name: "User")
        
        // WHEN
        let grouped: [ZMUser: [UserClient]] = [client].group(by: ZMUserClientUserKey)
        
        // THEN
        XCTAssertEqual(grouped.keys.count, 1)
        for key in grouped.keys {
            XCTAssertEqual(grouped[key]!.count, 1)
        }
    }

    public func testThatItGroupsByPropertyValue_Many() {
        // GIVEN
        let range = 1...10
        let user = ZMUser.insert(in: self.mocs.uiContext, name: "User")
        let clients: [UserClient] = range.map { _ in
            let client = UserClient.insertNewObject(in: self.mocs.uiContext)
            client.remoteIdentifier = UUID().transportString()
            client.user = user
            return client
        }
        
        // WHEN
        let grouped: [ZMUser: [UserClient]] = clients.group(by: ZMUserClientUserKey)
        
        // THEN
        XCTAssertEqual(grouped.keys.count, 1)
        XCTAssertEqual(grouped.keys.first, user)
        for key in grouped.keys {
            XCTAssertEqual(grouped[key]!.count, 10)
        }
    }

    public func testThatItGroupsByPropertyValue_ManyDistinct() {
        // GIVEN
        let range = 1...10
        let clients: [UserClient] = range.map {
            let client = UserClient.insertNewObject(in: self.mocs.uiContext)
            client.remoteIdentifier = UUID().transportString()
            client.user = ZMUser.insert(in: self.mocs.uiContext, name: "User \($0)")
            return client
        }
        
        // WHEN
        let grouped: [ZMUser: [UserClient]] = clients.group(by: ZMUserClientUserKey)
        
        // THEN
        XCTAssertEqual(grouped.keys.count, 10)
        for key in grouped.keys {
            XCTAssertEqual(grouped[key]!.count, 1)
        }
    }
    
    public func testThatItIgnoresNil() {
        // GIVEN
        let range = 1...10
        let clients: [UserClient] = range.map { _ in
            let client = UserClient.insertNewObject(in: self.mocs.uiContext)
            client.remoteIdentifier = UUID().transportString()
            client.user = nil
            return client
        }
        
        // WHEN
        let grouped: [ZMUser: [UserClient]] = clients.group(by: ZMUserClientUserKey)
        
        // THEN
        XCTAssertEqual(grouped.keys.count, 0)
    }
}

public final class ZMManagedObjectGroupingTestsInMemory: ZMBaseManagedObjectTest {
    func testThatItErrorsOnInMemoryStore() throws {
        // GIVEN && WHEN
        self.performIgnoringZMLogError {
            let _: [String: [UserClient]] = self.uiMOC.findDuplicated(by: #keyPath(UserClient.remoteIdentifier))
        }
        // THEN
        // test did not fail
    }
}
