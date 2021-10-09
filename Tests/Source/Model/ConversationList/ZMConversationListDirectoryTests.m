//
// 


@import WireDataModel;
#import "ZMBaseManagedObjectTest.h"
#import "ZMConversationListDirectory.h"
#import "ZMConversation+Internal.h"
#import "ZMConnection+Internal.h"
#import "ZMUser+Internal.h"
#import <WireDataModel/WireDataModel-Swift.h>

@interface ZMConversationListDirectoryTests : ZMBaseManagedObjectTest

@property (nonatomic) NSMutableArray *conversations;

@property (nonatomic) ZMConversation *archivedGroupConversation;
@property (nonatomic) ZMConversation *archivedOneToOneConversation;
@property (nonatomic) ZMConversation *incomingPendingConnectionConversation;
@property (nonatomic) ZMConversation *outgoingPendingConnectionConversation;
@property (nonatomic) ZMConversation *invalidConversation;
@property (nonatomic) ZMConversation *groupConversation;
@property (nonatomic) ZMConversation *groupConversationInFolder;
@property (nonatomic) ZMConversation *oneToOneConversation;
@property (nonatomic) ZMConversation *oneToOneConversationInFolder;
@property (nonatomic) ZMConversation *oneToOneConversationInTeam;
@property (nonatomic) ZMConversation *clearedConversation;
@property (nonatomic) ZMConversation *favoritedConversation;
@property (nonatomic) ZMConversation *serviceConversation;

@end



@implementation ZMConversationListDirectoryTests

- (ZMConversation *)createConversation
{
    ZMConversation *conv = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conv.lastServerTimeStamp = [NSDate date];
    conv.lastReadServerTimeStamp = conv.lastServerTimeStamp;
    conv.remoteIdentifier = [NSUUID createUUID];
    return conv;
}

