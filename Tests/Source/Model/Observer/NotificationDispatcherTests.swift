//
//

import Foundation
@testable import WireDataModel



extension ObjectChangeInfo {

    func checkForExpectedChangeFields(userInfoKeys: Set<String>, expectedChangedFields: Set<String>, file: StaticString = #file, line: UInt = #line){
        guard userInfoKeys.isSuperset(of: expectedChangedFields) else {
            return XCTFail("Expected change fields \(expectedChangedFields) not in userInfoKeys \(userInfoKeys). Please add them to the list.", file: file, line: line)
        }

        for key in userInfoKeys {
            guard let value = value(forKey: key) as? NSNumber else {
                return XCTFail("Can't find key or key is not boolean for '\(key)'", file: file, line: line)
            }
            if expectedChangedFields.contains(key) {
                XCTAssertTrue(value.boolValue, "\(key) was supposed to be true", file: file, line: line)
            } else {
                XCTAssertFalse(value.boolValue, "\(key) was supposed to be false", file: file, line: line)
            }
        }
    }
}

@objcMembers public class NotificationDispatcherTestBase : ZMBaseManagedObjectTest {

    var dispatcher : NotificationDispatcher! {
        return sut
    }
    var sut : NotificationDispatcher!
    var conversationObserver : ConversationObserver!
    var mergeNotifications = [Notification]()
    
    /// Holds a reference to the observer token, so that we don't release it during the test
    var token: Any? = nil

    
    override public func setUp() {
        super.setUp()
        conversationObserver = ConversationObserver()
        sut = NotificationDispatcher(managedObjectContext: uiMOC)
        NotificationCenter.default.addObserver(self, selector: #selector(NotificationDispatcherTestBase.contextDidMerge(_:)), name: Notification.Name.NSManagedObjectContextDidSave, object: syncMOC)
        mergeNotifications = []
    }
    
    override public func tearDown() {
        NotificationCenter.default.removeObserver(self)
        self.sut.tearDown()
        self.sut = nil
        self.conversationObserver = nil
        self.mergeNotifications = []
        self.token = nil
        super.tearDown()
    }
    
    @objc public func contextDidMerge(_ note: Notification) {
        mergeNotifications.append(note)
    }
    
    @objc public func mergeLastChanges() {
        let changedObjects =  mergeLastChangesWithoutNotifying()
        self.dispatcher.didMergeChanges(Set(changedObjects))
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

    }
    @objc @discardableResult public func mergeLastChangesWithoutNotifying() -> [NSManagedObjectID] {
        guard let change = mergeNotifications.last else { return [] }
        let changedObjects = (change.userInfo?[NSUpdatedObjectsKey] as? Set<ZMManagedObject>)?.map{$0.objectID} ?? []
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        self.uiMOC.mergeChanges(fromContextDidSave: change)
        mergeNotifications = []
        return changedObjects
    }

    
}

class NotificationDispatcherTests : NotificationDispatcherTestBase {

    class Wrapper {
        let dispatcher : NotificationDispatcher
        
        init(managedObjectContext: NSManagedObjectContext) {
            self.dispatcher = NotificationDispatcher(managedObjectContext: managedObjectContext)
        }
        deinit{
            dispatcher.tearDown()
        }
    }
    
    func testThatDeallocates(){
        // when
        var wrapper : Wrapper? = Wrapper(managedObjectContext: uiMOC)
        weak var center = wrapper!.dispatcher
        XCTAssertNotNil(center)
        
        // when
        wrapper = nil
        
        // then
        XCTAssertNil(center)
    }
    
    func testThatItNotifiesAboutChanges(){
        
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        withExtendedLifetime(ConversationChangeInfo.add(observer: conversationObserver, for: conversation)) { () -> () in

            // when
            conversation.userDefinedName = "foo"
            uiMOC.saveOrRollback()
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            
            // then
            XCTAssertEqual(conversationObserver.notifications.count, 1)
            guard let changeInfo = conversationObserver.notifications.first else {
                return XCTFail()
            }
            XCTAssertTrue(changeInfo.nameChanged)
        }
    }
    
    func testThatItNotifiesAboutChangesInOtherObjects(){
        
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = "Bernd"
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        conversation.mutableLastServerSyncedActiveParticipants.add(user)
        uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        withExtendedLifetime(ConversationChangeInfo.add(observer: conversationObserver, for: conversation)) { () -> () in
            // when
            user.name = "Brett"
            uiMOC.saveOrRollback()
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            
            // then
            XCTAssertEqual(conversationObserver.notifications.count, 1)
            guard let changeInfo = conversationObserver.notifications.first else {
                XCTFail()
                return
            }
            XCTAssertTrue(changeInfo.nameChanged)
        }
    }
    
