//
// 


@import WireTransport;

#import "ZMConversation+Transport.h"
#import "ZMConversation+Internal.h"
#import "ZMUser+Internal.h"
#import "ZMMessage+Internal.h"
#import "ZMUpdateEvent+WireDataModel.h"
#import <WireDataModel/WireDataModel-Swift.h>

static NSString* ZMLogTag ZM_UNUSED = @"Conversations";

static NSString *const ConversationInfoNameKey = @"name";
static NSString *const ConversationInfoTypeKey = @"type";
static NSString *const ConversationInfoIDKey = @"id";

static NSString *const ConversationInfoOthersKey = @"others";
static NSString *const ConversationInfoMembersKey = @"members";
static NSString *const ConversationInfoCreatorKey = @"creator";
static NSString *const ConversationInfoTeamIdKey = @"team";
static NSString *const ConversationInfoAccessModeKey = @"access";
static NSString *const ConversationInfoAccessRoleKey = @"access_role";
static NSString *const ConversationInfoMessageTimer = @"message_timer";
static NSString *const ConversationInfoReceiptMode = @"receipt_mode";

NSString *const ZMConversationInfoOTRMutedValueKey = @"otr_muted";
NSString *const ZMConversationInfoOTRMutedStatusValueKey = @"otr_muted_status";
NSString *const ZMConversationInfoOTRMutedReferenceKey = @"otr_muted_ref";
NSString *const ZMConversationInfoOTRArchivedValueKey = @"otr_archived";
NSString *const ZMConversationInfoOTRArchivedReferenceKey = @"otr_archived_ref";


static NSString *const ConversationInfoAutoReplyKey = @"auto_reply";

NSString *const ZMConversationInfoPlaceTopKey = @"place_top";
NSString *const ZMConversationInfoOTRSelfRemarkBoolKey = @"alias_name";
NSString *const ZMConversationInfoOTRSelfRemarkReferenceKey = @"alias_name_ref";
NSString *const ZMConversationInfoOTRSelfVerifyKey = @"confirm";
NSString *const ZMConversationInfoMemberInviteVerfyKey = @"memberjoin_confirm";
NSString *const ZMConversationInfoOTRCreatorChangeKey = @"new_creator";
NSString *const ZMConversationInfoBlockTimeKey = @"block_time";
NSString *const ZMConversationInfoBlockDurationKey = @"block_duration";
NSString *const ZMConversationInfoOpt_idKey = @"opt_id";
NSString *const ZMConversationInfoBlockUserKey = @"block_user";
NSString *const ZMConversationInfoOratorKey = @"orator";
NSString *const ZMConversationInfoManagerKey = @"manager";
NSString *const ZMConversationInfoManagerAddKey = @"man_add";
NSString *const ZMConversationInfoManagerDelKey = @"man_del";
NSString *const ZMConversationInfoOTRCanAddKey = @"addright";
NSString *const ZMCOnversationInfoOTROpenUrlJoinKey = @"url_invite";
NSString *const ZMCOnversationInfoOTRAllowViewMembersKey = @"viewmem";
NSString *const ZMConversationInfoIsAllowMemberAddEachOtherKey = @"add_friend";
NSString *const ZMConversationInfoIsVisibleForMemberChangeKey = @"view_chg_mem_notify";
NSString *const ZMConversationInfoIsMessageVisibleOnlyManagerAndCreatorKey = @"msg_only_to_manager";
NSString *const ZMConversationInfoAnnouncementKey = @"advisory";
NSString *const ZMConversationInfoOpenScreenShotKey = @"openScreenShot";
NSString *const ZMConversationBlockedKey = @"blocked";
NSString *const ZMConversationShowMemsumKey = @"show_memsum";
NSString *const ZMConversationEnabledEditMsgKey = @"enabled_edit_msg";
NSString *const ZMConversationAssistantBotKey = @"assistant_bot";
NSString *const ZMConversationAssistantBotOptKey = @"assistant_bot_opt";
NSString *const ZMConversationPersonalEnableEditMsgKey = @"personal_enabled_edit_msg";

