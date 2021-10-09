// 
// 


#import "ZMConversation.h"

@class ZMUpdateEvent;
typedef NS_ENUM(int, ZMBackendConversationType) {
    ZMConvTypeGroup = 0,
    ZMConvTypeSelf = 1,
    ZMConvOneToOne = 2,
    ZMConvConnection = 3,
    ZMConvTypeHugeGroup = 5, 
};

extern NSString *const ZMConversationInfoOTRMutedValueKey;
extern NSString *const ZMConversationInfoOTRMutedReferenceKey;
extern NSString *const ZMConversationInfoOTRMutedStatusValueKey;
extern NSString *const ZMConversationInfoOTRArchivedValueKey;
extern NSString *const ZMConversationInfoOTRArchivedReferenceKey;
//new add
extern NSString *const ZMConversationInfoOTRSelfRemarkBoolKey;
extern NSString *const ZMConversationInfoOTRSelfRemarkReferenceKey;
extern NSString *const ZMConversationInfoOTRSelfVerifyKey;
extern NSString *const ZMConversationInfoMemberInviteVerfyKey;
extern NSString *const ZMConversationInfoOTRCreatorChangeKey;
extern NSString *const ZMConversationInfoBlockTimeKey;
extern NSString *const ZMConversationInfoBlockDurationKey;
extern NSString *const ZMConversationInfoOpt_idKey;
extern NSString *const ZMConversationInfoBlockUserKey;
extern NSString *const ZMConversationInfoOratorKey;
extern NSString *const ZMConversationInfoManagerKey;
extern NSString *const ZMConversationInfoManagerAddKey;
extern NSString *const ZMConversationInfoManagerDelKey;
extern NSString *const ZMConversationInfoOTRCanAddKey;
extern NSString *const ZMCOnversationInfoOTROpenUrlJoinKey;
extern NSString *const ZMCOnversationInfoOTRAllowViewMembersKey;
extern NSString *const ZMConversationInfoIsAllowMemberAddEachOtherKey;
extern NSString *const ZMConversationInfoIsVisibleForMemberChangeKey;
extern NSString *const ZMConversationInfoPlaceTopKey;
extern NSString *const ZMConversationInfoIsMessageVisibleOnlyManagerAndCreatorKey;
extern NSString *const ZMConversationInfoAnnouncementKey;
extern NSString *const ZMConversationInfoOpenScreenShotKey;
extern NSString *const ZMConversationBlockedKey;
extern NSString *const ZMConversationShowMemsumKey;
extern NSString *const ZMConversationEnabledEditMsgKey;
extern NSString *const ZMConversationAssistantBotKey;
extern NSString *const ZMConversationAssistantBotOptKey;
extern NSString *const ZMConversationPersonalEnableEditMsgKey;

@interface ZMConversation (Transport)

- (void)updateWithUpdateEvent:(ZMUpdateEvent *)updateEvent;
- (void)updateClearedFromPostPayloadEvent:(ZMUpdateEvent *)event;
- (void)updateWithTransportData:(NSDictionary *)transportData serverTimeStamp:(NSDate *)serverTimeStamp;
- (void)updatePotentialGapSystemMessagesIfNeededWithUsers:(NSSet <ZMUser *>*)users;

/// Pass timeStamp when the timeStamp equals the time of the lastRead / cleared event, otherwise pass nil
- (void)updateSelfStatusFromDictionary:(NSDictionary *)dictionary timeStamp:(NSDate *)timeStamp previousLastServerTimeStamp:(NSDate *)previousLastServerTimestamp;

+ (ZMConversationType)conversationTypeFromTransportData:(NSNumber *)transportType;

- (BOOL)shouldAddEvent:(ZMUpdateEvent *)event;

@end
