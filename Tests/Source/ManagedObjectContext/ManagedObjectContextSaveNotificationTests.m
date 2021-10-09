// 
// 


#import "ZMBaseManagedObjectTest.h"

#import "NSNotification+ManagedObjectContextSave.h"
#import "NSManagedObjectContext+zmessaging.h"

#import "ZMUser+Internal.h"
#import "ZMConnection+Internal.h"



@interface ManagedObjectContextSaveNotificationTests : ZMBaseManagedObjectTest
@end



@implementation ManagedObjectContextSaveNotificationTests

- (void)testThatItEnumeratesInsertedObjects
{
    // given
    id mo1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    id mo2 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    id mo3 = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    
    NSDictionary *userInfo =
    @{
      NSInsertedObjectsKey: [NSSet setWithArray:@[mo1, mo2, mo3]]
      };
    NSNotification *note = [NSNotification notificationWithName:NSManagedObjectContextDidSaveNotification object:self.uiMOC userInfo:userInfo];
    
    // when
    NSMutableSet *found = [NSMutableSet set];
    [note enumerateInsertedObjectsWithEntityName:[ZMUser entityName] withBlock:^(NSManagedObject *mo) {
        [found addObject:mo];
    }];

    // then
    NSSet *expected = [NSSet setWithArray:@[mo1, mo2]];
    XCTAssertEqualObjects(found, expected);
}

- (void)testThatItEnumeratesModifiedObjects
{
    // given
    id mo1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    id mo2 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    id mo3 = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    
    NSDictionary *userInfo =
    @{
      NSUpdatedObjectsKey: [NSSet setWithArray:@[mo1, mo2, mo3]]
      };
    NSNotification *note = [NSNotification notificationWithName:NSManagedObjectContextDidSaveNotification object:self.uiMOC userInfo:userInfo];
    
    // when
    NSMutableSet *found = [NSMutableSet set];
    [note enumerateUpdatedObjectsWithEntityName:[ZMUser entityName] withBlock:^(NSManagedObject *mo) {
        [found addObject:mo];
    }];
    
    // then
    NSSet *expected = [NSSet setWithArray:@[mo1, mo2]];
    XCTAssertEqualObjects(found, expected);

}

@end