- (void)setUp
{
    [super setUp];
    
    Team *team = [Team insertNewObjectInManagedObjectContext:self.uiMOC];
    team.remoteIdentifier = [NSUUID createUUID];
    
    ZMUser *otherUser = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    otherUser.remoteIdentifier = [NSUUID createUUID];
    
    ZMUser *serviceUser = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    serviceUser.serviceIdentifier = @"serviceA";
    serviceUser.providerIdentifier = @"providerA";
    serviceUser.remoteIdentifier = [NSUUID createUUID];
    
    Label *folder = [Label insertNewObjectInManagedObjectContext:self.uiMOC];
    folder.name = @"folder A";
    
    self.archivedGroupConversation = [self createConversation];
    self.archivedGroupConversation.conversationType = ZMConversationTypeGroup;
    self.archivedGroupConversation.isArchived = YES;
    self.archivedGroupConversation.userDefinedName = @"archivedGroupConversation";
    
    self.archivedOneToOneConversation = [self createConversation];
    self.archivedOneToOneConversation.conversationType = ZMConversationTypeOneOnOne;
    self.archivedOneToOneConversation.isArchived = YES;
    self.archivedOneToOneConversation.connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    self.archivedOneToOneConversation.connection.status = ZMConnectionStatusAccepted;
    self.archivedOneToOneConversation.userDefinedName = @"archivedOneToOneConversation";
    
    self.incomingPendingConnectionConversation = [self createConversation];
    self.incomingPendingConnectionConversation.conversationType = ZMConversationTypeConnection;
    self.incomingPendingConnectionConversation.connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    self.incomingPendingConnectionConversation.connection.status = ZMConnectionStatusPending;
    self.incomingPendingConnectionConversation.userDefinedName = @"incomingPendingConnectionConversation";
    
    self.outgoingPendingConnectionConversation = [self createConversation];
    self.outgoingPendingConnectionConversation.conversationType = ZMConversationTypeConnection;
    self.outgoingPendingConnectionConversation.connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    self.outgoingPendingConnectionConversation.connection.status = ZMConnectionStatusSent;
    self.outgoingPendingConnectionConversation.userDefinedName = @"outgoingConnectionConversation";
    
    self.groupConversation = [self createConversation];
    self.groupConversation.conversationType = ZMConversationTypeGroup;
    self.groupConversation.userDefinedName = @"groupConversation";
    
    self.groupConversationInFolder = [self createConversation];
    self.groupConversationInFolder.conversationType = ZMConversationTypeGroup;
    self.groupConversationInFolder.userDefinedName = @"groupConversationInFolder";
    self.groupConversationInFolder.labels = [NSSet setWithObject:folder];
    
    self.oneToOneConversation = [self createConversation];
    self.oneToOneConversation.conversationType = ZMConversationTypeOneOnOne;
    self.oneToOneConversation.connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    self.oneToOneConversation.connection.status = ZMConnectionStatusAccepted;
    self.oneToOneConversation.userDefinedName = @"oneToOneConversation";
    
    self.oneToOneConversationInFolder = [self createConversation];
    self.oneToOneConversationInFolder.conversationType = ZMConversationTypeOneOnOne;
    self.oneToOneConversationInFolder.connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    self.oneToOneConversationInFolder.connection.status = ZMConnectionStatusAccepted;
    self.oneToOneConversationInFolder.userDefinedName = @"oneToOneConversationInFolder";
    self.oneToOneConversationInFolder.labels = [NSSet setWithObject:folder];
    
    self.oneToOneConversationInTeam = [self createConversation];
    self.oneToOneConversationInTeam.conversationType = ZMConversationTypeGroup;
    self.oneToOneConversationInTeam.userDefinedName = nil;
    self.oneToOneConversationInTeam.team = team;
    [self.oneToOneConversationInTeam.mutableLastServerSyncedActiveParticipants addObject:otherUser];
    
    self.invalidConversation = [self createConversation];
    self.invalidConversation.conversationType = ZMConversationTypeInvalid;
    self.invalidConversation.userDefinedName = @"invalidConversation";
    
    self.clearedConversation = [self createConversation];
    self.clearedConversation.conversationType = ZMConversationTypeOneOnOne;
    self.clearedConversation.connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    self.clearedConversation.connection.status = ZMConnectionStatusAccepted;
    self.clearedConversation.userDefinedName = @"clearedConversation";
    self.clearedConversation.clearedTimeStamp = self.clearedConversation.lastServerTimeStamp;
    self.clearedConversation.isArchived = YES;
    
    self.favoritedConversation = [self createConversation];
    self.favoritedConversation.conversationType = ZMConversationTypeGroup;
    self.favoritedConversation.userDefinedName = @"favoritedConversation";
    self.favoritedConversation.isFavorite = YES;
    
    self.serviceConversation = [self createConversation];
    self.serviceConversation.conversationType = ZMConversationTypeGroup;
    self.serviceConversation.userDefinedName = nil;
    self.serviceConversation.team = team;
    [self.serviceConversation.mutableLastServerSyncedActiveParticipants addObject:serviceUser];

    [self.uiMOC saveOrRollback];
}

- (void)tearDown
{
    WaitForAllGroupsToBeEmpty(0.5);
    
    self.invalidConversation = nil;
    self.groupConversation = nil;
    self.incomingPendingConnectionConversation = nil;
    self.outgoingPendingConnectionConversation = nil;
    self.archivedOneToOneConversation = nil;
    self.archivedGroupConversation = nil;
    self.oneToOneConversation = nil;
    self.oneToOneConversationInTeam = nil;
    self.clearedConversation = nil;
    self.favoritedConversation = nil;
    self.serviceConversation = nil;
    self.conversations = nil;
    
    [super tearDown];
}

- (void)testThatItReturnsAllConversations;
{
    // when
    ZMConversationList *list = self.uiMOC.conversationListDirectory.conversationsIncludingArchived;
    NSSet *expected = [NSSet setWithArray:@[self.archivedGroupConversation,
                                            self.archivedOneToOneConversation,
                                            self.groupConversation,
                                            self.groupConversationInFolder,
                                            self.oneToOneConversation,
                                            self.oneToOneConversationInFolder,
                                            self.oneToOneConversationInTeam,
                                            self.outgoingPendingConnectionConversation,
                                            self.favoritedConversation,
                                            self.serviceConversation]];
    // then
    
    XCTAssertEqualObjects([NSSet setWithArray:list], expected);
}

