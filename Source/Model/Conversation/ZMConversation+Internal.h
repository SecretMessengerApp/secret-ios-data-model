// 
// 


#import "ZMConversation.h"
#import "ZMManagedObject+Internal.h"
#import "ZMMessage.h"
#import "ZMConnection.h"
#import "ZMConversationSecurityLevel.h"

@import WireImages;

@class ZMClientMessage;
@class ZMAssetClientMessage;
@class ZMConnection;
@class ZMUser;
@class ZMConversationList;
@class ZMLastRead;
@class ZMCleared;
@class ZMUpdateEvent;
@class ZMLocationData;
@class ZMGenericMessage;
@class ZMSystemMessage;
@class Team;
@class UserAliasname;

NS_ASSUME_NONNULL_BEGIN
extern NSString *const ZMConversationConnectionKey;
extern NSString *const ZMConversationHasUnreadMissedCallKey;
extern NSString *const ZMConversationHasUnreadUnsentMessageKey;
extern NSString *const ZMConversationIsArchivedKey;
extern NSString *const ZMConversationIsSelfAnActiveMemberKey;
extern NSString *const ZMConversationMutedStatusKey;
extern NSString *const ZMConversationAllMessagesKey;
extern NSString *const ZMConversationHiddenMessagesKey;
extern NSString *const ZMConversationMembersAliasnameKey;
extern NSString *const ZMConversationLastServerSyncedActiveParticipantsKey;
extern NSString *const ZMConversationHasUnreadKnock;
extern NSString *const ZMConversationUserDefinedNameKey;
extern NSString *const ZMVisibleWindowLowerKey;
extern NSString *const ZMVisibleWindowUpperKey;
extern NSString *const ZMIsDimmedKey;
extern NSString *const ZMNormalizedUserDefinedNameKey;
extern NSString *const ZMConversationListIndicatorKey;
extern NSString *const ZMConversationConversationTypeKey;
extern NSString *const ZMConversationExternalParticipantsStateKey;

extern NSString *const ZMConversationLastReadServerTimeStampKey;
extern NSString *const ZMConversationLastServerTimeStampKey;
extern NSString *const ZMConversationClearedTimeStampKey;
extern NSString *const ZMConversationArchivedChangedTimeStampKey;
extern NSString *const ZMConversationSilencedChangedTimeStampKey;


extern NSString *const ZMNotificationConversationKey;
extern NSString *const ZMConversationRemoteIdentifierDataKey;
extern NSString *const TeamRemoteIdentifierDataKey;

extern const NSUInteger ZMConversationMaxTextMessageLength;
extern NSTimeInterval ZMConversationDefaultLastReadTimestampSaveDelay;
extern NSString *const ZMConversationEstimatedUnreadCountKey;

extern NSString *const ZMConversationInternalEstimatedUnreadSelfMentionCountKey;
extern NSString *const ZMConversationInternalEstimatedUnreadSelfReplyCountKey;
extern NSString *const ZMConversationInternalEstimatedUnreadCountKey;
extern NSString *const ZMConversationLastUnreadKnockDateKey;
extern NSString *const ZMConversationLastUnreadMissedCallDateKey;
extern NSString *const ZMConversationLastReadLocalTimestampKey;
extern NSString *const ZMConversationLegalHoldStatusKey;

extern NSString *const SecurityLevelKey;
extern NSString *const ZMConversationLabelsKey;


extern NSString *const ZMConversationAutoReplyKey;
extern NSString *const ZMConversationAutoReplyFromOtherKey;

extern NSString *const ZMConversationSelfRemarkKey;
extern NSString *const ZMConversationIsOpenCreatorInviteVerifyKey;

extern NSString *const ZMConversationIsOpenMemberInviteVerifyKey;
extern NSString *const ZMConversationOnlyCreatorInviteKey;
extern NSString *const ZMConversationOpenUrlJoinKey;
extern NSString *const ZMConversationAllowViewMembersKey;
extern NSString *const CreatorKey;
extern NSString *const LastVisibleMessage;
extern NSString *const LastModifiedDateKey;

extern NSString *const ZMConversationIsPlacedTopKey;
extern NSString *const ZMConversationIsNotDisturbKey;
extern NSString *const ZMConversationIsAllowMemberAddEachOtherKey;
extern NSString *const ZMConversationIsVisibleForMemberChangeKey;
extern NSString *const ZMConversationIsDisableSendMsgKey;
extern NSString *const ZMConversationManagerAddKey;
extern NSString *const ZMConversationManagerDelKey;
extern NSString *const ZMConversationIsMessageVisibleOnlyManagerAndCreatorKey;
extern NSString *const ZMConversationAnnouncementKey;
extern NSString *const ZMConversationPreviewAvatarKey;
extern NSString *const ZMConversationCompleteAvatarKey;
extern NSString *const ShowMemsumKey;
extern NSString *const EnabledEditMsgKey;
//extern NSString *const EnabledEditPersonalMsgKey;

