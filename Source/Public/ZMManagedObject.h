// 
// 


@import CoreData;

extern NSString * const ZMDataPropertySuffix;

@protocol ZMManagedObjectContextProvider;

@interface ZMManagedObject : NSManagedObject

@property (nonatomic, readonly) BOOL isZombieObject;

+ (NSManagedObjectID *)objectIDForURIRepresentation:(NSURL *)url inUserSession:(id<ZMManagedObjectContextProvider>)userSession;
+ (instancetype)existingObjectWithID:(NSManagedObjectID *)identifier inUserSession:(id<ZMManagedObjectContextProvider>)userSession;
+ (instancetype)existingObjectWithObjectIdentifier:(NSString *)identifier inManagedObjectContext:(NSManagedObjectContext *)context;

- (NSString *)objectIDURLString;

@end

@interface ZMManagedObject (NonpersistedObjectIdentifer)

@property (nonatomic, readonly) NSString *nonpersistedObjectIdentifer;

+ (instancetype)existingObjectWithNonpersistedObjectIdentifer:(NSString *)identifier inUserSession:(id<ZMManagedObjectContextProvider>)userSession;

@end
