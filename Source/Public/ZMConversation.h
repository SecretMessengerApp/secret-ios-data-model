// 
// 


@import WireSystem;

#import "ZMManagedObject.h"
#import "ZMMessage.h"
#import "ZMManagedObjectContextProvider.h"


@class ZMUser;
@class ZMMessage;
@class ZMTextMessage;
@class ZMImageMessage;
@class ZMKnockMessage;
@class ZMConversationList;
@class ZMFileMetadata;
@class ZMLocationData;
@class LinkMetadata;
@class Team;
@class Label;

@class UserAliasname;
@class ZMWebApp;
@class UserDisableSendMsgStatus;


@protocol ZMConversationMessage;

typedef NS_CLOSED_ENUM(int16_t, ZMConversationType) {
    ZMConversationTypeInvalid = 0,

    ZMConversationTypeSelf,
    ZMConversationTypeOneOnOne,
    ZMConversationTypeGroup,
    ZMConversationTypeConnection, // Incoming & outgoing connection request
    ZMConversationTypeHugeGroup, // type=5
};

/// The current indicator to be shown for a conversation in the conversation list.
typedef NS_ENUM(int16_t, ZMConversationListIndicator) {
    ZMConversationListIndicatorInvalid = 0,
    ZMConversationListIndicatorNone,
    ZMConversationListIndicatorUnreadSelfMention,
    ZMConversationListIndicatorUnreadSelfReply,
    ZMConversationListIndicatorUnreadMessages,
    ZMConversationListIndicatorKnock,
    ZMConversationListIndicatorMissedCall,
    ZMConversationListIndicatorExpiredMessage,
    ZMConversationListIndicatorActiveCall, ///< Ringing or talking in call.
    ZMConversationListIndicatorInactiveCall, ///< Other people are having a call but you are not in it.
    ZMConversationListIndicatorPending
};


typedef NS_ENUM(int16_t, ZMAutoReplyType) {
    ZMAutoReplyTypeClosed = 0,
    ZMAutoReplyTypeDarwin,
    ZMAutoReplyTypeAngel,
    ZMAutoReplyTypeCampusBelle,
    ZMAutoReplyTypeAI, // Incoming & outgoing connection request
    ZMAutoReplyTypeZuChongZhi
};

extern NSString * _Null_unspecified const ZMIsDimmedKey; ///< Specifies that a range in an attributed string should be displayed dimmed.

@interface ZMConversation : ZMManagedObject

@property (nonatomic, copy, nullable) NSString *userDefinedName;

@property (readonly, nonatomic) ZMConversationType conversationType;
@property (readonly, nonatomic) ZMConversationType pureConversationType;
@property (readonly, nonatomic, nullable) NSDate *lastModifiedDate;
@property (nonatomic, nullable) NSDate *disableSendLastModifiedDate;
@property (readonly, nonatomic, nonnull) NSOrderedSet *messages;
@property (readonly, nonatomic, nonnull) NSOrderedSet *messagesFilterService;
@property (readonly, nonatomic, nonnull) NSSet<ZMUser *> *activeParticipants;

@property (readonly, nonatomic, nonnull) NSSet<UserAliasname *> *membersAliasname;

@property (readonly, nonatomic, nonnull) NSSet<UserDisableSendMsgStatus *> *membersSendMsgStatuses;
@property (nonatomic) ServiceMessage * _Nullable lastServiceMessage;
@property (readonly, nonatomic, nonnull) NSSet<ZMMessage *> *allMessages;
@property (readonly, nonatomic, nonnull) NSArray<ZMUser *> *sortedActiveParticipants;
@property (readonly, nonatomic, nonnull) ZMUser *creator;
@property (nonatomic, readonly) BOOL isPendingConnectionConversation;
@property (nonatomic, readonly) NSUInteger estimatedUnreadCount;
@property (nonatomic, readonly) NSUInteger estimatedUnreadSelfMentionCount;
@property (nonatomic, readonly) NSUInteger estimatedUnreadSelfReplyCount;
@property (nonatomic, readonly) ZMConversationListIndicator conversationListIndicator;
@property (nonatomic, readonly) BOOL hasDraftMessage;
@property (nonatomic, nullable) Team *team;
@property (nonatomic, nonnull) NSSet<Label *> *labels;

/// This will return @c nil if the last added by self user message has not yet been sync'd to this device, or if the conversation has no self editable message.
@property (nonatomic, readonly, nullable) ZMMessage *lastEditableMessage;

@property (nonatomic) BOOL isArchived;

/// returns whether the user is allowed to write to this conversation
@property (nonatomic, readonly) BOOL isReadOnly;

/// For group conversation this will be nil, for one to one or connection conversation this will be the other user
@property (nonatomic, readonly, nullable) ZMUser *connectedUser;

@property (nonatomic) ZMAutoReplyType autoReply;

@property (nonatomic) ZMAutoReplyType autoReplyFromOther;

