// 
// 


#import "ZMBaseManagedObjectTest.h"
#import <libkern/OSAtomic.h>
#import <CommonCrypto/CommonCrypto.h>

#import "ZMClientMessage.h"
#import "NSManagedObjectContext+zmessaging.h"
#import "NSManagedObjectContext+zmessaging-Internal.h"
#import "MockModelObjectContextFactory.h"
#import "ZMTestSession.h"

#import "ZMUser+Internal.h"
#import "ZMConversation+Internal.h"
#import "ZMMessage+Internal.h"
#import "ZMConversation+UnreadCount.h"

#import "NSString+RandomString.h"


@interface ZMBaseManagedObjectTest ()

@property (nonatomic) ZMTestSession *testSession;
@property (nonatomic) NSTimeInterval originalConversationLastReadTimestampTimerValue; // this will speed up the tests A LOT

@end


@implementation ZMBaseManagedObjectTest

- (BOOL)shouldUseRealKeychain;
{
    return NO;
}

- (BOOL)shouldUseInMemoryStore;
{
    return YES;
}

- (void)performPretendingUiMocIsSyncMoc:(void(^)(void))block;
{
    [self.testSession performPretendingUiMocIsSyncMoc:block];
}

- (void)performPretendingSyncMocIsUiMoc:(void(^)(void))block
{
    [self.testSession performPretendingSyncMocIsUiMoc:block];
}

- (void)setUp;
{
    [super setUp];
    
    self.testSession = [[ZMTestSession alloc] initWithDispatchGroup:self.dispatchGroup];
    self.testSession.shouldUseInMemoryStore = self.shouldUseInMemoryStore;
    self.testSession.shouldUseRealKeychain = self.shouldUseRealKeychain;
    
    [self performIgnoringZMLogError:^{
        [self.testSession prepareForTestNamed:self.name];
    }];
    
    NSString *testName = NSStringFromSelector(self.invocation.selector);
    NSString *methodName = [NSString stringWithFormat:@"setup%@%@", [testName substringToIndex:1].capitalizedString, [testName substringFromIndex:1]];
    SEL selector = NSSelectorFromString(methodName);
    if ([self respondsToSelector:selector]) {
        ZM_SILENCE_CALL_TO_UNKNOWN_SELECTOR([self performSelector:selector]);
    }
    
    [self setupTimers];

    WaitForAllGroupsToBeEmpty(500); // we want the test to get stuck if there is something wrong. Better than random failures
}

- (void)setupTimers 
{
    [self.syncMOC performGroupedBlockAndWait:^{
        [self.syncMOC zm_createMessageObfuscationTimer];
    }];
    [self.uiMOC zm_createMessageDeletionTimer];
}

- (void)tearDown;
{
    WaitForAllGroupsToBeEmpty(500); // we want the test to get stuck if there is something wrong. Better than random failures
    [self.testSession tearDown];
    self.testSession = nil;
    [StorageStack reset];
    [super tearDown];
}

- (NSManagedObjectContext *)uiMOC
{
    return self.testSession.uiMOC;
}

- (NSManagedObjectContext *)syncMOC
{
    return self.testSession.syncMOC;
}

- (NSManagedObjectContext *)searchMOC
{
    return self.testSession.searchMOC;
}

- (void)resetUIandSyncContextsAndResetPersistentStore:(BOOL)resetPersistentStore
{
    [self.testSession resetUIandSyncContextsAndResetPersistentStore:resetPersistentStore];
}


@end


@implementation ZMBaseManagedObjectTest (UserTesting)

- (void)setEmailAddress:(NSString *)emailAddress onUser:(ZMUser *)user;
{
    user.emailAddress = emailAddress;
}

- (void)setPhoneNumber:(NSString *)phoneNumber onUser:(ZMUser *)user;
{
    user.phoneNumber = phoneNumber;
}

@end


@implementation ZMBaseManagedObjectTest (FilesInCache)

- (void)wipeCaches
{
    [self.testSession wipeCaches];
}

@end


@implementation ZMBaseManagedObjectTest (OTR)

- (UserClient *)createSelfClient
{
    return [self createSelfClientOnMOC:self.uiMOC];
}

- (UserClient *)createSelfClientOnMOC:(NSManagedObjectContext *)moc
{
    __block ZMUser *selfUser = nil;
    
    selfUser = [ZMUser selfUserInContext:moc];
    selfUser.remoteIdentifier = selfUser.remoteIdentifier ?: [NSUUID createUUID];
    UserClient *selfClient = [UserClient insertNewObjectInManagedObjectContext:moc];
    selfClient.remoteIdentifier = [NSString createAlphanumericalString];
    selfClient.user = selfUser;
    
    [moc setPersistentStoreMetadata:selfClient.remoteIdentifier forKey:ZMPersistedClientIdKey];
    
    [self performPretendingUiMocIsSyncMoc:^{
        NSDictionary *payload = @{@"id": selfClient.remoteIdentifier, @"type": @"permanent", @"time": [[NSDate date] transportString]};
        NOT_USED([UserClient createOrUpdateSelfUserClient:payload context:moc]);
    }];
    
    [moc saveOrRollback];
    
    return selfClient;
}

- (UserClient *)createClientForUser:(ZMUser *)user createSessionWithSelfUser:(BOOL)createSessionWithSeflUser
{
    return [self createClientForUser:user createSessionWithSelfUser:createSessionWithSeflUser onMOC:self.uiMOC];
}

