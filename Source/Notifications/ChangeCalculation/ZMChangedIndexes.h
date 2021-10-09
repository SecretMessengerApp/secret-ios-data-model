// 
// 


#import <Foundation/Foundation.h>
#import "ZMSetChangeMoveType.h"
@class ZMOrderedSetState;



@interface ZMChangedIndexes : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithStartState:(ZMOrderedSetState *)startState endState:(ZMOrderedSetState *)endState updatedState:(ZMOrderedSetState *)updatedState;
- (instancetype)initWithStartState:(ZMOrderedSetState *)startState endState:(ZMOrderedSetState *)endState updatedState:(ZMOrderedSetState *)updatedState moveType:(ZMSetChangeMoveType)moveType NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly) BOOL requiresReload;
@property (nonatomic, readonly) NSIndexSet *deletedIndexes;
@property (nonatomic, readonly) NSIndexSet *insertedIndexes;
@property (nonatomic, readonly) NSIndexSet *updatedIndexes;
@property (nonatomic, readonly) NSSet *deletedObjects;

- (void)enumerateMovedIndexes:(void(^)(NSUInteger from, NSUInteger to))block;

@end
