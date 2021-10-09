// 
// 


#import "ZMOTRMessage.h"
#import "ZMGenericMessage+UpdateEvent.h"
#import "ZMConversation+Internal.h"
#import "ZMConversation+Transport.h"
#import <WireDataModel/WireDataModel-Swift.h>
#import "ZMGenericMessageData.h"


@import WireTransport;


NSString * const DeliveredKey = @"delivered";


@implementation ZMOTRMessage

- (NSString *)entityName;
{
    NSAssert(FALSE, @"Subclasses should override this method: [%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    return nil;
}

- (NSSet *)ignoredKeys;
{
    NSSet *keys = [super ignoredKeys];
    return [keys setByAddingObjectsFromArray:@[DeliveredKey, ZMMessageIsExpiredKey]];
}

- (void)missesRecipient:(UserClient *)recipient
{
    [self missesRecipients:[NSSet setWithObject:recipient]];
}

- (void)missesRecipients:(NSSet<UserClient *> *)recipients
{
    [[self mutableSetValueForKey:ZMMessageMissingRecipientsKey] addObjectsFromArray:recipients.allObjects];
}

- (void)doesNotMissRecipient:(UserClient *)recipient
{
    [self doesNotMissRecipients:[NSSet setWithObject:recipient]];
}

- (void)doesNotMissRecipients:(NSSet<UserClient *> *)recipients
{
    [[self mutableSetValueForKey:ZMMessageMissingRecipientsKey] minusSet:recipients];
}

- (ZMDeliveryState)deliveryState
{
    //we set server time stamp in awake from insert to be able to sort messages
    //probably we need to store "deliveryTimestamp" separately and check it here
    if (self.isExpired) {
        return ZMDeliveryStateFailedToSend;
    }
    else if (self.delivered == NO) {
        return ZMDeliveryStatePending;
    }
    else if (self.isSendRead) {
        return ZMDeliveryStateRead;
    }
    else if (self.isSendDelivered){
        return ZMDeliveryStateDelivered;
    }
    else {
        return ZMDeliveryStateSent;
    }
}

- (BOOL)isSent
{
    return self.delivered;
}

+ (NSSet *)keyPathsForValuesAffectingDeliveryState;
{
    return [[ZMMessage keyPathsForValuesAffectingValueForKey:ZMMessageDeliveryStateKey] setByAddingObject:DeliveredKey];
}

- (NSString *)dataSetDebugInformation
{
    return [[self.dataSet mapWithBlock:^NSString *(ZMGenericMessageData *msg) {
        return [NSString stringWithFormat:@"<%@>: %@", NSStringFromClass(ZMGenericMessageData.class), msg.genericMessage];
    }].array componentsJoinedByString:@"\n"];
}

- (void)markAsSent
{
    self.delivered = YES;
    [super markAsSent];
}

- (void)expire
{
    [super expire];
}

- (void)resend
{
    self.delivered = NO;
    [super resend];
}

- (void)updateWithGenericMessage:(__unused ZMGenericMessage *)message updateEvent:(__unused ZMUpdateEvent *)updateEvent initialUpdate:(__unused BOOL)initialUpdate
{
    NSAssert(FALSE, @"Subclasses should override this method: [%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
}
//- (void)updateEnableEditStatus:(BOOL)isEnableEdit  message:(ZMGenericMessage*)message{

//    self.isEnabledEditMsg = isEnableEdit;
//    if (message.hasTextJson){
//        NSString *jsonText = message.textJson.content;
//        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:[jsonText dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
//        if ([@"25" isEqualToString:dic[@"msgType"]]) {
//            NSDictionary *data = dic[@"msgData"];
//            int type = [[data optionalStringForKey:@"type"] intValue];

//            self.enabledEditMsgFunctionType = (ZMenabledEditMsgFunctionType)type;
//        }
//    }
//}

+ (ZMMessage *_Nullable)createOrUpdateMessageFromUpdateEvent:(ZMUpdateEvent *)updateEvent
                              inManagedObjectContext:(NSManagedObjectContext *)moc
                                      prefetchResult:(ZMFetchRequestBatchResult *)prefetchResult
{
    ZMGenericMessage *message;
    @try {
        message = [ZMGenericMessage genericMessageFromUpdateEvent:updateEvent];
    }
    @catch(NSException *e) {
        ZMLogError(@"Cannot create message from protobuffer: %@", e);
        message = nil;
    }

    ZMLogWithLevelAndTag(ZMLogLevelDebug, @"event-processing", @"processing:\n%@", [message debugDescription]);
    
    ZMConversation *conversation = [self.class conversationForUpdateEvent:updateEvent inContext:moc prefetchResult:prefetchResult];
    VerifyReturnNil(conversation != nil);
    ZMUser *selfUser = [ZMUser selfUserInContext:moc];

    if (conversation.conversationType == ZMConversationTypeSelf && ![updateEvent.senderUUID isEqual:selfUser.remoteIdentifier]) {
        return nil; // don't process messages in the self conversation not sent from the self user
    }

    // Update the legal hold state in the conversation
//    [conversation updateSecurityLevelIfNeededAfterReceiving:message timestamp:updateEvent.timeStamp ?: [NSDate date]];

//    if (!message.knownMessage) {
//        [UnknownMessageAnalyticsTracker tagUnknownMessageWithAnalytics:moc.analytics];
//    }

    // Check if the message is valid

    if (message == nil) {
        ZMUser *sender = [ZMUser userWithRemoteID:updateEvent.senderUUID createIfNeeded:NO inConversation:conversation inContext:moc];
        VerifyReturnNil(sender);
        [conversation appendInvalidSystemMessageAt:updateEvent.timeStamp sender:sender];
        return nil;
    }
    
    // Verify sender is part of conversation
    ZMUser * sender = [ZMUser userWithRemoteID:updateEvent.senderUUID createIfNeeded:YES inConversation:conversation inContext:moc];
    [conversation addParticipantIfMissing:sender date: [updateEvent.timeStamp dateByAddingTimeInterval:-0.01]];

    // Insert the message

    if (message.hasLastRead && conversation.conversationType == ZMConversationTypeSelf) {
        [ZMConversation updateConversationWithZMLastReadFromSelfConversation:message.lastRead inContext:moc];
    } else if (message.hasCleared && conversation.conversationType == ZMConversationTypeSelf) {
        [ZMConversation updateConversationWithZMClearedFromSelfConversation:message.cleared inContext:moc];
    } else if (message.hasHidden && conversation.conversationType == ZMConversationTypeSelf) {
        [ZMMessage removeMessageWithRemotelyHiddenMessage:message.hidden inManagedObjectContext:moc];
    } else if (message.hasDeleted) {
        [ZMMessage removeMessageWithRemotelyDeletedMessage:message.deleted inConversation:conversation senderID:updateEvent.senderUUID inManagedObjectContext:moc];
    } else if (message.hasReaction) {
        // if we don't understand the reaction received, discard it
        if (message.reaction.emoji.length > 0 && [Reaction transportReactionFrom:message.reaction.emoji] == TransportReactionNone) {
            return nil;
        }
        [ZMMessage addReaction:message.reaction sender:sender conversation:conversation inManagedObjectContext:moc];
    } else if (message.hasForbid) {
        [ZMMessage addOperation:message.forbid sender:sender conversation:conversation inManagedObjectContext:moc];
    } else if (message.hasConfirmation) {
        [ZMMessageConfirmation createMessageConfirmations:message.confirmation conversation:conversation updateEvent:updateEvent];
    } else if (message.hasEdited) {
        NSUUID *editedMessageId = [NSUUID uuidWithTransportString:message.edited.replacingMessageId];
        //
//        if ([EditMessageProcessRecorder.shared existWithMessageId:editedMessageId.transportString user: selfUser.remoteIdentifier.transportString]) {
//            return nil;
//        }
        ZMMessage *editedMessage = [ZMMessage fetchMessageWithNonce:editedMessageId forConversation:conversation inManagedObjectContext:moc prefetchResult:prefetchResult];
        if (editedMessage && [editedMessage processMessageEdit:message.edited from:updateEvent]) {
//            [EditMessageProcessRecorder.shared addMessageEditedWithMessageId:editedMessageId.transportString user:selfUser.remoteIdentifier.transportString];
            [editedMessage updateCategoryCache];
            conversation.lastVisibleMessage = editedMessage;
            return editedMessage;
        }
    } else if (message.textData.linkPreview.count > 0) {
        NSUUID *nonce = [NSUUID uuidWithTransportString:message.messageId];
        ZMOTRMessage *clientMessage = (ZMOTRMessage *)[ZMMessage fetchMessageWithNonce:nonce
               forConversation:conversation
        inManagedObjectContext:moc
                prefetchResult:prefetchResult];
        BOOL isNew = NO;
        if (!clientMessage) {
            clientMessage = [[ZMClientMessage alloc] initWithNonce:nonce managedObjectContext:moc];
            clientMessage.senderClientID = updateEvent.senderClientID;
            clientMessage.serverTimestamp = updateEvent.timeStamp;
            [clientMessage updateWithSender:sender forConversation:conversation];
            isNew = YES;
        }
        [clientMessage updateWithGenericMessage:message updateEvent:updateEvent initialUpdate: isNew];
        [clientMessage updateCategoryCache];
//        [clientMessage updateEnableEditStatus:conversation.isEnabledEditPersonalMsg message:message];
        return clientMessage;
    } else if ([conversation shouldAddEvent:updateEvent] && !(message.hasClientAction || message.hasCalling || message.hasAvailability)) {
        NSUUID *nonce = [NSUUID uuidWithTransportString:message.messageId];

//        if ([EditMessageProcessRecorder.shared existWithMessageId:nonce.transportString user: selfUser.remoteIdentifier.transportString]) {
//            return nil;
//        }
        Class messageClass = [ZMGenericMessage entityClassForGenericMessage:message];
        ZMOTRMessage *clientMessage;

        clientMessage = (ZMOTRMessage *)[ZMMessage fetchMessageWithNonce:nonce
                                                         forConversation:conversation
                                                  inManagedObjectContext:moc
                                                          prefetchResult:prefetchResult];
        
        
        if (clientMessage == nil) {
            clientMessage = [[messageClass alloc] initWithNonce:nonce managedObjectContext:moc];
            clientMessage.senderClientID = updateEvent.senderClientID;
            clientMessage.serverTimestamp = updateEvent.timeStamp;

            if (updateEvent.type == ZMUpdateEventTypeConversationServiceMessageAdd && [clientMessage isKindOfClass:ZMClientMessage.class]) {
                ((ZMClientMessage *)clientMessage).linkPreviewState = ZMLinkPreviewStateWaitingToBeProcessed;
            }
        } else if (updateEvent.type != ZMUpdateEventTypeConversationMemberJoinask) {
            return clientMessage;
        }
        
        // In case of AssetMessages: If the payload does not match the sha265 digest, calling `updateWithGenericMessage:updateEvent` will delete the object.
        [clientMessage updateWithGenericMessage:message updateEvent:updateEvent initialUpdate: YES];
        
        // It seems that if the object was inserted and immediately deleted, the isDeleted flag is not set to true.
        // In addition the object will still have a managedObjectContext until the context is finally saved. In this
        // case, we need to check the nonce (which would have previously been set) to avoid setting an invalid
        // relationship between the deleted object and the conversation and / or sender
        if (clientMessage.isZombieObject || clientMessage.nonce == nil) {
            return nil;
        }
        
        [clientMessage updateWithSender:sender forConversation:conversation];
//        [clientMessage updateWithUpdateEvent:updateEvent forConversation:conversation];

        if (message.hasTextJson) {
           [clientMessage updateAssistantbotWithUpdateEvent:updateEvent forConversation:conversation jsonText:message.textJson.content];
        }
        [clientMessage unarchiveIfNeeded:conversation];
        [clientMessage updateCategoryCache];
//        [clientMessage updateEnableEditStatus:conversation.isEnabledEditPersonalMsg message:message];
        return clientMessage;
    }

    return nil;
}

+ (NSMutableArray *)createNotificationMessageFromUpdateEvent:(ZMUpdateEvent *)updateEvent
                                           inManagedObjectContext:(NSManagedObjectContext *)moc {
    NSMutableArray * array = [NSMutableArray array];
    ZMGenericMessage *message;
    ZMOTRMessage *clientMessage;
    @try {
        message = [ZMGenericMessage genericMessageFromUpdateEvent:updateEvent];
    } @catch(NSException *e) {
        ZMLogError(@"Cannot create message from protobuffer: %@", e);
        message = nil;
    }
    if (message == nil) {
        return nil;
    }
    if (message.textData.linkPreview.count > 0) {
        return nil;
    }
    NSUUID *nonce = [NSUUID uuidWithTransportString:message.messageId];
    Class messageClass = [ZMGenericMessage entityClassForGenericMessage:message];
    ZMConversation *conversation = [ZMConversation conversationNoRowCacheWithRemoteID: updateEvent.conversationUUID createIfNeeded:NO inContext: moc];
    VerifyReturnNil(conversation != nil);
    ZMUser * sender = [ZMUser userNoRowCacheWithRemoteID:updateEvent.senderUUID createIfNeeded:NO inContext:moc];
    clientMessage = [[messageClass alloc] initWithNonce:nonce managedObjectContext:moc];
    //TODO
    [clientMessage updateWithGenericMessage:message updateEvent:updateEvent initialUpdate: YES];
    clientMessage.sender = sender;
    if (message.hasTextJson) {
       [clientMessage updateAssistantbotWithUpdateEvent:updateEvent forConversation:conversation jsonText:message.textJson.content];
    }

    if (message.hasDeleted) {
        return array;
    }
//    deletionTimeout
    [array addObject:clientMessage];
    [array addObject:conversation];
    return array;
}

-(void)updateWithPostPayload:(NSDictionary *)payload updatedKeys:(NSSet *)updatedKeys {

    NSDate *timestamp = [payload dateFor:@"time"];
    if (timestamp == nil) {
        ZMLogWarn(@"No time in message post response from backend.");
    } else if( ! [timestamp isEqualToDate:self.serverTimestamp]) {
        self.expectsReadConfirmation = self.conversation.hasReadReceiptsEnabled;
    }
    
    [super updateWithPostPayload:payload updatedKeys:updatedKeys];
}

@end
