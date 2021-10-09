// 
// 


@import CoreData;

NS_ASSUME_NONNULL_BEGIN

@interface NSNotification (ManagedObjectContextSave)

- (void)enumerateInsertedObjectsWithEntityName:(NSString *)entityName withBlock:(void(^)(id mo))block;

- (void)enumerateUpdatedObjectsWithEntityName:(NSString *)entityName withBlock:(void(^)(id mo))block;

@end

NS_ASSUME_NONNULL_END
