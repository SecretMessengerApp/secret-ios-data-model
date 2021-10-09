// 
// 


@import WireTesting;
@import WireDataModel;

#import "NSManagedObjectContext+TestHelpers.h"
#import "ZMUser.h"


@class NSManagedObjectContext;
@class ZMManagedObject;
@class ZMUser;
@class ZMConversation;
@class ZMConnection;
@protocol ZMObjectStrategyDirectory;
@class ZMAssetClientMessage;
@class ZMTestSession;

@import WireCryptobox;
@import WireImages;
@class UserClient;

@class ZMClientMessage;

/// This is a base test class with utility stuff for all tests.
@interface ZMBaseManagedObjectTest : ZMTBaseTest


@property (nonatomic, readonly, nonnull) ZMTestSession *testSession;
@property (nonatomic, readonly, nonnull) NSManagedObjectContext *uiMOC;
@property (nonatomic, readonly, nonnull) NSManagedObjectContext *syncMOC;
@property (nonatomic, readonly, nonnull) NSManagedObjectContext *searchMOC;


/// reset ui and sync contexts
- (void)resetUIandSyncContextsAndResetPersistentStore:(BOOL)resetPersistantStore;

/// perform operations pretending that the uiMOC is a syncMOC
- (void)performPretendingUiMocIsSyncMoc:(nonnull void(^)(void))block;

/// perform operations pretending that the syncMOC is a uiMOC
- (void)performPretendingSyncMocIsUiMoc:(nonnull void(^)(void))block;

@end



@interface ZMBaseManagedObjectTest (UserTesting)

- (void)setEmailAddress:(nullable NSString *)emailAddress onUser:(nonnull ZMUser *)user;
- (void)setPhoneNumber:(nullable NSString *)phoneNumber onUser:(nonnull ZMUser *)user;

@end



@interface ZMBaseManagedObjectTest (FilesInCache)

/// Wipes the asset caches on the managed object contexts
- (void)wipeCaches;

@end


@interface ZMBaseManagedObjectTest (OTR)

- (nonnull UserClient *)createSelfClient;
- (nonnull UserClient *)createSelfClientOnMOC:(nonnull NSManagedObjectContext *)moc;

- (nonnull UserClient *)createClientForUser:(nonnull ZMUser *)user createSessionWithSelfUser:(BOOL)createSessionWithSeflUser;
- (nonnull UserClient *)createClientForUser:(nonnull ZMUser *)user createSessionWithSelfUser:(BOOL)createSessionWithSeflUser onMOC:(nonnull NSManagedObjectContext *)moc;

- (nonnull ZMClientMessage *)createClientTextMessage;
- (nonnull ZMClientMessage *)createClientTextMessageWithText:(nonnull NSString *)text;

@end


@interface ZMBaseManagedObjectTest (SwiftBridgeConversation)

- (void)simulateUnreadCount:(NSUInteger)unreadCount forConversation:(nonnull ZMConversation *)conversation;
- (void)simulateUnreadSelfMentionCount:(NSUInteger)unreadCount forConversation:(nonnull ZMConversation *)conversation;
- (void)simulateUnreadSelfReplyCount:(NSUInteger)unreadCount forConversation:(nonnull ZMConversation *)conversation;
- (void)simulateUnreadMissedCallInConversation:(nonnull ZMConversation *)conversation;
- (void)simulateUnreadMissedKnockInConversation:(nonnull ZMConversation *)conversation;

- (void)simulateUnreadCount:(NSUInteger)unreadCount forConversation:(nonnull ZMConversation *)conversation mergeBlock:(void(^_Nullable)(void))mergeBlock;
- (void)simulateUnreadSelfMentionCount:(NSUInteger)unreadCount forConversation:(nonnull ZMConversation *)conversation mergeBlock:(void(^_Nullable)(void))mergeBlock;
- (void)simulateUnreadSelfReplyCount:(NSUInteger)unreadCount forConversation:(nonnull ZMConversation *)conversation mergeBlock:(void(^_Nullable)(void))mergeBlock;
- (void)simulateUnreadMissedCallInConversation:(nonnull ZMConversation *)conversation mergeBlock:(void(^_Nullable)(void))mergeBlock;
- (void)simulateUnreadMissedKnockInConversation:(nonnull ZMConversation *)conversation mergeBlock:(void(^_Nullable)(void))mergeBlock;

@end