    func testThatItCanCalculateChangesWhenObjectIsFaulted(){
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = "foo"
        uiMOC.saveOrRollback()
        uiMOC.refresh(user, mergeChanges: true)
        XCTAssertTrue(user.isFault)
        XCTAssertEqual(user.displayName, "foo")
        let observer = UserObserver()
        withExtendedLifetime(UserChangeInfo.add(observer: observer, for: user, managedObjectContext: self.uiMOC)) { () -> () in
        
            // when
            syncMOC.performGroupedBlockAndWait {
                let syncUser = self.syncMOC.object(with: user.objectID) as! ZMUser
                syncUser.name = "bar"
                self.syncMOC.saveOrRollback()
            }
            mergeLastChanges()
            
            // then
            XCTAssertEqual(user.displayName, "bar")
            XCTAssertEqual(observer.notifications.count, 1)
            if let note = observer.notifications.first {
                XCTAssertTrue(note.nameChanged)
            }
        }
    }
    
    func testThatItNotifiesAboutChangeWhenObjectIsFaultedAndDisappears(){
        // given
        var user: ZMUser? = ZMUser.insertNewObject(in: uiMOC)
        user?.name = "foo"
        uiMOC.saveOrRollback()
        let objectID = user!.objectID
        uiMOC.refresh(user!, mergeChanges: true)
        XCTAssertTrue(user!.isFault)
        let observer = UserObserver()
        
        withExtendedLifetime(UserChangeInfo.add(observer: observer, for: user!, managedObjectContext: self.uiMOC)) { () -> () in
        
            // when
            user = nil
            syncMOC.performGroupedBlockAndWait {
                let syncUser = self.syncMOC.object(with: objectID) as! ZMUser
                syncUser.name = "bar"
                self.syncMOC.saveOrRollback()
            }
            mergeLastChanges()
            
            // then
            XCTAssertEqual(observer.notifications.count, 1)
            if let note = observer.notifications.first {
                XCTAssertTrue(note.nameChanged)
            }
        }
    }
    
    func testThatItProcessesNonCoreDataChangeNotifications(){
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = "foo"
        uiMOC.saveOrRollback()
        
        let observer = UserObserver()
        withExtendedLifetime(UserChangeInfo.add(observer: observer, for: user, managedObjectContext: self.uiMOC))  { () -> () in
        
            // when
            NotificationDispatcher.notifyNonCoreDataChanges(objectID: user.objectID, changedKeys: ["name"], uiContext: uiMOC)
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            
            // then
            XCTAssertEqual(observer.notifications.count, 1)
            if let note = observer.notifications.first {
                XCTAssertTrue(note.nameChanged)
            }
        }
    }
    
    func testThatItOnlySendsNotificationsWhenDidMergeIsCalled(){
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = "foo"
        uiMOC.saveOrRollback()
        
        let observer = UserObserver()
        withExtendedLifetime(UserChangeInfo.add(observer: observer, for: user, managedObjectContext: self.uiMOC)) { () -> () in
        
            // when
            user.name = "bar"
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            // then
            XCTAssertEqual(observer.notifications.count, 0)
            
            // and when
            sut.didMergeChanges(Set(arrayLiteral: user.objectID))
            
            // then
            XCTAssertEqual(observer.notifications.count, 1)
            if let note = observer.notifications.first {
                XCTAssertTrue(note.nameChanged)
            }
        }
    }
    
    func testThatItOnlySendsNotificationsWhenDidSaveIsCalled(){
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = "foo"
        uiMOC.saveOrRollback()
        
        let observer = UserObserver()
        withExtendedLifetime(UserChangeInfo.add(observer: observer, for: user, managedObjectContext: self.uiMOC)) { () -> () in
        
            // when
            user.name = "bar"
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            // then
            XCTAssertEqual(observer.notifications.count, 0)
            
            // and when
            uiMOC.saveOrRollback()
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

            // then
            XCTAssertEqual(observer.notifications.count, 1)
            if let note = observer.notifications.first {
                XCTAssertTrue(note.nameChanged)
            }
        }
    }
    
    // MARK: Background behaviour
    
    func testThatItDoesNotProcessChangesWhenDisabled(){
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = "foo"
        uiMOC.saveOrRollback()
        
        let observer = UserObserver()
        withExtendedLifetime(UserChangeInfo.add(observer: observer, for: user, managedObjectContext: self.uiMOC)) { () -> () in
            
            // when
            sut.isDisabled = true
            user.name = "bar"
            uiMOC.saveOrRollback()
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            
            // then
            XCTAssertEqual(observer.notifications.count, 0)
        }
    }
    
    func testThatItProcessesChangesAfterBeingEnabled(){
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = "foo"
        uiMOC.saveOrRollback()
        sut.isDisabled = true
        
        let observer = UserObserver()
        withExtendedLifetime(UserChangeInfo.add(observer: observer, for: user, managedObjectContext: self.uiMOC)) { () -> () in
            
            // when
            sut.isDisabled = false
            user.name = "bar"
            uiMOC.saveOrRollback()
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            
            // then
            XCTAssertEqual(observer.notifications.count, 1)
            if let note = observer.notifications.first {
                XCTAssertTrue(note.nameChanged)
            }
        }
    }
    
