// 
// 


#import <Foundation/Foundation.h>



/// This class wraps a C++ stdlib std::vector<intptr_t>
/// Wrapping it allows pure ObjC classes to pass this state around.
@interface ZMOrderedSetState : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithOrderedSet:(NSOrderedSet *)orderedSet NS_DESIGNATED_INITIALIZER;

@end



@interface ZMOrderedSetState (ZMTrace)

- (intptr_t)traceSize;
- (intptr_t *)traceState;

@end
