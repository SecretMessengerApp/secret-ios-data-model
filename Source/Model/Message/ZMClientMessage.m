// 
// 


@import WireSystem;
@import WireUtilities;
@import WireTransport;
@import WireProtos;
@import CoreGraphics;
@import ImageIO;
@import MobileCoreServices;
@import WireCryptobox;

#import "ZMClientMessage.h"
#import "ZMConversation+Internal.h"
#import "ZMConversation+Transport.h"
#import "ZMUpdateEvent+WireDataModel.h"
#import "ZMGenericMessage+UpdateEvent.h"

#import "ZMGenericMessageData.h"
#import "ZMUser+Internal.h"
#import "ZMOTRMessage.h"
#import "ZMGenericMessage+External.h"
#import <WireDataModel/WireDataModel-Swift.h>

static NSString * const ClientMessageGenericMessageKey = @"genericMessage";
static NSString * const ClientMessageUpdateTimestamp = @"updatedTimestamp";

NSString * const ZMClientMessageLinkPreviewStateKey = @"linkPreviewState";
NSString * const ZMClientMessageLinkPreviewKey = @"linkPreview";
NSString * const ZMFailedToCreateEncryptedMessagePayloadString = @"💣";
// From https://github.com/wearezeta/generic-message-proto:
// "If payload is smaller then 256KB then OM can be sent directly"
// Just to be sure we set the limit lower, to 128KB (base 10)
NSUInteger const ZMClientMessageByteSizeExternalThreshold = 128000;

static NSString *ZMLogTag ZM_UNUSED = @"ephemeral";

@interface ZMClientMessage()

@property (nonatomic) ZMGenericMessage *genericMessage;

@end

@interface ZMClientMessage (ZMKnockMessageData) <ZMKnockMessageData>

@end

@implementation ZMClientMessage

+ (NSString *)entityName;
{
    return @"ClientMessage";
}

- (NSSet *)ignoredKeys
{
    return [[super ignoredKeys] setByAddingObject:ClientMessageUpdateTimestamp];
}

- (NSDate *)updatedAt
{
    return self.updatedTimestamp;
}

- (void)updateWithGenericMessage:(ZMGenericMessage *)message updateEvent:(ZMUpdateEvent *)updateEvent initialUpdate:(BOOL)initialUpdate
{ 
    if (initialUpdate) {
        [self addData:message.data];
        [self updateNormalizedText];
    } else {
        [self applyLinkPreviewUpdate:message from:updateEvent];
    }
}

- (void)expire
{
    if (self.genericMessage.hasEdited) {
        // Replace the nonce with the original
        // This way if we get a delete from a different device while we are waiting for the response it will delete this message
        NSUUID *originalID = [NSUUID uuidWithTransportString:self.genericMessage.edited.replacingMessageId];
        self.nonce = originalID;
    }
    [super expire];
}

- (void)resend
{
    if (self.genericMessage.hasEdited) {
        // Re-apply the edit since we've restored the orignal nonce when the message expired
        [self editText:self.textMessageData.messageText mentions:self.textMessageData.mentions fetchLinkPreview:YES];
        [super resend];
    } else {
        [super resend];
    }
}

- (id<ZMJsonTextMessageData>)jsonTextMessageData{
    if (self.genericMessage.jsonTextData != nil) {
        return self;
    }
    return nil;
}

- (id<ZMTextMessageData>)textMessageData
{
    if (self.genericMessage.textData != nil) {
        return self;
    }
    return nil;
}

- (id<ZMImageMessageData>)imageMessageData
{
    return nil;
}

- (id<ZMKnockMessageData>)knockMessageData
{
    if (self.genericMessage.knockData != nil) {
        return self;
    }
    return nil;
}

- (id<ZMFileMessageData>)fileMessageData
{
    return nil;
}

- (void)updateWithPostPayload:(NSDictionary *)payload updatedKeys:(__unused NSSet *)updatedKeys
{
    // we don't want to update the conversation if the message is a confirmation message
    if (self.genericMessage.hasConfirmation || self.genericMessage.hasReaction)
    {
        return;
    }
    if (self.genericMessage.hasDeleted) {
        NSUUID *originalID = [NSUUID uuidWithTransportString:self.genericMessage.deleted.messageId];
        ZMMessage *original = [ZMMessage fetchMessageWithNonce:originalID forConversation:self.conversation inManagedObjectContext:self.managedObjectContext];
        original.sender = nil;
        original.senderClientID = nil;
    } else if (self.genericMessage.hasEdited) {
        NSUUID *nonce = [self nonceFromPostPayload:payload];
        if (nonce != nil && ![self.nonce isEqual:nonce]) {
            ZMLogWarn(@"send message response nonce does not match");
            return;
        }
        NSDate *serverTimestamp = [payload dateFor:@"time"];
        if (serverTimestamp != nil) {
            self.updatedTimestamp = serverTimestamp;
        }
    } else {
        [super updateWithPostPayload:payload updatedKeys:nil];
    }
}

+ (NSPredicate *)predicateForObjectsThatNeedToBeInsertedUpstream
{
    NSPredicate *encryptedNotSynced = [NSPredicate predicateWithFormat:@"%K == FALSE", DeliveredKey];
    NSPredicate *notExpired = [NSPredicate predicateWithFormat:@"%K == 0", ZMMessageIsExpiredKey];
    return [NSCompoundPredicate andPredicateWithSubpredicates:@[encryptedNotSynced, notExpired]];
}

- (void)markAsSent
{
    [super markAsSent];
    if (self.linkPreviewState == ZMLinkPreviewStateUploaded) {
        self.linkPreviewState = ZMLinkPreviewStateDone;
    }
    [self setObfuscationTimerIfNeeded];
}

- (void)setObfuscationTimerIfNeeded
{
    if (!self.isEphemeral) {
        return;
    }
    if (self.genericMessage.textData != nil && self.genericMessage.linkPreviews.count > 0 &&
        self.linkPreviewState != ZMLinkPreviewStateDone)
    {
        // If we have link previews and they are not sent yet, we wait until they are sent
        return;
    }
    [self startDestructionIfNeeded];
}

- (BOOL)hasDownloadedImage
{
    if (nil != self.textMessageData && nil != self.textMessageData.linkPreview) {
        return [self.managedObjectContext.zm_fileAssetCache hasDataOnDisk:self format:ZMImageFormatMedium encrypted:NO] || // processed or downloaded
               [self.managedObjectContext.zm_fileAssetCache hasDataOnDisk:self format:ZMImageFormatOriginal encrypted:NO]; // original
    }
    return false;
}

@end


@implementation ZMClientMessage (ZMKnockMessage)

@end

@implementation ZMClientMessage (Ephemeral)

- (BOOL)isEphemeral
{
    return self.destructionDate != nil || self.genericMessage.hasEphemeral || self.isObfuscated;
}

- (NSTimeInterval)deletionTimeout
{
    if (self.isEphemeral) {
        return self.genericMessage.ephemeral.expireAfterMillis/1000;
    }
    return -1;
}

- (void)obfuscate
{
    [super obfuscate];
    if (self.genericMessage.knockData == nil) {
        ZMGenericMessage *obfuscatedMessage = [self.genericMessage obfuscatedMessage];
        [self deleteContent];
        if (obfuscatedMessage != nil) {
            [self mergeWithExistingData:obfuscatedMessage.data];
            [self setGenericMessage:self.genericMessageFromDataSet];
        }
    }
}

@end


