// 
// 


#import "ZMConversationTests.h"
#import "ZMConversation+Transport.h"
#import "WireDataModelTests-Swift.h"
#import <WireDataModel/WireDataModel-Swift.h>

@interface ZMConversationParticipantsTests : ZMConversationTestsBase
@end

@implementation ZMConversationParticipantsTests

- (void)testThatItAddsMissingParticipantInGroup
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    
    // when
    [conversation addParticipantIfMissing:user date:[NSDate date]];
    
    // then
    [conversation.activeParticipants containsObject:user];
    ZMSystemMessage *systemMessage = (ZMSystemMessage *)conversation.lastMessage;
    XCTAssertEqual(systemMessage.systemMessageType, ZMSystemMessageTypeParticipantsAdded);
}

- (void)testThatItDoesntAddParticipantsAddedSystemMessageIfUserIsNotMissing
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    [conversation internalAddParticipants:@[user]];
    
    // when
    [conversation addParticipantIfMissing:user date:[NSDate date]];
    
    // then
    [conversation.activeParticipants containsObject:user];
    XCTAssertEqual(conversation.allMessages.count, 0lu);
}

- (void)testThatItAddsMissingParticipantInOneToOne
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeOneOnOne;
    
    // when
    [conversation addParticipantIfMissing:user date:[NSDate date]];
    
    // then
    [conversation.activeParticipants containsObject:user];
}

- (void)testThatItReturnsAllParticipantsAsActiveParticipantsInOneOnOneConversations
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeOneOnOne;
    
    ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    connection.status = ZMConnectionStatusAccepted;
    connection.to = user;
    connection.conversation = conversation;
    
    [self.uiMOC saveOrRollback];

    // then
    XCTAssertEqual(conversation.activeParticipants.count, 2u);
}


- (void)testThatItReturnsAllParticipantsAsActiveParticipantsInConnectionConversations
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeConnection;
    
    ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    connection.status = ZMConnectionStatusPending;
    connection.to = user;
    connection.conversation = conversation;
    
    [self.uiMOC saveOrRollback];
    
    // then
    XCTAssertEqual(conversation.activeParticipants.count, 2u);
}

- (void)testThatItReturnsSelfUserAsActiveParticipantsInSelfConversations
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeSelf;
    
    // then
    XCTAssertEqual(conversation.activeParticipants.count, 1u);
}

- (void)testThatItAddsParticipants
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    ZMUser *user1 = [self createUser];
    ZMUser *user2 = [self createUser];
    
    // when
    [conversation internalAddParticipants:@[user1]];
    [conversation internalAddParticipants:@[user2]];
    
    // then
    NSOrderedSet *expectedActiveParticipants = [NSOrderedSet orderedSetWithObjects:user1, user2, nil];
    XCTAssertEqualObjects(expectedActiveParticipants, conversation.lastServerSyncedActiveParticipants);
}

- (void)testThatItDoesNotUnarchiveTheConversationWhenTheSelfUserIsAddedIfMuted
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    conversation.isArchived = YES;
    conversation.mutedStatus = MutedMessageOptionValueAll;
    ZMUser *selfUser = [ZMUser selfUserInContext:self.uiMOC];
    selfUser.remoteIdentifier = [NSUUID createUUID];
    
    // when
    [conversation internalAddParticipants:@[selfUser]];
    WaitForAllGroupsToBeEmpty(0.5f);
    
    // then
    XCTAssertTrue(conversation.isArchived);
}

- (void)testThatItUnarchivesTheConversationWhenTheSelfUserIsAdded
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    conversation.isArchived = YES;
    ZMUser *selfUser = [ZMUser selfUserInContext:self.uiMOC];
    selfUser.remoteIdentifier = [NSUUID createUUID];

    // when
    [conversation internalAddParticipants:@[selfUser]];
    WaitForAllGroupsToBeEmpty(0.5f);
    
    // then
    XCTAssertFalse(conversation.isArchived);
}

- (void)testThatItCanRemoveTheSelfUser
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    ZMUser *user1 = [self createUser];
    ZMUser *selfUser = [ZMUser selfUserInContext:self.uiMOC];
    selfUser.remoteIdentifier = [NSUUID createUUID];
    