NS_ASSUME_NONNULL_END

@interface ZMConversation (Internal)

+ (nullable instancetype)conversationNoRowCacheWithRemoteID:(nonnull NSUUID *)UUID createIfNeeded:(BOOL)create inContext:(nonnull NSManagedObjectContext *)moc;

+ (nullable instancetype)conversationWithRemoteID:(nonnull NSUUID *)UUID createIfNeeded:(BOOL)create inContext:(nonnull NSManagedObjectContext *)moc;
+ (nullable instancetype)conversationWithRemoteID:(nonnull NSUUID *)UUID createIfNeeded:(BOOL)create inContext:(nonnull NSManagedObjectContext *)moc created:(nullable BOOL *)created;
+ (nullable instancetype)insertGroupConversationIntoManagedObjectContext:(nonnull NSManagedObjectContext *)moc withParticipants:(nonnull NSArray *)participants;
+ (nullable instancetype)insertGroupConversationIntoManagedObjectContext:(nonnull NSManagedObjectContext *)moc withParticipants:(nonnull NSArray <ZMUser *>*)participants inTeam:(nullable Team *)team;
+ (nullable instancetype)insertGroupConversationIntoManagedObjectContext:(nonnull NSManagedObjectContext *)moc withParticipants:(nonnull NSArray <ZMUser *>*)participants name:(nullable NSString *)name inTeam:(nullable Team *)team;
+ (nullable instancetype)insertGroupConversationIntoManagedObjectContext:(nonnull NSManagedObjectContext *)moc withParticipants:(nonnull NSArray <ZMUser *>*)participants name:(nullable NSString *)name inTeam:(nullable Team *)team allowGuests:(BOOL)allowGuests;
+ (nullable instancetype)insertHugeGroupConversationIntoManagedObjectContext:(nonnull NSManagedObjectContext *)moc withParticipants:(nonnull NSArray <ZMUser *>*)participants name:(nullable NSString *)name inTeam:(nullable Team *)team allowGuests:(BOOL)allowGuests;
+ (nullable instancetype)insertGroupConversationIntoManagedObjectContext:(nonnull NSManagedObjectContext *)moc withParticipants:(nonnull NSArray <ZMUser *>*)participants name:(nullable NSString *)name inTeam:(nullable Team *)team allowGuests:(BOOL)allowGuests readReceipts:(BOOL)readReceipts;
+ (nullable instancetype)fetchOrCreateTeamConversationInManagedObjectContext:(nonnull NSManagedObjectContext *)moc withParticipant:(nonnull ZMUser *)participant team:(nonnull Team *)team;

+ (nonnull ZMConversationList *)conversationsIncludingArchivedInContext:(nonnull NSManagedObjectContext *)moc;
+ (nonnull ZMConversationList *)archivedConversationsInContext:(nonnull NSManagedObjectContext *)moc;
+ (nonnull ZMConversationList *)clearedConversationsInContext:(nonnull NSManagedObjectContext *)moc;
+ (nonnull ZMConversationList *)conversationsExcludingArchivedInContext:(nonnull NSManagedObjectContext *)moc;
+ (nonnull ZMConversationList *)pendingConversationsInContext:(nonnull NSManagedObjectContext *)moc;
+ (nonnull ZMConversationList *)hugeGroupConversationsInContext:(nonnull NSManagedObjectContext *)moc;
+ (nonnull ZMConversationList *)unreadMessageConversationsInContext:(nonnull NSManagedObjectContext *)moc;

+ (nonnull NSPredicate *)predicateForSearchQuery:(nonnull NSString *)searchQuery team:(nullable Team *)team;
+ (nonnull NSPredicate *)userDefinedNamePredicateForSearchString:(nonnull NSString *)searchString;

@property (readonly, nonatomic, nonnull) NSMutableOrderedSet *mutableLastServerSyncedActiveParticipants;

@property (nonatomic) BOOL internalIsArchived;

@property (nonatomic, nullable) NSDate *pendingLastReadServerTimestamp;
@property (nonatomic, nullable) NSDate *lastServerTimeStamp;
@property (nonatomic, nullable) NSDate *lastReadServerTimeStamp;
@property (nonatomic, nullable) NSDate *clearedTimeStamp;
@property (nonatomic, nullable) NSDate *archivedChangedTimestamp;
@property (nonatomic, nullable) NSDate *silencedChangedTimestamp;