    func testThatItDoesNotProcessChangesWhenAppEntersBackground(){
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = "foo"
        uiMOC.saveOrRollback()
        
        let observer = UserObserver()
        withExtendedLifetime(UserChangeInfo.add(observer: observer, for: user, managedObjectContext: self.uiMOC)) { () -> () in
        
            // when
            sut.applicationDidEnterBackground()
            user.name = "bar"
            uiMOC.saveOrRollback()
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            
            // then
            XCTAssertEqual(observer.notifications.count, 0)
        }
    }
    
    func testThatItProcessesChangesAfterAppEnteredBackgroundAndNowEntersForegroundAgain(){
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = "foo"
        uiMOC.saveOrRollback()
        sut.applicationDidEnterBackground()
        
        let observer = UserObserver()
        withExtendedLifetime(UserChangeInfo.add(observer: observer, for: user, managedObjectContext: self.uiMOC)) { () -> () in

            // when
            sut.applicationWillEnterForeground()
            user.name = "bar"
            uiMOC.saveOrRollback()
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            
            // then
            XCTAssertEqual(observer.notifications.count, 1)
            if let note = observer.notifications.first {
                XCTAssertTrue(note.nameChanged)
            }
        }
    }
    
    
    // MARK: ChangeInfoConsumer
    class ChangeConsumer : NSObject, ChangeInfoConsumer {
        var changes : [ClassIdentifier : [ObjectChangeInfo]]?
        var didCallStopObserving = false
        var didCallStartObserving = false
        
        func objectsDidChange(changes: [ClassIdentifier : [ObjectChangeInfo]]) {
            self.changes = changes
        }
        
        func stopObserving() {
            didCallStopObserving = true
        }
        
        func startObserving() {
            didCallStartObserving = true
        }
    }
    
    func testThatItNotifiesChangeInfoConsumersWhenObservationStops_enteringBackground(){
        // given
        let consumer = ChangeConsumer()
        sut.addChangeInfoConsumer(consumer)
        XCTAssertFalse(consumer.didCallStopObserving)

        // when
        sut.applicationDidEnterBackground()
        
        // then
        XCTAssertTrue(consumer.didCallStopObserving)
    }
    
    func testThatItNotifiesChangeInfoConsumersWhenObservationStarts_enteringForeground(){
        // given
        let consumer = ChangeConsumer()
        sut.applicationDidEnterBackground()
        sut.addChangeInfoConsumer(consumer)
        XCTAssertFalse(consumer.didCallStartObserving)
        
        // when
        sut.applicationWillEnterForeground()
        
        // then
        XCTAssertTrue(consumer.didCallStartObserving)
    }
    
    func testThatItNotifiesChangeInfoConsumersWhenObservationStops_disabled(){
        // given
        let consumer = ChangeConsumer()
        sut.addChangeInfoConsumer(consumer)
        XCTAssertFalse(consumer.didCallStopObserving)
        
        // when
        sut.isDisabled = true
        
        // then
        XCTAssertTrue(consumer.didCallStopObserving)
    }
    
    func testThatItNotifiesChangeInfoConsumersWhenObservationStarts_enabled(){
        // given
        let consumer = ChangeConsumer()
        sut.isDisabled = true
        sut.addChangeInfoConsumer(consumer)
        XCTAssertFalse(consumer.didCallStartObserving)
        
        // when
        sut.isDisabled = false
        
        // then
        XCTAssertTrue(consumer.didCallStartObserving)
    }
    
    func testThatItNotifiesChangeInfoConsumersWhenObjectChanged(){
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = "foo"
        uiMOC.saveOrRollback()
        
        let consumer = ChangeConsumer()
        sut.addChangeInfoConsumer(consumer)
        XCTAssertNil(consumer.changes)
        
        // when
        user.name = "bar"
        uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        XCTAssertNotNil(consumer.changes)
        if let changes = consumer.changes {
            XCTAssertEqual(changes.count, 1)
            guard let userChanges = changes[ZMUser.entityName()] as? [UserChangeInfo],
                  let change = userChanges.first
            else { return XCTFail()}
            XCTAssertTrue(change.nameChanged)
        }
    }
    
    func testThatItProcessesChangedObjectIDsFromMerge(){
        // given
        let conv = ZMConversation.insertNewObject(in: uiMOC)
        uiMOC.saveOrRollback()
        withExtendedLifetime(ConversationChangeInfo.add(observer: conversationObserver, for: conv)) { () -> () in

            syncMOC.performGroupedBlockAndWait {
                let syncConv = try! self.syncMOC.existingObject(with: conv.objectID) as! ZMConversation
                syncConv.userDefinedName = "foo"
                self.syncMOC.saveOrRollback()
            }
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            self.uiMOC.mergeChanges(fromContextDidSave: mergeNotifications.last!)
            
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            XCTAssertEqual(conversationObserver.notifications.count, 0)

            // when
            sut.didMergeChanges(Set(arrayLiteral: conv.objectID))
            
            // then
            XCTAssertEqual(conversationObserver.notifications.count, 1)
            guard let changeInfo = conversationObserver.notifications.first else {
                return XCTFail()
            }
            XCTAssertTrue(changeInfo.nameChanged)
        }
    }
    
}