@property (nonatomic) BOOL isOpenUrlJoin;

@property (nonatomic, copy, nullable) NSString *joinGroupUrl;

@property (nonatomic, copy, nullable)NSString *selfRemark;

@property (nonatomic, nullable) NSDate *selfRemarkChangeTimestamp;

@property (nonatomic) BOOL isOpenCreatorInviteVerify;

@property (nonatomic) BOOL isOnlyCreatorInvite;

@property (nonatomic) BOOL isOpenMemberInviteVerify;

@property (nonatomic) BOOL isOpenScreenShot;

@property (nonatomic) NSInteger membersCount;

@property (nonatomic) BOOL isAllowViewMembers;

@property (nullable, nonatomic, copy) NSString *groupImageMediumKey;
@property (nullable, nonatomic, copy) NSString *groupImageSmallKey;

@property (nullable, nonatomic, copy) NSString *communityID;

@property (nonatomic) BOOL isPlacedTop;

@property (nonatomic) BOOL isAllowMemberAddEachOther;

@property (nonatomic) BOOL isVisibleForMemberChange;

@property (nonatomic) BOOL isDisableSendMsg;


@property (nullable, nonatomic, copy) NSString *assistantBot;

@property (nonatomic) int16_t triggerCode;

@property (nonatomic) NSSet<NSString *> * _Nullable orator;

@property (nonatomic) NSSet<NSString *> * _Nullable manager;
@property (nonatomic) NSSet<NSString *> * _Nullable managerAdd;
@property (nonatomic) NSSet<NSString *> * _Nullable managerDel;

@property (nonatomic) BOOL isMessageVisibleOnlyManagerAndCreator;

@property (nullable, nonatomic, copy) NSString *announcement;

@property (nonatomic) BOOL isReadAnnouncement;

@property (nonatomic) NSDate * _Nullable lastServiceMessageTimeStamp;

@property (nonatomic) BOOL isServiceNotice;


@property (nonatomic, nullable) NSDate *creatorChangeTimestamp;


@property (nonatomic, nullable) ZMMessage *lastVisibleMessage;


@property (nonatomic) BOOL blocked;
@property (nonatomic) ServiceMessage * _Nullable blockWarningMessage;
@property (nonatomic) NSDate * _Nullable blockWarningMessageTimeStamp;


@property (nonatomic) BOOL showMemsum;

@property (nonatomic) BOOL enabledEditMsg;

@property (nonatomic) BOOL isNotDisturb;


//@property (nonatomic) BOOL isEnabledEditPersonalMsg;


//@property (nonatomic) NSDate * _Nullable enabledEditPersonalMsgTimeStamp;

@property (nullable, nonatomic, copy) NSString *fifth_image;
@property (nullable, nonatomic, copy) NSString *fifth_name;
 
- (BOOL)canMarkAsUnread;
- (void)markAsUnread;

///// Insert a new group conversation into the user session
+ (nonnull instancetype)insertGroupConversationIntoUserSession:(nonnull id<ZMManagedObjectContextProvider> )session
                                              withParticipants:(nonnull NSArray<ZMUser *> *)participants
                                                        inTeam:(nullable Team *)team;

/// Insert a new group conversation with name into the user session
+ (nonnull instancetype)insertGroupConversationIntoUserSession:(nonnull id<ZMManagedObjectContextProvider> )session
                                              withParticipants:(nonnull NSArray<ZMUser *> *)participants
                                                          name:(nullable NSString*)name
                                                        inTeam:(nullable Team *)team;

/// Insert a new group conversation with name into the user session
+ (nonnull instancetype)insertGroupConversationIntoUserSession:(nonnull id<ZMManagedObjectContextProvider> )session
                                              withParticipants:(nonnull NSArray<ZMUser *> *)participants
                                                          name:(nullable NSString*)name
                                                        inTeam:(nullable Team *)team
                                                   allowGuests:(BOOL)allowGuests;

+ (nonnull instancetype)insertHugeGroupConversationIntoUserSession:(nonnull id<ZMManagedObjectContextProvider> )session
                                                  withParticipants:(nonnull NSArray<ZMUser *> *)participants
                                                              name:(nullable NSString*)name
                                                            inTeam:(nullable Team *)team
                                                       allowGuests:(BOOL)allowGuests;



- (void)deleteConversation;

/// If that conversation exists, it is returned, @c nil otherwise.
+ (nullable instancetype)existingOneOnOneConversationWithUser:(nonnull ZMUser *)otherUser inUserSession:(nonnull id<ZMManagedObjectContextProvider> )session;

@end

@interface ZMConversation (History)

/// This will reset the message history to the last message in the conversation.
- (void)clearMessageHistory;

/// UI should call this method on opening cleared conversation.
- (void)revealClearedConversation;

@end

@interface ZMConversation (Connections)

/// The message that was sent as part of the connection request.
@property (nonatomic, copy, readonly, nonnull) NSString *connectionMessage;

@end
