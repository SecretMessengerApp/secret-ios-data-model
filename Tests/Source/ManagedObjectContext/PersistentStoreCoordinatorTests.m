// 
// 


#import "ZMBaseManagedObjectTest.h"
#import "ZMConversation+Internal.h"
#import "NSManagedObjectContext+zmessaging-Internal.h"
#import "ZMManagedObject+Internal.h"
#import "ZMTestSession.h"




@interface PersistentStoreCoordinatorTests : ZMBaseManagedObjectTest
@end



@implementation PersistentStoreCoordinatorTests

- (BOOL)shouldUseInMemoryStore;
{
    // This makes the test to use an on disk SQLite store
    return NO;
}

- (void)setUp
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL *storeURL = [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject] URLAppendingPersistentStoreLocation];
    
    if ([fm fileExistsAtPath:storeURL.path]) {
        NSError *error = nil;
        NSURL *parentURL;
        XCTAssert([storeURL getResourceValue:&parentURL forKey:NSURLParentDirectoryURLKey error:&error], @"%@", error);
        XCTAssert([[NSFileManager defaultManager] removeItemAtURL:parentURL error:&error],
                  @"Failed to remove directory %@", parentURL.path);
    }
    
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testThatChangesInOneContextAreVisibleInAnother
{
    // when
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    XCTAssert([self.uiMOC saveOrRollback]);
    
    __block ZMConversation *syncConversation;
    [self.syncMOC performGroupedBlockAndWait:^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:ZMConversation.entityName];
        NSArray *result = [self.syncMOC executeFetchRequestOrAssert:request];
        
        // then
        XCTAssertEqual(result.count, 1u);
        syncConversation = result[0];
    }];

    XCTAssertEqualObjects(syncConversation.objectID, conversation.objectID);
}

- (void)testThatPermissionsAreCorrectlySet;
{
    NSError *error;
    NSURL *parentURL;
    XCTAssert([self.testSession.storeURL getResourceValue:&parentURL forKey:NSURLParentDirectoryURLKey error:&error], @"%@", error);
    
    NSNumber *excluded;
    XCTAssert([parentURL getResourceValue:&excluded forKey:NSURLIsExcludedFromBackupKey error:&error], @"%@", error);
    XCTAssertTrue(excluded.boolValue);
    
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:parentURL.path error:&error];
    XCTAssertNotNil(attributes, @"%@", error);
    int permissions = ((NSNumber *) attributes[NSFilePosixPermissions]).intValue;
    XCTAssertEqual(permissions & 0077, 0);
}

@end