//    [conversation addParticipant:user1];
    [conversation internalAddParticipants:@[selfUser, user1]];
    
    XCTAssertTrue(conversation.isSelfAnActiveMember);
    
    // when
    [conversation internalRemoveParticipants:@[selfUser] sender:user1];
    WaitForAllGroupsToBeEmpty(0.5f);
    
    // then
    XCTAssertFalse(conversation.isSelfAnActiveMember);
}

- (void)testThatItDoesNothingForUnknownParticipants
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    ZMUser *user1 = [self createUser];
    ZMUser *user2 = [self createUser];
    ZMUser *user3 = [self createUser];
    ZMUser *unknownUser = [self createUser];
    
    [conversation internalAddParticipants:@[user1, user2, user3]];
    
    // when
    [conversation internalRemoveParticipants:@[unknownUser] sender:user1];
    
    // then
    NSSet *expectedActiveParticipants = [NSSet setWithObjects:user1, user2, user3, nil];
    XCTAssertEqualObjects(expectedActiveParticipants, conversation.lastServerSyncedActiveParticipants.set);
}

- (void)testThatActiveParticipantsContainsSelf
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    ZMUser *selfUser = [ZMUser selfUserInContext:self.uiMOC];
    
    // when
    conversation.isSelfAnActiveMember = YES;
    
    // then
    XCTAssertTrue([conversation.activeParticipants containsObject:selfUser]);
    
    // when
    conversation.isSelfAnActiveMember = NO;
    
    // then
    XCTAssertFalse([conversation.activeParticipants containsObject:selfUser]);
}

- (void)testThatOtherActiveParticipantsDoesNotContainSelf
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *selfUser = [ZMUser selfUserInContext:self.uiMOC];
    
    // when
    conversation.isSelfAnActiveMember = YES;
    
    // then
    XCTAssertFalse([conversation.lastServerSyncedActiveParticipants containsObject:selfUser]);
}

@end



@implementation ZMConversationParticipantsTests (ConnectedUser)

- (void)testThatTheConnectedUserIsNilForGroupConversation
{
    // when
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    [conversation.mutableLastServerSyncedActiveParticipants addObject:[ZMUser insertNewObjectInManagedObjectContext:self.uiMOC]];
    [conversation.mutableLastServerSyncedActiveParticipants addObject:[ZMUser insertNewObjectInManagedObjectContext:self.uiMOC]];
    
    // then
    XCTAssertNil(conversation.connectedUser);
}

- (void)testThatTheConnectedUserIsNilForSelfconversation
{
    // when
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeSelf;
    
    // then
    XCTAssertNil(conversation.connectedUser);
}

- (void)testThatWeHaveAConnectedUserForOneOnOneConversation
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeOneOnOne;
    ZMUser* user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    connection.to = user;
    
    // when
    connection.conversation = conversation;
    
    // then
    XCTAssertEqual(conversation.connectedUser, user);
}

- (void)testThatWeHaveAConnectedUserForConnectionConversation
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeConnection;
    ZMUser* user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    connection.to = user;
    
    // when
    connection.conversation = conversation;
    
    // then
    XCTAssertEqual(conversation.connectedUser, user);
}

@end


@implementation ZMConversationParticipantsTests (Sorting)

- (void)testThatItSortsParticipantsByFullName
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    NSUUID *uuid = NSUUID.createUUID;
    conversation.remoteIdentifier = uuid;
    
    ZMUser *selfUser = [ZMUser selfUserInContext:self.uiMOC];
    ZMUser *user1 = [self createUser];
    ZMUser *user2 = [self createUser];
    ZMUser *user3 = [self createUser];
    ZMUser *user4 = [self createUser];

    selfUser.name = @"Super User";
    user1.name = @"Hans im Glueck";
    user2.name = @"Anna Blume";
    user3.name = @"Susi Super";
    user4.name = @"Super Susann";
    
    [conversation internalAddParticipants:@[user1, user2, user3, user4]];
    [self.uiMOC saveOrRollback];
    
    NSArray *expected = @[user2, user1, user4, selfUser, user3];
    
    XCTAssertEqualObjects(conversation.sortedActiveParticipants, expected);
}

@end