//- (void)testThatItReturnsUnarchivedConversations;
//{
//    // when
//    ZMConversationList *list = self.uiMOC.conversationListDirectory.unarchivedConversations;
//    NSSet *expected = [NSSet setWithArray:@[self.groupConversation,
//                                            self.oneToOneConversation,
//                                            self.outgoingPendingConnectionConversation,
//                                            self.favoritedConversation,
//                                            self.groupConversationInFolder,
//                                            self.oneToOneConversationInFolder,
//                                            self.oneToOneConversationInTeam,
//                                            self.serviceConversation]];
//
//    // then
//    XCTAssertEqualObjects([NSSet setWithArray:list], expected);
//}

- (void)testThatItReturnsArchivedConversations;
{
    // when
    ZMConversationList *list = self.uiMOC.conversationListDirectory.archivedConversations;
    NSSet *expected = [NSSet setWithArray:@[self.archivedGroupConversation, self.archivedOneToOneConversation]];
    
    // then
    XCTAssertEqualObjects([NSSet setWithArray:list], expected);
}

- (void)testThatItReturnsPendingConversations;
{
    // when
    ZMConversationList *list = self.uiMOC.conversationListDirectory.pendingConnectionConversations;
    NSSet *expected = [NSSet setWithArray:@[self.incomingPendingConnectionConversation]];
    
    // then
    XCTAssertEqualObjects([NSSet setWithArray:list], expected);
}

- (void)testThatItKeepsReturningTheSameObject
{
    // when
    ZMConversationList * list1 = self.uiMOC.conversationListDirectory.conversationsIncludingArchived;
    ZMConversationList * list2 = self.uiMOC.conversationListDirectory.conversationsIncludingArchived;
    
    //then
    XCTAssertEqual(list1, list2);
}

- (void)testThatItReturnsClearedConversations
{
    // when
    ZMConversationList *list = self.uiMOC.conversationListDirectory.clearedConversations;
    NSSet *expected = [NSSet setWithArray:@[self.clearedConversation]];
    
    // then
    XCTAssertEqualObjects([NSSet setWithArray:list], expected);
}

- (void)testThatItNotReturnsClearedConversationsIn_ConversationsIncludingArchived
{
    // when
    ZMConversationList *list = self.uiMOC.conversationListDirectory.conversationsIncludingArchived;
    NSSet *expected = [NSSet setWithArray:@[self.clearedConversation]];
    
    // then
    // cleared conversations should not be included in conversationsIncludingArchived
    XCTAssertFalse([[NSSet setWithArray:list] intersectsSet:expected]);
}

- (void)testThatItsReturnsGroupConversations
{
    // when
    ZMConversationList *list = self.uiMOC.conversationListDirectory.groupConversations;
    NSSet *expected = [NSSet setWithArray:@[self.groupConversation, self.favoritedConversation]];
    
    // then
    XCTAssertEqualObjects([NSSet setWithArray:list], expected);
}

- (void)testThatItsReturnsOneToOneConversations
{
    // when
    ZMConversationList *list = self.uiMOC.conversationListDirectory.oneToOneConversations;
    NSSet *expected = [NSSet setWithArray:@[self.oneToOneConversation, self.oneToOneConversationInTeam, self.outgoingPendingConnectionConversation, self.serviceConversation]];
    
    // then
    XCTAssertEqualObjects([NSSet setWithArray:list], expected);
}

- (void)testThatItReturnsFavoritedConveration
{
//    // when
//    ZMConversationList *list = self.uiMOC.conversationListDirectory.favoriteConversations;
//    NSSet *expected = [NSSet setWithArray:@[self.favoritedConversation]];
//
//    // then
//    XCTAssertEqualObjects([NSSet setWithArray:list], expected);
}

//- (void)testThatAllListsAreIncluded
//{
//    ZMConversationListDirectory *directory = self.uiMOC.conversationListDirectory;
//    // when & then
//    XCTAssertTrue([directory.allConversationLists containsObject:directory.unarchivedConversations]);
//    XCTAssertTrue([directory.allConversationLists containsObject:directory.conversationsIncludingArchived]);
//    XCTAssertTrue([directory.allConversationLists containsObject:directory.archivedConversations]);
//    XCTAssertTrue([directory.allConversationLists containsObject:directory.pendingConnectionConversations]);
//    XCTAssertTrue([directory.allConversationLists containsObject:directory.clearedConversations]);
//    XCTAssertTrue([directory.allConversationLists containsObject:directory.oneToOneConversations]);
//    XCTAssertTrue([directory.allConversationLists containsObject:directory.groupConversations]);
//}

@end
