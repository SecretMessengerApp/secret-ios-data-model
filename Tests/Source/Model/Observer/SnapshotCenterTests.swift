//
//

import Foundation
@testable import WireDataModel

class SnapshotCenterTests : BaseZMMessageTests {

    var sut: SnapshotCenter!
    
    override func setUp() {
        super.setUp()
        sut = SnapshotCenter(managedObjectContext: uiMOC)
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testThatItCreatesSnapshotsOfObjects(){
        // given
        let conv = ZMConversation.insertNewObject(in: uiMOC)
        
        // when
        _ = sut.extractChangedKeysFromSnapshot(for: conv)
        
        // then
        XCTAssertNotNil(sut.snapshots[conv.objectID])
    }
    
    func testThatItSnapshotsNilValues(){
        // given
        let conv = ZMConversation.insertNewObject(in: uiMOC)
        _ = sut.extractChangedKeysFromSnapshot(for: conv)
        
        // when
        guard let snapshot = sut.snapshots[conv.objectID] else { return XCTFail("did not create snapshot")}
        
        // then
        let expectedAttributes : [String : NSObject?] = ["userDefinedName": nil,
                                                           "internalEstimatedUnreadCount": 0 as Optional<NSObject>,
                                                           "hasUnreadUnsentMessage": 0 as Optional<NSObject>,
                                                           "archivedChangedTimestamp": nil,
                                                           "isSelfAnActiveMember": 1 as Optional<NSObject>,
                                                           "draftMessageText": nil,
                                                           "modifiedKeys": nil,
                                                           "securityLevel": 0 as Optional<NSObject>,
                                                           "lastServerTimeStamp": nil,
                                                           "localMessageDestructionTimeout": 0 as Optional<NSObject>,
                                                           "syncedMessageDestructionTimeout": 0 as Optional<NSObject>,
                                                           "clearedTimeStamp": nil,
                                                           "needsToBeUpdatedFromBackend": 0 as Optional<NSObject>,
                                                           "lastUnreadKnockDate": nil,
                                                           "conversationType": 0 as Optional<NSObject>,
                                                           "internalIsArchived": 0 as Optional<NSObject>,
                                                           "lastModifiedDate": nil,
                                                           "silencedChangedTimestamp": nil,
                                                           "lastUnreadMissedCallDate": nil,
                                                           "voiceChannel": nil,
                                                           "remoteIdentifier_data": nil,
                                                           "lastReadServerTimeStamp": nil,
                                                           "normalizedUserDefinedName": nil,
                                                           "remoteIdentifier": nil,
                                                           "mutedStatus": 0 as Optional<NSObject>]
        let expectedToManyRelationships = ["hiddenMessages": 0,
                                           "lastServerSyncedActiveParticipants": 0,
                                           "allMessages": 0,
                                           "labels": 0]
        
        expectedAttributes.forEach {
            XCTAssertEqual(snapshot.attributes[$0] ?? nil, $1)
        }
        XCTAssertEqual(snapshot.toManyRelationships, expectedToManyRelationships)
    }
    
    func testThatItSnapshotsSetValues(){
        // given
        let conv = ZMConversation.insertNewObject(in: uiMOC)
        conv.conversationType = .group
        conv.userDefinedName = "foo"
        performPretendingUiMocIsSyncMoc {
            conv.lastModifiedDate = Date()
            conv.lastServerTimeStamp = Date()
            conv.lastUnreadKnockDate = Date()
            conv.lastUnreadMissedCallDate = Date()
        }
        conv.mutedMessageTypes = .all
        conv.isSelfAnActiveMember = false
        conv.append(text: "foo")
        conv.resetLocallyModifiedKeys(conv.keysThatHaveLocalModifications)
        _ = sut.extractChangedKeysFromSnapshot(for: conv)
        
        // when
        guard let snapshot = sut.snapshots[conv.objectID] else { return XCTFail("did not create snapshot")}
        
        // then
        let expectedAttributes : [String : NSObject?] = ["userDefinedName": conv.userDefinedName as Optional<NSObject>,
                                                         "internalEstimatedUnreadCount": 0 as Optional<NSObject>,
                                                         "hasUnreadUnsentMessage": 0 as Optional<NSObject>,
                                                         "archivedChangedTimestamp": nil,
                                                         "isSelfAnActiveMember": 0 as Optional<NSObject>,
                                                         "draftMessageText": nil,
                                                         "modifiedKeys": nil,
                                                         "securityLevel": 0 as Optional<NSObject>,
                                                         "lastServerTimeStamp": conv.lastServerTimeStamp as Optional<NSObject>,
                                                         "localMessageDestructionTimeout": 0 as Optional<NSObject>,
                                                         "syncedMessageDestructionTimeout": 0 as Optional<NSObject>,
                                                         "clearedTimeStamp": nil,
                                                         "needsToBeUpdatedFromBackend": 0 as Optional<NSObject>,
                                                         "lastUnreadKnockDate": conv.lastUnreadKnockDate as Optional<NSObject>,
                                                         "conversationType": conv.conversationType.rawValue as Optional<NSObject>,
                                                         "internalIsArchived": 0 as Optional<NSObject>,
                                                         "lastModifiedDate": conv.lastModifiedDate as Optional<NSObject>,
                                                         "silencedChangedTimestamp": conv.silencedChangedTimestamp as Optional<NSObject>,
                                                         "lastUnreadMissedCallDate": conv.lastUnreadMissedCallDate as Optional<NSObject>,
                                                         "voiceChannel": nil,
                                                         "remoteIdentifier_data": nil,
                                                         "lastReadServerTimeStamp": conv.lastReadServerTimeStamp as Optional<NSObject>,
                                                         "normalizedUserDefinedName": conv.normalizedUserDefinedName as Optional<NSObject>,
                                                         "remoteIdentifier": nil,
                                                         "mutedStatus": (MutedMessageOptionValue.all.rawValue) as Optional<NSObject>]
        let expectedToManyRelationships = ["hiddenMessages": 0,
                                           "lastServerSyncedActiveParticipants": 0,
                                           "allMessages": 1,
                                           "labels": 0]
        
        let expectedToOneRelationships = ["team": false,
                                          "connection": false,
                                          "creator": false]
        
        expectedAttributes.forEach{
            XCTAssertEqual((snapshot.attributes[$0] ?? nil), $1, "values for \($0) don't match")
        }
        XCTAssertEqual(snapshot.toManyRelationships, expectedToManyRelationships)
        XCTAssertEqual(snapshot.toOneRelationships, expectedToOneRelationships)
    }
    
    func testThatReturnsChangedKeys() {
        // given
        let conv = ZMConversation.insertNewObject(in: uiMOC)
        _ = sut.extractChangedKeysFromSnapshot(for: conv)
        
        // when
        conv.userDefinedName = "foo"
        let changedKeys = sut.extractChangedKeysFromSnapshot(for: conv)

        // then
        XCTAssertEqual(changedKeys.count, 2)
        XCTAssertEqual(changedKeys, Set(["normalizedUserDefinedName", "userDefinedName"]))
    }
    
    func testThatItUpatesTheSnapshot(){
        // given
        let conv = ZMConversation.insertNewObject(in: uiMOC)
        _ = sut.extractChangedKeysFromSnapshot(for: conv)
        
        // when
        conv.userDefinedName = "foo"
        _ = sut.extractChangedKeysFromSnapshot(for: conv)
        
        // then
        guard let snapshot = sut.snapshots[conv.objectID] else { return XCTFail("did not create snapshot")}
        
        // then
        XCTAssertEqual(snapshot.attributes["userDefinedName"] as? String, "foo")
    }
    
    func testThatItReturnsAllKeysChangedWhenSnapshotDoesNotExist(){
        // given
        let conv = ZMConversation.insertNewObject(in: uiMOC)

        // when
        let changedKeys = sut.extractChangedKeysFromSnapshot(for: conv)

        // then
        XCTAssertEqual(changedKeys, Set(conv.entity.attributesByName.keys).union(["hiddenMessages",
                                                                                  "lastServerSyncedActiveParticipants",
                                                                                  "allMessages",
                                                                                  "labels"]))
    }

}

