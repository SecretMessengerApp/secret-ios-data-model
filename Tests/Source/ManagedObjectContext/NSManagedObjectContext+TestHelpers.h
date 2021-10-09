// 
// 


#import "NSManagedObjectContext+zmessaging.h"



@interface NSManagedObjectContext (TestHelpers)

- (void)performGroupedBlockAndWaitWithReasonableTimeout:(dispatch_block_t)block;

@end
