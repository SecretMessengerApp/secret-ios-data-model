//
//

import Foundation
import WireUtilities

/// List of context
@objcMembers public class ManagedObjectContextDirectory: NSObject {
    
    init(persistentStoreCoordinator: NSPersistentStoreCoordinator,
         accountDirectory: URL,
         applicationContainer: URL,
         dispatchGroup: ZMSDispatchGroup? = nil) {
        self.uiContext = ManagedObjectContextDirectory.createUIManagedObjectContext(persistentStoreCoordinator: persistentStoreCoordinator, dispatchGroup: dispatchGroup)
        self.syncContext = ManagedObjectContextDirectory.createSyncManagedObjectContext(persistentStoreCoordinator: persistentStoreCoordinator,
                                                                                        accountDirectory: accountDirectory,
                                                                                        dispatchGroup: dispatchGroup,
                                                                                        applicationContainer: applicationContainer)
        MemoryReferenceDebugger.register(self.syncContext)
        self.msgContext = ManagedObjectContextDirectory.createMsgManagedObjectContext(persistentStoreCoordinator: persistentStoreCoordinator,
                                                                                      accountDirectory: accountDirectory,
                                                                                      dispatchGroup: dispatchGroup,
                                                                                      applicationContainer: applicationContainer)
        MemoryReferenceDebugger.register(self.msgContext)
        self.searchContext = ManagedObjectContextDirectory.createSearchManagedObjectContext(persistentStoreCoordinator: persistentStoreCoordinator, dispatchGroup: dispatchGroup)
        MemoryReferenceDebugger.register(self.searchContext)
        super.init()
    }
    
    /// User interface context. It can be used only from the main queue
    fileprivate(set) public var uiContext: NSManagedObjectContext!
    
    /// Local storage and network synchronization context. It can be used only from its private queue.
    /// This context track changes to its objects and synchronizes them from/to the backend.
    fileprivate(set) public var syncContext: NSManagedObjectContext!
    
    /// message send context
    fileprivate(set) public var msgContext: NSManagedObjectContext!
    
    /// Search context. It can be used only from its private queue.
    /// This context is used to perform searches, not to slow down or insert temporary results in the
    /// sync context.
    fileprivate(set) public var searchContext: NSManagedObjectContext!

    deinit {
        self.tearDown()
    }
}

extension ManagedObjectContextDirectory {
    func tearDown() {
        // this will set all contextes to nil
        // making it crash if used after tearDown
        self.uiContext?.tearDown()
        self.syncContext?.tearDown()
        self.searchContext?.tearDown()
        self.uiContext?.tearDown()
        self.syncContext?.tearDown()
        self.searchContext?.tearDown()
        self.uiContext = nil
        self.syncContext = nil
        self.searchContext = nil
    }
}

extension ManagedObjectContextDirectory {
    
    fileprivate static func createUIManagedObjectContext(
        persistentStoreCoordinator: NSPersistentStoreCoordinator, dispatchGroup: ZMSDispatchGroup? = nil) -> NSManagedObjectContext {
        
        let moc = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        moc.performAndWait {
            Thread.current.name = NSManagedObjectContextType.ui.rawValue
            moc.name = NSManagedObjectContextType.ui.rawValue
            moc.markAsUIContext()
            moc.configure(with: persistentStoreCoordinator)
            ZMUser.selfUser(in: moc)
            dispatchGroup.apply(moc.add)
        }
        moc.mergePolicy = NSMergePolicy(merge: .rollbackMergePolicyType)
        return moc
    }
    
    fileprivate static func createSyncManagedObjectContext(
        persistentStoreCoordinator: NSPersistentStoreCoordinator,
        accountDirectory: URL,
        dispatchGroup: ZMSDispatchGroup? = nil,
        applicationContainer: URL) -> NSManagedObjectContext {
        
        let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        moc.performAndWait {
            Thread.current.name = NSManagedObjectContextType.sync.rawValue
            moc.name = NSManagedObjectContextType.sync.rawValue
            moc.markAsSyncContext()
            moc.configure(with: persistentStoreCoordinator)
            ZMUser.selfUser(in: moc)
            moc.setupLocalCachedSessionAndSelfUser()
            moc.setupUserKeyStore(accountDirectory: accountDirectory, applicationContainer: applicationContainer)
            moc.undoManager = nil
            moc.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
            dispatchGroup.apply(moc.add)
        }
        
        // this will be done async, not to block the UI thread, but
        // enqueued on the syncMOC anyway, so it will execute before
        // any other block of code has a chance to use it
//        moc.performGroupedBlock {
//            moc.applyPersistedDataPatchesForCurrentVersion()
//        }
        return moc
    }
    
    fileprivate static func createMsgManagedObjectContext(
            persistentStoreCoordinator: NSPersistentStoreCoordinator,
            accountDirectory: URL,
            dispatchGroup: ZMSDispatchGroup? = nil,
            applicationContainer: URL) -> NSManagedObjectContext {
            
            let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            moc.performAndWait {
                Thread.current.name = NSManagedObjectContextType.msg.rawValue
                moc.name = NSManagedObjectContextType.msg.rawValue
                moc.markAsMsgContext()
                moc.configure(with: persistentStoreCoordinator)
                ZMUser.selfUser(in: moc)
                moc.setupLocalCachedSessionAndSelfUser()
                moc.setupUserKeyStore(accountDirectory: accountDirectory, applicationContainer: applicationContainer)
                moc.undoManager = nil
                moc.mergePolicy = NSMergePolicy(merge: .rollbackMergePolicyType)
                dispatchGroup.apply(moc.add)
            }
            
            // this will be done async, not to block the UI thread, but
            // enqueued on the syncMOC anyway, so it will execute before
            // any other block of code has a chance to use it
    //        moc.performGroupedBlock {
    //            moc.applyPersistedDataPatchesForCurrentVersion()
    //        }
            return moc
        }
 
    fileprivate static func createSearchManagedObjectContext(
        persistentStoreCoordinator: NSPersistentStoreCoordinator,
        dispatchGroup: ZMSDispatchGroup? = nil
        ) -> NSManagedObjectContext {
        
        let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        moc.markAsSearch()
        moc.performAndWait {
            Thread.current.name = NSManagedObjectContextType.search.rawValue
            moc.name = NSManagedObjectContextType.search.rawValue
            moc.configure(with: persistentStoreCoordinator)
            ZMUser.selfUser(in: moc)
            moc.setupLocalCachedSessionAndSelfUser()
            moc.undoManager = nil
            moc.mergePolicy = NSMergePolicy(merge: .rollbackMergePolicyType)
            dispatchGroup.apply(moc.add)
        }
        return moc
    }
}

extension NSManagedObjectContext {
    
    fileprivate func configure(with persistentStoreCoordinator: NSPersistentStoreCoordinator) {
        self.createDispatchGroups()
        self.persistentStoreCoordinator = persistentStoreCoordinator
    }
    
    // This function setup the user info on the context, the session and self user must be initialised before end.
    public func setupLocalCachedSessionAndSelfUser() {
        guard let request = UserClient.sortedFetchRequest(),
              let session = self.executeFetchRequestOrAssert(request).first as? ZMSession else { return }
        self.userInfo[SessionObjectIDKey] = session.objectID
        ZMUser.boxSelfUser(session.selfUser, inContextUserInfo: self)
    }
    
}
