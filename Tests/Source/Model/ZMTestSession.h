//
//

@import Foundation;

@class NSManagedObjectContext;
@class ZMManagedObject;
@class ZMUser;
@class ZMSDispatchGroup;

/// This class provides contexts & caches for running tests against our data model.
@interface ZMTestSession : NSObject

- (instancetype)initWithDispatchGroup:(ZMSDispatchGroup *)dispatchGroup accountIdentifier:(NSUUID *)identifier;
- (instancetype)initWithDispatchGroup:(ZMSDispatchGroup *)dispatchGroup;

/// If useInMemoryStore is set to YES an in memory store is used. Defaults to YES.
@property (nonatomic) BOOL shouldUseInMemoryStore;

/// If shouldUseRealKeychain is set to YES the real keychain is accessed. Defaults to NO
@property (nonatomic) BOOL shouldUseRealKeychain;

/// User interface context. The UI makes changes to objects on this context.
@property (nonatomic, readonly) NSManagedObjectContext *uiMOC;

/// Synchronization context. Synchronized changes are made on this context.
@property (nonatomic, readonly) NSManagedObjectContext *syncMOC;

/// Search context. Results from searches are retrieved on this context.
@property (nonatomic, readonly) NSManagedObjectContext *searchMOC;

/// The url in which the database will be stored (in case @c shouldUseInMemoryStore is set to @c NO)
//@property (nonatomic, readonly) NSURL *databaseDirectory;

@property (nonatomic, readonly) NSURL *storeURL;

/// Prepare the fixture for running a test.
- (void)prepareForTestNamed:(NSString *)testName;

/// Waits for queues and managed object contexts to finish work and verifies mocks
- (void)tearDown;

/// Resets UI and Sync contexts
- (void)resetUIandSyncContextsAndResetPersistentStore:(BOOL)resetPersistantStore;

/// Perform operations pretending that the uiMOC is a syncMOC
- (void)performPretendingUiMocIsSyncMoc:(void(^)(void))block;

/// Perform operations pretending that the syncMOC is a uiMOC
- (void)performPretendingSyncMocIsUiMoc:(void(^)(void))block;

/// Wipes the asset caches on the managed object contexts
- (void)wipeCaches;

@end