@implementation ZMConversation (Transport)

- (void)updateClearedFromPostPayloadEvent:(ZMUpdateEvent *)event
{
    if (event.timeStamp != nil) {
        [self updateCleared:event.timeStamp synchronize:YES];
    }
}

- (void)updateWithUpdateEvent:(ZMUpdateEvent *)updateEvent
{
    if (updateEvent.timeStamp != nil) {
        [self updateServerModified:updateEvent.timeStamp];
    }
}

- (void)updateWithTransportData:(NSDictionary *)transportData serverTimeStamp:(NSDate *)serverTimeStamp;
{
    NSUUID *remoteId = [transportData uuidForKey:ConversationInfoIDKey];
    RequireString(remoteId == nil || [remoteId isEqual:self.remoteIdentifier],
                  "Remote IDs not matching for conversation: %s vs. %s",
                  remoteId.transportString.UTF8String,
                  self.remoteIdentifier.transportString.UTF8String);
    
    if (transportData[ConversationInfoNameKey] != [NSNull null]) {
        self.userDefinedName = [transportData stringForKey:ConversationInfoNameKey];
    }
    
    self.conversationType = [self conversationTypeFromTransportData:[transportData numberForKey:ConversationInfoTypeKey]];
 
//    self.isEnabledEditPersonalMsg = [transportData[ZMConversationPersonalEnableEditMsgKey] boolValue];

    self.isOpenScreenShot = [transportData[ZMConversationInfoOpenScreenShotKey] boolValue];

    self.showMemsum = [transportData[ZMConversationShowMemsumKey] boolValue];

    self.enabledEditMsg = [transportData[ZMConversationEnabledEditMsgKey] boolValue];

    self.isAllowViewMembers = [transportData[ZMCOnversationInfoOTRAllowViewMembersKey] boolValue];

    self.isOpenUrlJoin = [transportData[ZMCOnversationInfoOTROpenUrlJoinKey] boolValue];

    self.isOpenCreatorInviteVerify = [transportData[ZMConversationInfoOTRSelfVerifyKey] boolValue];

    self.isOpenMemberInviteVerify = [transportData[ZMConversationInfoMemberInviteVerfyKey] boolValue];

    self.isOnlyCreatorInvite = [transportData[ZMConversationInfoOTRCanAddKey] boolValue];

    NSNumber *forumIdNumber = [transportData optionalNumberForKey:@"forumid"];
    if (forumIdNumber != nil) {
        // Backend is sending the miliseconds, we need to convert to seconds.
        self.communityID = [forumIdNumber stringValue];
    }

    self.isMessageVisibleOnlyManagerAndCreator = [transportData[ZMConversationInfoIsMessageVisibleOnlyManagerAndCreatorKey] boolValue];

    //self.announcement = [transportData optionalStringForKey:ZMConversationInfoAnnouncementKey];
    

    self.isAllowMemberAddEachOther = [transportData[ZMConversationInfoIsAllowMemberAddEachOtherKey] boolValue];

    self.isVisibleForMemberChange = [transportData[ZMConversationInfoIsVisibleForMemberChangeKey] boolValue];
    self.isDisableSendMsg = !([[transportData optionalNumberForKey:ZMConversationInfoBlockTimeKey] integerValue] == 0);
    self.blocked = !([[transportData optionalNumberForKey:ZMConversationBlockedKey] integerValue] == 0);
    self.assistantBot = [transportData optionalStringForKey:@"assistant_bot"];

    if(transportData[@"assets"] != [NSNull null]) {
        NSArray *imgArr = [transportData arrayForKey:@"assets"];
        for (NSDictionary *dic in imgArr) {
            if ([dic[@"size"] isEqualToString:@"preview"]) {
                self.groupImageSmallKey = dic[@"key"];
            }
            if ([dic[@"size"] isEqualToString:@"complete"]) {
                self.groupImageMediumKey = dic[@"key"];
            }
        }
    }
    
    if (serverTimeStamp != nil) {
         // If the lastModifiedDate is non-nil, e.g. restore from backup, do not update the lastModifiedDate
        if (self.lastModifiedDate == nil) {
            [self updateLastModified:serverTimeStamp];
        }
        [self updateServerModified:serverTimeStamp];
    }
    
    NSDictionary *selfStatus = [[transportData dictionaryForKey:ConversationInfoMembersKey] dictionaryForKey:@"self"];
    if(selfStatus != nil) {
        [self updateSelfStatusFromDictionary:selfStatus timeStamp:nil previousLastServerTimeStamp:nil];
    }
    else {
        ZMLogError(@"Missing self status in conversation data");
    }
    
    NSUUID *creatorId = [transportData uuidForKey:ConversationInfoCreatorKey];
    if(creatorId != nil) {
        self.creator = [ZMUser userWithRemoteID:creatorId createIfNeeded:YES inConversation:self inContext:self.managedObjectContext];
    }
    
    NSDictionary *members = [transportData dictionaryForKey:ConversationInfoMembersKey];
    if(members != nil) {
    
        if (self.conversationType == ZMConversationTypeOneOnOne){
            NSArray *usersInfos = [members arrayForKey:ConversationInfoOthersKey];
            
            if (usersInfos.count > 1) {
                NSDictionary *userInfo = (NSDictionary *)usersInfos[0];
                self.autoReplyFromOther = [self autoReplyTypeFromTransportData:[userInfo optionalNumberForKey:ConversationInfoAutoReplyKey]];
            }
            
        }
        
        [self updateMembersWithPayload:members];
        [self updatePotentialGapSystemMessagesIfNeededWithUsers:self.activeParticipants];
    }
    else {
        ZMLogError(@"Invalid members in conversation JSON: %@", transportData);
    }

    NSUUID *teamId = [transportData optionalUuidForKey:ConversationInfoTeamIdKey];
    if (nil != teamId) {
        [self updateTeamWithIdentifier:teamId];
    }
    NSArray *orator = [transportData optionalArrayForKey:ZMConversationInfoOratorKey];
    if (orator && orator.count > 0) {
        [orator enumerateObjectsUsingBlock:^(NSString*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NOT_USED(idx);
            NOT_USED(stop);
            ZMUser *user = [ZMUser userWithRemoteID:[NSUUID uuidWithTransportString:obj] createIfNeeded:YES inConversation:self inContext:self.managedObjectContext];
            user.needsToBeUpdatedFromBackend = YES;
        }];
        self.orator = orator.set;
    }
    NSArray *managers = [transportData optionalArrayForKey:ZMConversationInfoManagerKey];
    if (managers && managers.count > 0) {
        [managers enumerateObjectsUsingBlock:^(NSString*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NOT_USED(idx);
            NOT_USED(stop);
            ZMUser *user = [ZMUser userWithRemoteID:[NSUUID uuidWithTransportString:obj] createIfNeeded:YES inConversation:self inContext:self.managedObjectContext];
            user.needsToBeUpdatedFromBackend = YES;
        }];
        self.manager = managers.set;
    }
    

    NSNumber *membersCountNumber = [transportData optionalNumberForKey:@"memsum"];
    self.membersCount = self.conversationType == ZMConversationTypeHugeGroup
    ? membersCountNumber.integerValue
    : (NSInteger)self.activeParticipants.count;
    

//    NSNumber *receiptMode = [transportData optionalNumberForKey:ConversationInfoReceiptMode];
//    if (nil != receiptMode) {
//        BOOL enabled = receiptMode.intValue > 0;
//        BOOL receiptModeChanged = !self.hasReadReceiptsEnabled && enabled;
//        self.hasReadReceiptsEnabled = enabled;
//
//        // We only want insert a system message if this is an existing conversation (non empty)
//        if (receiptModeChanged && self.lastMessage != nil) {
//            [self appendMessageReceiptModeIsOnMessageWithTimestamp:[NSDate date]];
//        }
//    }
    
    self.accessModeStrings = [transportData optionalArrayForKey:ConversationInfoAccessModeKey];
    self.accessRoleString = [transportData optionalStringForKey:ConversationInfoAccessRoleKey];
    
    NSNumber *messageTimerNumber = [transportData optionalNumberForKey:ConversationInfoMessageTimer];
    
    if (messageTimerNumber != nil) {
        // Backend is sending the miliseconds, we need to convert to seconds.
        self.syncedMessageDestructionTimeout = messageTimerNumber.doubleValue / 1000;
    }
    [UserAliasname createFromTransportData:transportData managedObjectContext:self.managedObjectContext inConversation:self];
    
    [UserDisableSendMsgStatus createFrom:transportData managedObjectContext:self.managedObjectContext inConversation:self.remoteIdentifier.transportString];
}