@property (nonatomic, nullable) NSUUID *remoteIdentifier;
@property (nonatomic, nullable) NSUUID *teamRemoteIdentifier;
@property (readonly, nonatomic, nonnull) NSMutableSet<ZMMessage *> *mutableMessages;
@property (readonly, nonatomic, nonnull) NSSet<ZMMessage *> *hiddenMessages;
@property (nonatomic, nullable) ZMConnection *connection;
@property (readonly, nonatomic) enum ZMConnectionStatus relatedConnectionState; // This is a computed property, needed for snapshoting
@property (nonatomic, nonnull) ZMUser *creator;
@property (nonatomic, nullable) NSDate *lastModifiedDate;
@property (nonatomic) ZMConversationType conversationType;
@property (nonatomic, copy, nullable) NSString *normalizedUserDefinedName;
@property (nonatomic) NSTimeInterval lastReadTimestampSaveDelay;
@property (nonatomic) int64_t lastReadTimestampUpdateCounter;

@property (nonatomic, nullable) NSDate *previewAvatarData;
@property (nonatomic, nullable) NSDate *completeAvatarData;
/**
    Appends the given message in the conversation.
 
    @param message The message that should be inserted.
*/
- (void)appendMessage:(nonnull ZMMessage *)message;

- (void)mergeWithExistingConversationWithRemoteID:(nonnull NSUUID *)remoteID;


+ (nonnull NSUUID *)selfConversationIdentifierInContext:(nonnull NSManagedObjectContext *)context;
+ (nonnull ZMConversation *)selfConversationInContext:(nonnull NSManagedObjectContext *)managedObjectContext;

/// Appends a new message to the conversation.
/// @param genericMessage the generic message that should be appended
/// @param expires wether the message should expire or tried to be send infinitively
/// @param hidden wether the message should be hidden in the conversation or not
- (nullable ZMClientMessage *)appendClientMessageWithGenericMessage:(nonnull ZMGenericMessage *)genericMessage expires:(BOOL)expires hidden:(BOOL)hidden;

/// Appends a new message to the conversation.
/// @param genericMessage the generic message that should be appended
- (nullable ZMClientMessage *)appendClientMessageWithGenericMessage:(nonnull ZMGenericMessage *)genericMessage;

/// Appends a new message to the conversation.
/// @param client message that should be appended
- (nonnull ZMClientMessage *)appendMessage:(nonnull ZMClientMessage *)clientMessage expires:(BOOL)expires hidden:(BOOL)hidden;

- (nullable ZMAssetClientMessage *)appendAssetClientMessageWithNonce:(nonnull NSUUID *)nonce imageData:(nonnull NSData *)imageData isOriginal:(BOOL)isOriginal;

- (void)unarchiveIfNeeded;

@end


@interface ZMConversation (SelfConversation)

/// Create and append to self conversation a ClientMessage that has generic message data built with the given data
+ (nullable ZMClientMessage *)appendSelfConversationWithGenericMessage:(nonnull ZMGenericMessage *)genericMessage managedObjectContext:(nonnull NSManagedObjectContext *)moc;

+ (nullable ZMClientMessage *)appendSelfConversationWithLastReadOfConversation:(nonnull ZMConversation *)conversation;
+ (nullable ZMClientMessage *)appendSelfConversationWithClearedOfConversation:(nonnull ZMConversation *)conversation;

+ (void)updateConversationWithZMLastReadFromSelfConversation:(nonnull ZMLastRead *)lastRead inContext:(nonnull NSManagedObjectContext *)context;
+ (void)updateConversationWithZMClearedFromSelfConversation:(nonnull ZMCleared *)cleared inContext:(nonnull NSManagedObjectContext *)context;

@end


@interface ZMConversation (ParticipantsInternal)

- (void)internalAddParticipants:(nonnull NSArray<ZMUser *> *)participants;
- (void)internalRemoveParticipants:(nonnull NSArray<ZMUser *> *)participants sender:(nonnull ZMUser *)sender;

@property (nonatomic) BOOL isSelfAnActiveMember; ///< whether the self user is an active member (as opposed to a past member)
@property (nonatomic, nonnull) NSOrderedSet<ZMUser *> *lastServerSyncedActiveParticipants;

@end

@interface NSUUID (ZMSelfConversation)

- (BOOL)isSelfConversationRemoteIdentifierInContext:(nonnull NSManagedObjectContext *)moc;

@end


@interface ZMConversation (Optimization)

+ (void)refreshObjectsThatAreNotNeededInSyncContext:(nonnull NSManagedObjectContext *)managedObjectContext;
@end


@interface ZMConversation (CoreDataGeneratedAccessors)

// CoreData autogenerated methods
- (void)addHiddenMessagesObject:(nonnull ZMMessage *)value;
- (void)removeHiddenMessagesObject:(nonnull ZMMessage *)value;
- (void)addHiddenMessages:(nonnull NSSet<ZMMessage *> *)values;
- (void)removeHiddenMessages:(nonnull NSSet<ZMMessage *> *)values;
- (void)addAllMessagesObject:(nonnull ZMMessage *)value;
- (void)removeAllMessagesObject:(nonnull ZMMessage *)value;
- (void)addAllMessages:(nonnull NSSet<ZMMessage *> *)values;
- (void)removeAllMessages:(nonnull NSSet<ZMMessage *> *)values;
@end

