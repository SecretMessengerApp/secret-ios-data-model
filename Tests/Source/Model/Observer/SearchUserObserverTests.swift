//
//


import Foundation
@testable import WireDataModel

class SearchUserObserverTests : NotificationDispatcherTestBase, ZMManagedObjectContextProvider {
    
    class TestSearchUserObserver : NSObject, ZMUserObserver {
        
        var receivedChangeInfo : [UserChangeInfo] = []
        
        func userDidChange(_ changeInfo: UserChangeInfo) {
            receivedChangeInfo.append(changeInfo)
        }
    }
    
    var managedObjectContext: NSManagedObjectContext! {
        return uiMOC
    }
    
    var syncManagedObjectContext: NSManagedObjectContext! {
        return syncMOC
    }
    
    var testObserver : TestSearchUserObserver!
    
    override func setUp() {
        super.setUp()
        testObserver = TestSearchUserObserver()
    }
    
    override func tearDown() {
        testObserver = nil
        uiMOC.searchUserObserverCenter.reset()
        super.tearDown()
    }
    
    func testThatItNotifiesTheObserverOfASmallProfilePictureChange() {
        
        // given
        let remoteID = UUID.create()
        let searchUser = ZMSearchUser(contextProvider: self, name: "Hans", handle: "hans", accentColor: .brightOrange, remoteIdentifier: remoteID)
        
        uiMOC.searchUserObserverCenter.addSearchUser(searchUser)
        self.token = UserChangeInfo.add(observer: testObserver, for: searchUser, managedObjectContext: self.uiMOC)
        
        // when
        searchUser.updateImageData(for: .preview, imageData: verySmallJPEGData())
        
        // then
        XCTAssertEqual(testObserver.receivedChangeInfo.count, 1)
        if let note = testObserver.receivedChangeInfo.first {
            XCTAssertTrue(note.imageSmallProfileDataChanged)
        }
    }
    
    func testThatItNotifiesTheObserverOfASmallProfilePictureChangeIfTheInternalUserUpdates() {
        
        // given
        let user = ZMUser.insertNewObject(in:self.uiMOC)
        user.remoteIdentifier = UUID.create()
        self.uiMOC.saveOrRollback()
        let searchUser = ZMSearchUser(contextProvider: self, name: "", handle: nil, accentColor: .brightYellow, remoteIdentifier: nil, user: user)
        
        uiMOC.searchUserObserverCenter.addSearchUser(searchUser)
        self.token = UserChangeInfo.add(observer: testObserver, for:searchUser, managedObjectContext: self.uiMOC)
        
        // when
        user.previewProfileAssetIdentifier = UUID.create().transportString()
        user.setImage(data: verySmallJPEGData(), size: .preview)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5)) 
        
        // then
        XCTAssertEqual(testObserver.receivedChangeInfo.count, 1)
        if let note = testObserver.receivedChangeInfo.first {
            XCTAssertTrue(note.imageSmallProfileDataChanged)
        }
    }
    
    func testThatItStopsNotifyingAfterUnregisteringTheToken() {
        
        // given
        let remoteID = UUID.create()
        let searchUser = ZMSearchUser(contextProvider: self, name: "Hans", handle: "hans", accentColor: .brightOrange, remoteIdentifier: remoteID)
        
        uiMOC.searchUserObserverCenter.addSearchUser(searchUser)
        self.token = UserChangeInfo.add(observer: testObserver, for: searchUser, managedObjectContext: self.uiMOC)
        
        // when
        self.token = nil
        searchUser.updateImageData(for: .preview, imageData: verySmallJPEGData())
        
        // then
        XCTAssertEqual(testObserver.receivedChangeInfo.count, 0)
    }
    
    func testThatItNotifiesObserversWhenConnectingToASearchUserThatHasNoLocalUser(){
    
        // given
        let remoteID = UUID.create()
        let searchUser = ZMSearchUser(contextProvider: self, name: "Hans", handle: "hans", accentColor: .brightOrange, remoteIdentifier: remoteID)
        
        XCTAssertFalse(searchUser.isPendingApprovalByOtherUser)
        uiMOC.searchUserObserverCenter.addSearchUser(searchUser)
        self.token = UserChangeInfo.add(observer: testObserver, for: searchUser, managedObjectContext: self.uiMOC)

        // when
        searchUser.connect(message: "Hey")
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        XCTAssertEqual(testObserver.receivedChangeInfo.count, 1)
        guard let note = testObserver.receivedChangeInfo.first else { return XCTFail()}
        XCTAssertEqual(note.user as? ZMSearchUser, searchUser)
        XCTAssertTrue(note.connectionStateChanged)
    }
 
    func testThatItNotifiesObserverWhenConnectingToALocalUser() {
    
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.remoteIdentifier = UUID()
        XCTAssert(uiMOC.saveOrRollback())

        let searchUser = ZMSearchUser(contextProvider: self, name: "Hans", handle: "hans", accentColor: .brightOrange, remoteIdentifier: nil, user: user)
        
        let testObserver2 = TestSearchUserObserver()
        var tokens: [AnyObject] = []
        self.token = tokens
        tokens.append(UserChangeInfo.add(observer: testObserver, for: user, managedObjectContext: self.uiMOC)!)
        
        uiMOC.searchUserObserverCenter.addSearchUser(searchUser)
        tokens.append(UserChangeInfo.add(observer: testObserver2, for: searchUser, managedObjectContext: self.uiMOC)!)
        
        // when
        searchUser.connect(message: "Hey")
        XCTAssert(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // when
        XCTAssertTrue(searchUser.user!.isPendingApprovalByOtherUser)
        XCTAssertEqual(testObserver.receivedChangeInfo.count, 1)
        XCTAssertEqual(testObserver2.receivedChangeInfo.count, 1)
        
        if let note1 = testObserver.receivedChangeInfo.first {
            XCTAssertEqual(note1.user as? ZMUser, user)
            XCTAssertTrue(note1.connectionStateChanged)
        } else {
            XCTFail("Did not receive UserChangeInfo for ZMUser")
        }

        if let note2 = testObserver2.receivedChangeInfo.first {
            XCTAssertEqual(note2.user as? ZMSearchUser, searchUser)
            XCTAssertTrue(note2.connectionStateChanged)
        } else {
            XCTFail("Did not receive UserChangeInfo for ZMSearchUser")
        }
    }
}