- (void)updateMembersWithPayload:(NSDictionary *)members
{
    NSArray *usersInfos = [members arrayForKey:ConversationInfoOthersKey];
    NSSet<ZMUser *> *lastSyncedUsers = [NSSet set];
    
    if (self.mutableLastServerSyncedActiveParticipants != nil) {
//        lastSyncedUsers = self.mutableLastServerSyncedActiveParticipants.set;
       
        NSMutableSet<ZMUser *> *activeParticipants = [self.mutableLastServerSyncedActiveParticipants.set mutableCopy];
        ZMUser *selfUser = [ZMUser selfUserInContext:self.managedObjectContext];
        if ([activeParticipants containsObject:selfUser]) {
            [activeParticipants removeObject:selfUser];
        }
        lastSyncedUsers = activeParticipants;
        
    }
    
    NSSet<NSUUID *> *participantUUIDs = [NSSet setWithArray:[usersInfos.asDictionaries mapWithBlock:^id(NSDictionary *userDict) {
        return [userDict uuidForKey:ConversationInfoIDKey];
    }]];
    
    NSMutableSet<ZMUser *> *participants = [[ZMUser usersWithRemoteIDs:participantUUIDs inContext:self.managedObjectContext] mutableCopy];
    
    if (participants.count != participantUUIDs.count) {
        
        // All users didn't exist so we need create the missing users
        
        NSSet<NSUUID *> *fetchedUUIDs = [NSSet setWithArray:[participants.allObjects mapWithBlock:^id(ZMUser *user) { return user.remoteIdentifier; }]];
        NSMutableSet<NSUUID *> *missingUUIDs = [participantUUIDs mutableCopy];
        [missingUUIDs minusSet:fetchedUUIDs];
                
        for (NSUUID *userId in missingUUIDs) {
            [participants addObject:[ZMUser userWithRemoteID:userId createIfNeeded:YES inConversation:self inContext:self.managedObjectContext]];
        }
    }
    
    NSMutableSet<ZMUser *> *addedParticipants = [participants mutableCopy];
    [addedParticipants minusSet:lastSyncedUsers];
    NSMutableSet<ZMUser *> *removedParticipants = [lastSyncedUsers mutableCopy];
    [removedParticipants minusSet:participants];
    
    ZMLogDebug(@"updateMembersWithPayload (%@) added = %lu removed = %lu", self.remoteIdentifier.transportString, (unsigned long)addedParticipants.count, (unsigned long)removedParticipants.count);
    
    [self internalAddParticipants:addedParticipants.allObjects];
    [self internalRemoveParticipants:removedParticipants.allObjects sender:[ZMUser selfUserInContext:self.managedObjectContext]];
}

