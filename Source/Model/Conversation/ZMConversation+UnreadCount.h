// 
// 


@class ZMConversation;
@class ZMMessage;

@interface ZMConversation (UnreadCount)

/// internalEstimatedUnreadCount can only be set from the syncMOC
/// It is calculated by counting the unread messages which should generate an unread dot
@property (nonatomic) int64_t internalEstimatedUnreadCount;

/// internalEstimatedUnreadSelfMentionCount can only be set from the syncMOC
/// It is calculated by counting the unread messages which mention the self user
@property (nonatomic) int64_t internalEstimatedUnreadSelfMentionCount;

/// internalEstimatedUnreadSelfReplyCount can only be set from the syncMOC
/// It is calculated by counting the unread messages which reply to the self user
@property (nonatomic) int64_t internalEstimatedUnreadSelfReplyCount;

/// hasUnreadUnsentMessage is set when a message expires
/// and reset when the visible window changes
@property (nonatomic) BOOL hasUnreadUnsentMessage;

@property (nonatomic, readonly) BOOL hasUnreadMessagesInOtherConversations;

@property (nonatomic, readonly) ZMConversationListIndicator unreadListIndicator;
+ (NSSet *)keyPathsForValuesAffectingUnreadListIndicator;

/// Predicate for conversations that will be considered unread for the purpose of the badge count
+ (NSPredicate *)predicateForConversationConsideredUnread;

/// Predicate for conversations that will be considered unread for the purpose of the back arrow dot
+ (NSPredicate *)predicateForConversationConsideredUnreadExcludingSilenced;

/// Count of unread conversations (exluding silenced converations)
+ (NSUInteger)unreadConversationCountInContext:(NSManagedObjectContext *)moc;

/// Count of unread conversations (excluding silenced conversations)
+ (NSUInteger)unreadConversationCountExcludingSilencedInContext:(NSManagedObjectContext *)moc
                                                      excluding:(ZMConversation *)conversation;

@end


/// use this for testing only
@interface ZMConversation (Internal_UnreadCount)

/// lastUnreadKnockDate can only be set from the syncMOC
/// if this is nil, there is no unread knockMessage
@property (nonatomic) NSDate *lastUnreadKnockDate;
/// lastUnreadMissedCallDate can only be set from the syncMOC
/// if this is nil, there is no unread missed call
@property (nonatomic) NSDate *lastUnreadMissedCallDate;


@property (nonatomic, readonly) BOOL hasUnreadKnock;
@property (nonatomic, readonly) BOOL hasUnreadMissedCall;

@end

