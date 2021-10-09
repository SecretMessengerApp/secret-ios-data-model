// 
// 

@import WireProtos;

#import "ZMUpdateEvent+WireDataModel.h"
#import "ZMConversation+Internal.h"
#import "ZMMessage+Internal.h"
#import "ZMUser+Internal.h"
#import "ZMGenericMessage+UpdateEvent.h"

@implementation ZMUpdateEvent (WireDataModel)

- (NSDate *)timeStamp
{
    if (self.isTransient || self.type == ZMUpdateEventTypeUserConnection) {
        return nil;
    }
    return [self.payload dateFor:@"time"];
}

- (NSUUID *)senderUUID
{
    if (self.type == ZMUpdateEventTypeUserConnection) {
        return [[self.payload optionalDictionaryForKey:@"connection"] optionalUuidForKey:@"to"];
    }
    
    if (self.type == ZMUpdateEventTypeUserContactJoin) {
        return [[self.payload optionalDictionaryForKey:@"user"] optionalUuidForKey:@"id"];
    }

    if (self.type == ZMUpdateEventTypeConversationAppMessageAdd) {
        return nil;
    }

    return [self.payload optionalUuidForKey:@"from"];
}

- (NSUUID *)conversationUUID;
{
    if (self.type == ZMUpdateEventTypeUserConnection) {
        return  [[self.payload optionalDictionaryForKey:@"connection"] optionalUuidForKey:@"conversation"];
    }
    if (self.type == ZMUpdateEventTypeTeamConversationDelete) {
        return [[self.payload optionalDictionaryForKey:@"data"] optionalUuidForKey:@"conv"];
    }
    
    return [self.payload optionalUuidForKey:@"conversation"];
}

- (NSString *)senderClientID
{
    if (self.type == ZMUpdateEventTypeConversationOtrMessageAdd ||
        self.type == ZMUpdateEventTypeConversationOtrAssetAdd ||
        self.type == ZMUpdateEventTypeConversationBgpMessageAdd) {
        return [[self.payload optionalDictionaryForKey:@"data"] optionalStringForKey:@"sender"];
    }
    return nil;
}

- (NSString *)recipientClientID
{
    if (self.type == ZMUpdateEventTypeConversationOtrMessageAdd ||
        self.type == ZMUpdateEventTypeConversationOtrAssetAdd ||
        self.type == ZMUpdateEventTypeConversationBgpMessageAdd) {
        return [[self.payload optionalDictionaryForKey:@"data"] optionalStringForKey:@"recipient"];
    }
    return nil;
}

- (NSUUID *)messageNonce;
{
    switch (self.type) {
        case ZMUpdateEventTypeConversationMessageAdd:
        case ZMUpdateEventTypeConversationAssetAdd:
        case ZMUpdateEventTypeConversationKnock:
            return [[self.payload optionalDictionaryForKey:@"data"] optionalUuidForKey:@"nonce"];

        case ZMUpdateEventTypeConversationServiceMessageAdd:
        case ZMUpdateEventTypeConversationBgpMessageAdd:
        case ZMUpdateEventTypeConversationClientMessageAdd:
        case ZMUpdateEventTypeConversationOtrMessageAdd:
        case ZMUpdateEventTypeConversationOtrAssetAdd:
        case ZMUpdateEventTypeConversationMemberJoinask:
        case ZMUpdateEventTypeConversationJsonMessageAdd:
        {
            ZMGenericMessage *message = [ZMGenericMessage genericMessageFromUpdateEvent:self];
            return [NSUUID uuidWithTransportString:message.messageId];
        }
        default:
            return nil;
            break;
    }
}

- (NSMutableSet *)usersFromUserIDsInManagedObjectContext:(NSManagedObjectContext *)context createIfNeeded:(BOOL)createIfNeeded;
{
    NSMutableSet *users = [NSMutableSet set];
    for (NSString *uuidString in [[self.payload optionalDictionaryForKey:@"data"] optionalArrayForKey:@"user_ids"] ) {
        VerifyAction([uuidString isKindOfClass:[NSString class]], return [NSMutableSet set]);
        NSUUID *uuid = uuidString.UUID;
        VerifyAction(uuid != nil, return [NSMutableSet set]);
        ZMUser *user = [ZMUser userWithRemoteID:uuid createIfNeeded:createIfNeeded inContext:context];
        if (user != nil) {
            [users addObject:user];
        }
    }
    return users;
}

@end


