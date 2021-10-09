//
//

import Foundation
@testable import WireDataModel

class ZMUserFetchAndMergeTests: ModelObjectsTests {
    func testThatItMergesDuplicatesWhenFetching() {
        self.syncMOC.performGroupedBlockAndWait {
            // Given
            let remoteIdentifier = UUID()

            let user1 = ZMUser.insert(in: self.syncMOC, name: "one")
            user1.remoteIdentifier = remoteIdentifier
            let user2 = ZMUser.insert(in: self.syncMOC, name: "two")
            user2.remoteIdentifier = remoteIdentifier
            self.syncMOC.saveOrRollback()

            let beforeMerge = ZMUser.fetchAll(with: remoteIdentifier, in: self.syncMOC)
            XCTAssertEqual(beforeMerge.count, 2)

            // when
            let user = ZMUser.fetchAndMerge(with: remoteIdentifier, createIfNeeded: false, in: self.syncMOC)

            // then
            XCTAssertNotNil(user)
            XCTAssertEqual(user?.remoteIdentifier, remoteIdentifier)

            let afterMerge = ZMUser.fetchAll(with: remoteIdentifier, in: self.syncMOC)
            XCTAssertEqual(afterMerge.count, 1)
            XCTAssertEqual(user, afterMerge.first)
        }

    }

}