- (void)updateTeamWithIdentifier:(NSUUID *)teamId
{
    VerifyReturn(nil != teamId);
    self.teamRemoteIdentifier = teamId;
    self.team = [Team fetchOrCreateTeamWithRemoteIdentifier:teamId createIfNeeded:NO inContext:self.managedObjectContext created:nil];
}

- (void)updatePotentialGapSystemMessagesIfNeededWithUsers:(NSSet <ZMUser *>*)users
{
    if (self.conversationType == ZMConvTypeHugeGroup) {
        return;
    }
//    ZMSystemMessage *latestSystemMessage = [ZMSystemMessage fetchLatestPotentialGapSystemMessageInConversation:self];
//    if (nil == latestSystemMessage) {
//        return;
//    }
//    if (users.count == 0 || latestSystemMessage.users.count == 0) {
//        return; 
//    }
//
//    NSMutableSet <ZMUser *>* removedUsers = latestSystemMessage.users.mutableCopy;
//    [removedUsers minusSet:users];
//
//    NSMutableSet <ZMUser *>* addedUsers = users.mutableCopy;
//    [addedUsers minusSet:latestSystemMessage.users];
//
//    latestSystemMessage.addedUsers = addedUsers;
//    latestSystemMessage.removedUsers = removedUsers;
//    [latestSystemMessage updateNeedsUpdatingUsersIfNeeded];
}

