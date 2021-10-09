// 
// 


@import CoreData;
@import WireSystem;
@import WireUtilities;
@import PINCache;

@class NSOperationQueue;
@class DisplayNameGenerator;

extern NSString * _Nonnull const IsUserInterfaceContextKey;
extern NSString * _Nonnull const IsSyncContextKey;
extern NSString * _Nonnull const IsSearchContextKey;
extern NSString * _Nonnull const IsEventContextKey;

@interface NSManagedObjectContext (zmessaging)

/// Returns @c YES if the receiver is a context that is used for synchronisation with the backend.
///
/// Individual fields are marked as "needs to be pushed to the server" or "is in sync with server" when they are changed by either a user interface context or a sync context repsectively.
@property (readonly) BOOL zm_isSyncContext;

/// handler msg send
@property (readonly) BOOL zm_isMsgContext;

/// Inverse of @c zm_isSyncContext
@property (readonly) BOOL zm_isUserInterfaceContext;

/// Returns @c YES if the receiver is a context that is used for searching.
@property (readonly) BOOL zm_isSearchContext;

/// Returns @c YES if the context should refresh objects following the policy for the sync context
@property (readonly) BOOL zm_shouldRefreshObjectsWithSyncContextPolicy;

/// Returns @c YES if the context should refresh objects following the policy for the UI context
@property (readonly) BOOL zm_shouldRefreshObjectsWithUIContextPolicy;

/// Returns @c YES if the context is still valid, false if it has been torn down
@property (readonly) BOOL zm_isValidContext;

/// Returns @c self in case this is a sync context, or attached sync context, if present
@property (nonatomic, null_unspecified) NSManagedObjectContext* zm_syncContext;

/// Returns @c self in case this is a sync context, or attached sync context, if present
@property (nonatomic, null_unspecified) NSManagedObjectContext* zm_msgContext;

/// Returns @c self in case this is a UI context, or attached UI context, if present
@property (nonatomic, null_unspecified) NSManagedObjectContext *zm_userInterfaceContext;

/// Returns the set containing all user clients that failed to establish a session with selfClient
@property (nonatomic, readonly, nullable) NSMutableSet *zm_failedToEstablishSessionStore;

/// Returns the URL of the store. This is supposed to be used for debugging purposes only
@property (nonatomic, readonly, nullable) NSURL *zm_storeURL;

/// Returns the Display Name Generator
@property (nonatomic, readonly, nullable) DisplayNameGenerator*zm_displayNameGenerator;

/// Calls @c -save: only if the receiver returns @c YES for @c -hasChanges
/// If the save fails, calls @c -rollback on the receiver.
/// returns @c NO if there was a rollback, @c YES otherwise
- (BOOL)saveOrRollback;

/// Calls @c -save: even if the receiver returns @c NO for @c -hasChanges
/// If the save fails, calls @c -rollback on the receiver.
/// returns @c NO if there was a rollback, @c YES otherwise
- (BOOL)forceSaveOrRollback;

/// This will trigger a call to @c -saveOrRollback once a coalescence timer has expired or immediately if there are too many pending changes
- (void)enqueueDelayedSave;
/// This will trigger a call to @c -saveOrRollback if there are too many pending changes. Returns YES if it saved
- (BOOL)saveIfTooManyChanges;

/// This will trigger a call to @c -enqueueDelayedSave once the receiver's group has emptied or
/// immediately if the receiver has a lot of pending changes.
- (void)enqueueDelayedSaveWithGroup:(nullable ZMSDispatchGroup *)group;

/// Executes a fetch request and asserts in case of error
/// For generic requests in Swift please refer to `func fetchOrAssert<T>(request: NSFetchRequest<T>) -> [T]`
- (nonnull NSArray *)executeFetchRequestOrAssert:(nonnull NSFetchRequest *)request;

/// Fetch metadata for key from in-memory non-persisted metadata
/// or from persistent store metadata, in that order
- (nullable id)persistentStoreMetadataForKey:(nonnull NSString *)key;

@end

