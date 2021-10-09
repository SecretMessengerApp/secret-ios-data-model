// 
// 

@import WireDataModel;
#import "ZMBaseManagedObjectTest.h"
#import <WireDataModelTests-Swift.h>

//Integration tests for validation

@interface ManagedObjectValidationTests : ZMBaseManagedObjectTest

@end

@implementation ManagedObjectValidationTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testThatValidationOnUIContextIsPerformed
{
    ZMUser *user = [ZMUser selfUserInContext:self.uiMOC];
    user.name = @"Ilya";
    id value = user.name;
    
    id validator = [OCMockObject mockForClass:[StringLengthValidator class]];
 
    [[[validator expect] andForwardToRealObject] validateValue:[OCMArg anyObjectRef]
                                           minimumStringLength:2
                                           maximumStringLength:100
                                             maximumByteLength:INT_MAX
                                                         error:[OCMArg anyObjectRef]];
  
    BOOL result = [user validateValue:&value forKey:@"name" error:NULL];
    XCTAssertTrue(result);
    [validator verify];
    [validator stopMocking];
}

- (void)testThatValidationOnNonUIContextAlwaysPass
{
    [self.syncMOC performGroupedBlockAndWait:^{        
        ZMUser *user = [ZMUser selfUserInContext:self.syncMOC];
        user.name = @"Ilya";
        id value = user.name;
        
        id validator = [OCMockObject mockForClass:[StringLengthValidator class]];
        [[[validator reject] andForwardToRealObject] validateValue:[OCMArg anyObjectRef]
                                               minimumStringLength:2
                                               maximumStringLength:64
                                                 maximumByteLength:256
                                                             error:[OCMArg anyObjectRef]];
        
        BOOL result = [user validateValue:&value forKey:@"name" error:NULL];
        XCTAssertTrue(result);
        [validator verify];
        [validator stopMocking];
    }];
}

@end
