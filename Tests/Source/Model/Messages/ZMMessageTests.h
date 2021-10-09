// 
// 


#import "ModelObjectsTests.h"


@interface BaseZMMessageTests : ModelObjectsTests

@end





@interface BaseZMMessageTests (Ephemeral)

- (NSString *)textMessageRequiringExternalMessageWithNumberOfClients:(NSUInteger)count;
- (ZMUpdateEvent *)encryptedExternalMessageFixtureWithBlobFromClient:(UserClient *)fromClient;
- (NSString *)expectedExternalMessageText;

@end
