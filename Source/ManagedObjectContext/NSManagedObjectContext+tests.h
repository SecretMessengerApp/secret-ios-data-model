// 
// 


@import CoreData;


@interface NSManagedObjectContext (zmessagingTests)

- (void)markAsSyncContext;
- (void)markAsMsgContext;
- (void)markAsSearchContext;
- (void)markAsUIContext;
- (void)disableObjectRefresh;

- (void)resetContextType;

- (void)disableSaves;
- (void)enableSaves;

/// Enables automatic rollback whenever the sync is saved
- (void)enableForceRollback;

/// Disables automatic rollback whenever the sync is saved
- (void)disableForceRollback;

@end
