// 
// 


@import Foundation;
#import "ZMBaseManagedObjectTest.h"
#import "ZMChangedIndexes.h"
#import "ZMOrderedSetState.h"

@interface ZMChangedIndexesTests : ZMBaseManagedObjectTest




@end

@implementation ZMChangedIndexesTests



- (void)testThatItCalculatesDifferenceBetweenOrderedSets
{

    // given
    ZMOrderedSetState *startState = [[ZMOrderedSetState alloc] initWithOrderedSet:[[NSOrderedSet alloc] initWithObjects:@"A", @"B", @"C", @"D", @"E", nil]];

    ZMOrderedSetState *endState = [[ZMOrderedSetState alloc] initWithOrderedSet:[[NSOrderedSet alloc] initWithObjects:@"A", @"F", @"D", @"C", @"E", nil]];
    
    ZMOrderedSetState *updateState = [[ZMOrderedSetState alloc] initWithOrderedSet:[[NSOrderedSet alloc] initWithObjects:@"C", @"E", nil]];
    
    
    // when
    ZMChangedIndexes *sut = [[ZMChangedIndexes alloc] initWithStartState:startState endState:endState updatedState:updateState];
    
    
    // then
    XCTAssertEqualObjects(sut.deletedIndexes, [[NSIndexSet alloc] initWithIndex:1]);
    XCTAssertEqualObjects(sut.insertedIndexes, [[NSIndexSet alloc] initWithIndex:1]);
    
    XCTAssertEqualObjects(sut.updatedIndexes, [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(3, 2)]);
    
    __block BOOL calledOnce = NO;
    [sut enumerateMovedIndexes:^(NSUInteger from, NSUInteger to) {
        XCTAssertFalse(calledOnce);
        calledOnce = YES;
        XCTAssertEqual(from, 3u);
        XCTAssertEqual(to, 2u);
    }];
    
    XCTAssertTrue(calledOnce);
}

- (void)testThatItCalculatesMovedIndexesForSwappedIndexesCorrectly
{
    
    // given
    ZMOrderedSetState *startState = [[ZMOrderedSetState alloc] initWithOrderedSet:[[NSOrderedSet alloc] initWithObjects:@"A", @"B", @"C", nil]];
    ZMOrderedSetState *endState = [[ZMOrderedSetState alloc] initWithOrderedSet:[[NSOrderedSet alloc] initWithObjects:@"C", @"B", @"A", nil]];
    ZMOrderedSetState *updateState = [[ZMOrderedSetState alloc] initWithOrderedSet:[NSOrderedSet orderedSet]];
    
    // when
    ZMChangedIndexes *sut = [[ZMChangedIndexes alloc] initWithStartState:startState endState:endState updatedState:updateState];
    
    // then
    XCTAssertEqualObjects(sut.deletedIndexes, [NSIndexSet indexSet]);
    XCTAssertEqualObjects(sut.insertedIndexes, [NSIndexSet indexSet]);
    XCTAssertEqualObjects(sut.updatedIndexes, [NSIndexSet indexSet]);

    __block NSUInteger callcount = 0;
    [sut enumerateMovedIndexes:^(NSUInteger from, NSUInteger to) {
        if (callcount == 0) {
            XCTAssertEqual(from, 2u);
            XCTAssertEqual(to, 0u);
        } if (callcount == 1) {
            XCTAssertEqual(from, 2u);
            XCTAssertEqual(to, 1u);
        } 
        callcount++;
    }];

    XCTAssertEqual(callcount, 2u);
}


@end
