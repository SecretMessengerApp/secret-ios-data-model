// 
// 


@import Foundation;
@import CoreData;


@interface NSFetchRequest (ZMRelationshipKeyPaths)

- (void)configureRelationshipPrefetching;

- (NSSet *)allKeyPathsInPredicate;

@end