/// Pass timestamp when the timestamp equals the time of the lastRead / cleared event, otherwise pass nil
- (void)updateSelfStatusFromDictionary:(NSDictionary *)dictionary timeStamp:(NSDate *)timeStamp previousLastServerTimeStamp:(NSDate *)previousLastServerTimestamp
{
    self.isSelfAnActiveMember = YES;
    
    [self updateMutedStatusWithPayload:dictionary];
    if ([self updateIsArchivedWithPayload:dictionary] && self.isArchived && previousLastServerTimestamp != nil) {
        if (timeStamp != nil && self.clearedTimeStamp != nil && [self.clearedTimeStamp isEqualToDate:previousLastServerTimestamp]) {
            [self updateCleared:timeStamp synchronize:NO];
        }
    }
    self.selfRemark = [dictionary optionalStringForKey:ZMConversationInfoOTRSelfRemarkReferenceKey];
    [self updateIsPlacedTopWithPayload:dictionary];
}

- (void)updateIsPlacedTopWithPayload:(NSDictionary *)dictionary
{
    if (dictionary[ZMConversationInfoPlaceTopKey] != nil && dictionary[ZMConversationInfoPlaceTopKey] != [NSNull null]) {
        self.isPlacedTop = [dictionary[ZMConversationInfoPlaceTopKey] boolValue];
    }
}

- (BOOL)updateIsArchivedWithPayload:(NSDictionary *)dictionary
{
    if (dictionary[ZMConversationInfoOTRArchivedReferenceKey] != nil && dictionary[ZMConversationInfoOTRArchivedReferenceKey] != [NSNull null]) {
        NSDate *silencedRef = [dictionary dateFor:ZMConversationInfoOTRArchivedReferenceKey];
        if (silencedRef != nil && [self updateArchived:silencedRef synchronize:NO]) {
            NSNumber *archived = [dictionary optionalNumberForKey:ZMConversationInfoOTRArchivedValueKey];
            self.internalIsArchived = [archived isEqual:@1];
            return YES;
        }
    }
    return NO;
}

- (ZMAutoReplyType)autoReplyTypeFromTransportData:(NSNumber *)autoReplyType
{
    int const t = [autoReplyType intValue];
    return (ZMAutoReplyType)t;
}

- (ZMConversationType)conversationTypeFromTransportData:(NSNumber *)transportType
{
    return [[self class] conversationTypeFromTransportData:transportType];
}

+ (ZMConversationType)conversationTypeFromTransportData:(NSNumber *)transportType
{
    int const t = [transportType intValue];
    switch (t) {
        case ZMConvTypeGroup:
            return ZMConversationTypeGroup;
        case ZMConvOneToOne:
            return ZMConversationTypeOneOnOne;
        case ZMConvConnection:
            return ZMConversationTypeConnection;
        case ZMConvTypeHugeGroup:
            return ZMConversationTypeHugeGroup;
        default:
            NOT_USED(ZMConvTypeSelf);
            return ZMConversationTypeSelf;
    }
}

- (BOOL)shouldAddEvent:(ZMUpdateEvent *)event
{
    NSDate *timeStamp = event.timeStamp;
    if (self.clearedTimeStamp != nil && timeStamp != nil &&
        [self.clearedTimeStamp compare:timeStamp] != NSOrderedAscending)
    {
        return NO;
    }
    if (self.conversationType == ZMConversationTypeSelf){
        return NO;
    }
    return YES;
}

@end
