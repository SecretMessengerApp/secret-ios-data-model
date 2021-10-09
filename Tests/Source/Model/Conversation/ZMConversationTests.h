// 
// 


#import "ModelObjectsTests.h"
#import "NSManagedObjectContext+zmessaging.h"
#import "ZMUser+Internal.h"
#import "ZMMessage+Internal.h"
#import "ZMConnection+Internal.h"

@interface ZMConversationTestsBase : ModelObjectsTests

@property(nonatomic) NSNotification *lastReceivedNotification;

- (void)didReceiveWindowNotification:(NSNotification *)notification;
- (ZMUser *)createUser; ///< creates user on the UI moc
- (ZMUser *)createUserOnMoc:(NSManagedObjectContext *)moc;
- (ZMConversation *)insertConversationWithUnread:(BOOL)hasUnread;
@end