- (UserClient *)createClientForUser:(ZMUser *)user createSessionWithSelfUser:(BOOL)createSessionWithSeflUser onMOC:(NSManagedObjectContext *)moc
{
    if(user.remoteIdentifier == nil) {
        user.remoteIdentifier = [NSUUID createUUID];
    }
    UserClient *userClient = [UserClient insertNewObjectInManagedObjectContext:moc];
    userClient.remoteIdentifier = [NSString createAlphanumericalString];
    userClient.user = user;
    
    if (createSessionWithSeflUser) {
        UserClient *selfClient = [ZMUser selfUserInContext:moc].selfClient;
        [self performPretendingUiMocIsSyncMoc:^{
            NSError *error;
            NSString *key = [selfClient.keysStore lastPreKeyAndReturnError:&error];
            NOT_USED([selfClient establishSessionWithClient:userClient usingPreKey:key]);
        }];
    }
    return userClient;
}

- (ZMClientMessage *)createClientTextMessage
{
    return [self createClientTextMessageWithText:self.name];
}

- (ZMClientMessage *)createClientTextMessageWithText:(NSString *)text
{
    NSUUID *nonce = [NSUUID createUUID];
    ZMClientMessage *message = [[ZMClientMessage alloc] initWithNonce:nonce managedObjectContext:self.uiMOC];
    ZMGenericMessage *textMessage = [ZMGenericMessage messageWithContent:[ZMText textWith:text mentions:@[] linkPreviews:@[] replyingTo:nil] nonce:nonce];
    [message addData:textMessage.data];
    return message;
}

@end


@implementation  ZMBaseManagedObjectTest (SwiftBridgeConversation)

- (void)performChangesSyncConversation:(ZMConversation *)conversation
                            mergeBlock:(void(^)(void))mergeBlock
                           changeBlock:(void(^)(ZMConversation*))changeBlock
{
    BOOL isSyncContext = conversation.managedObjectContext.zm_isSyncContext;
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConversation *syncConv = conversation;
        if (!isSyncContext) {
            NSManagedObjectID *objectID = conversation.objectID;
            syncConv = (id)[self.syncMOC objectWithID:objectID];
        }
        changeBlock(syncConv);
        [self.syncMOC saveOrRollback];
    }];
    if (!isSyncContext) {
        if (mergeBlock) {
            mergeBlock();
        } else {
            [self.uiMOC refreshObject:conversation mergeChanges:YES];
        }
    }
}
- (void)simulateUnreadCount:(NSUInteger)unreadCount forConversation:(nonnull ZMConversation *)conversation mergeBlock:(void(^_Nullable)(void))mergeBlock;
{
    [self performChangesSyncConversation:conversation mergeBlock:mergeBlock changeBlock:^(ZMConversation * syncConv) {
        syncConv.internalEstimatedUnreadCount = [@(unreadCount) intValue];
    }];
}

- (void)simulateUnreadSelfMentionCount:(NSUInteger)unreadCount forConversation:(nonnull ZMConversation *)conversation mergeBlock:(void(^_Nullable)(void))mergeBlock;
{
    [self performChangesSyncConversation:conversation mergeBlock:mergeBlock changeBlock:^(ZMConversation * syncConv) {
        syncConv.internalEstimatedUnreadSelfMentionCount = [@(unreadCount) intValue];
    }];
}

- (void)simulateUnreadSelfReplyCount:(NSUInteger)unreadCount forConversation:(nonnull ZMConversation *)conversation mergeBlock:(void(^_Nullable)(void))mergeBlock;
{
    [self performChangesSyncConversation:conversation mergeBlock:mergeBlock changeBlock:^(ZMConversation * syncConv) {
        syncConv.internalEstimatedUnreadSelfReplyCount = [@(unreadCount) intValue];
    }];
}

- (void)simulateUnreadMissedCallInConversation:(nonnull ZMConversation *)conversation mergeBlock:(void(^_Nullable)(void))mergeBlock;
{
    [self performChangesSyncConversation:conversation mergeBlock:mergeBlock changeBlock:^(ZMConversation * syncConv) {
        syncConv.lastUnreadMissedCallDate = [NSDate date];
    }];
}

- (void)simulateUnreadMissedKnockInConversation:(nonnull ZMConversation *)conversation mergeBlock:(void(^_Nullable)(void))mergeBlock;
{
    [self performChangesSyncConversation:conversation mergeBlock:mergeBlock changeBlock:^(ZMConversation * syncConv) {
        syncConv.lastUnreadKnockDate = [NSDate date];
    }];
}

- (void)simulateUnreadCount:(NSUInteger)unreadCount forConversation:(ZMConversation *)conversation;
{
    [self simulateUnreadCount:unreadCount forConversation:conversation mergeBlock:nil];
}

- (void)simulateUnreadSelfMentionCount:(NSUInteger)unreadCount forConversation:(ZMConversation *)conversation;
{
    [self simulateUnreadSelfMentionCount:unreadCount forConversation:conversation mergeBlock:nil];
}

- (void)simulateUnreadSelfReplyCount:(NSUInteger)unreadCount forConversation:(ZMConversation *)conversation;
{
    [self simulateUnreadSelfReplyCount:unreadCount forConversation:conversation mergeBlock:nil];
}

- (void)simulateUnreadMissedCallInConversation:(ZMConversation *)conversation;
{
    [self simulateUnreadMissedCallInConversation:conversation mergeBlock:nil];
}

- (void)simulateUnreadMissedKnockInConversation:(ZMConversation *)conversation;
{
    [self simulateUnreadMissedKnockInConversation:conversation mergeBlock:nil];
}

@end
