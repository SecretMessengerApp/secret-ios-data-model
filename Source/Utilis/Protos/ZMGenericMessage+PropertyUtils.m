// 
// 

@import WireTransport;

#import "ZMGenericMessage+PropertyUtils.h"


@implementation ZMLastRead (Utils)

+ (instancetype)lastReadWithTimestamp:(NSDate *)timeStamp conversationRemoteID:(NSUUID *)conversationID;
{
    ZMLastReadBuilder *builder = [ZMLastRead builder];
    builder.conversationId = conversationID.transportString;
    builder.lastReadTimestamp = (long long) ([timeStamp timeIntervalSince1970] * 1000); // timestamps are stored in milliseconds
    return [builder build];
}

@end




@implementation ZMCleared (Utils)

+ (instancetype)clearedWithTimestamp:(NSDate *)timeStamp conversationRemoteID:(NSUUID *)conversationID;
{
    ZMClearedBuilder *builder = [ZMCleared builder];
    builder.conversationId = conversationID.transportString;
    builder.clearedTimestamp = (long long) ([timeStamp timeIntervalSince1970] * 1000); // timestamps are stored in milliseconds
    return [builder build];
}

@end

@implementation ZMMessageDelete (Utils)

+ (instancetype)messageDeleteWithMessageID:(NSUUID *)messageID;
{
    ZMMessageDeleteBuilder *builder = [ZMMessageDelete builder];
    builder.messageId = messageID.transportString;
    return [builder build];
}

@end


@implementation ZMReaction (Utils)

+ (instancetype)reactionWithEmoji:(NSString *)emoji messageID:(NSUUID *)messageID;
{
    ZMReactionBuilder *builder = [ZMReaction builder];
    builder.emoji = emoji;
    builder.messageId = messageID.transportString;
    return [builder build];
}

@end


@implementation ZMForbid (Utils)

+ (instancetype)forbidWithType:(NSString *)type messageID:(NSUUID *)messageID operatorName:(NSString *)name
{
    ZMForbidBuilder *builder = [ZMForbid builder];
    [builder setEmoji:type];
    [builder setMessageId:messageID.transportString];
    [builder setOptName:name];
    return [builder build];
}

@end


@implementation ZMConfirmation (Utils)

+ (instancetype)messageWithMessageID:(NSUUID *)messageID confirmationType:(ZMConfirmationType)confirmationType;
{
    ZMConfirmationBuilder *builder = [ZMConfirmation builder];
    builder.firstMessageId = messageID.transportString;
    builder.type = confirmationType;
    return [builder build];
}

@end
