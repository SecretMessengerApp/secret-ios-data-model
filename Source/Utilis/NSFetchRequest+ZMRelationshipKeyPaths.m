// 
// 


@import CoreData;
#import "NSFetchRequest+ZMRelationshipKeyPaths.h"




@interface NSPredicate (ZMRelationshipKeyPaths)

- (void)collectRelationshipKeyPathsIntoSet:(NSMutableSet *)keyPaths;
- (void)collectKeyPathsIntoSet:(NSMutableSet *)keyPaths;

@end



@interface NSExpression (ZMRelationshipKeyPaths)

- (void)collectRelationshipKeyPathsIntoSet:(NSMutableSet *)keyPaths;
- (void)collectKeyPathsIntoSet:(NSMutableSet *)keyPaths;

@end




@implementation NSFetchRequest (ZMRelationshipKeyPaths)

- (void)configureRelationshipPrefetching;
{
    NSMutableSet *keyPaths = [NSMutableSet set];
    [self.predicate collectRelationshipKeyPathsIntoSet:keyPaths];
    self.relationshipKeyPathsForPrefetching = [keyPaths allObjects];
}

- (NSSet *)allKeyPathsInPredicate;
{
    NSMutableSet *keyPaths = [NSMutableSet set];
    [self.predicate collectKeyPathsIntoSet:keyPaths];
    return keyPaths;
}

@end



@implementation NSPredicate (ZMRelationshipKeyPaths)

- (void)collectRelationshipKeyPathsIntoSet:(NSMutableSet * __unused)keyPaths;
{
    // no-op
}

- (void)collectKeyPathsIntoSet:(NSMutableSet * __unused)keyPaths;
{
    // no-op
}

@end



@implementation NSCompoundPredicate (ZMRelationshipKeyPaths)

- (void)collectRelationshipKeyPathsIntoSet:(NSMutableSet *)keyPaths;
{
    for (NSPredicate *p in self.subpredicates) {
        [p collectRelationshipKeyPathsIntoSet:keyPaths];
    }
}

- (void)collectKeyPathsIntoSet:(NSMutableSet *)keyPaths;
{
    for (NSPredicate *p in self.subpredicates) {
        [p collectKeyPathsIntoSet:keyPaths];
    }
}

@end



@implementation NSComparisonPredicate (ZMRelationshipKeyPaths)

- (void)collectRelationshipKeyPathsIntoSet:(NSMutableSet *)keyPaths;
{
    [self.rightExpression collectRelationshipKeyPathsIntoSet:keyPaths];
    [self.leftExpression collectRelationshipKeyPathsIntoSet:keyPaths];
}

- (void)collectKeyPathsIntoSet:(NSMutableSet *)keyPaths;
{
    [self.rightExpression collectKeyPathsIntoSet:keyPaths];
    [self.leftExpression collectKeyPathsIntoSet:keyPaths];
}

@end



@implementation NSExpression (ZMRelationshipKeyPaths)

- (void)collectRelationshipKeyPathsIntoSet:(NSMutableSet *)keyPaths;
{
    // status -> nothing
    // connection.status -> connection
    // connection.user.name -> connection.user
    if (self.expressionType == NSKeyPathExpressionType) {
        NSString *keyPath = self.keyPath;
        NSArray *components = [keyPath componentsSeparatedByString:@"."];
        if (1 < components.count) {
            NSString *p = [[components subarrayWithRange:NSMakeRange(0, components.count - 1)] componentsJoinedByString:@"."];
            [keyPaths addObject:p];
        }
    }
}

- (void)collectKeyPathsIntoSet:(NSMutableSet *)keyPaths;
{
    if (self.expressionType == NSKeyPathExpressionType) {
        NSString *keyPath = self.keyPath;
        if (keyPath != nil) {
            [keyPaths addObject:keyPath];
        }
    }
}

@end
