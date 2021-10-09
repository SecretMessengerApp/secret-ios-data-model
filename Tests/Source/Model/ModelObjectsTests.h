// 
// 


@import WireDataModel;
@import WireTesting;
#import <CoreData/CoreData.h>
#import <WireTransport/WireTransport.h>

#import "ZMConversation+Internal.h"
#import "ZMManagedObject+Internal.h"
#import "ZMBaseManagedObjectTest.h"



@interface ModelObjectsTests : ZMBaseManagedObjectTest

@property (nonatomic) ZMUser *selfUser;
@property (nonatomic) NSManagedObjectModel *model;

- (void)checkAttributeForClass:(Class)aClass key:(NSString *)key value:(id)value;

- (void)withAssertionsDisabled:(void (^)(void))block;

@end
