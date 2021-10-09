// 
// 


@import WireProtos;



@interface ZMLastRead (Utils)

+ (ZMLastRead *)lastReadWithTimestamp:(NSDate *)timeStamp
                  conversationRemoteID:(NSUUID *)conversationID;

@end



@interface ZMCleared (Utils)

+ (instancetype)clearedWithTimestamp:(NSDate *)timeStamp
          conversationRemoteID:(NSUUID *)conversationID;

@end


@interface ZMMessageDelete (Utils)

+ (instancetype)messageDeleteWithMessageID:(NSUUID *)messageID;

@end



@interface ZMReaction (Utils)

+ (instancetype)reactionWithEmoji:(NSString *)emoji messageID:(NSUUID *)messageID;

@end


@interface ZMForbid (Utils)

+ (instancetype)forbidWithType:(NSString *)type messageID:(NSUUID *)messageID operatorName:(NSString *)name;

@end



@interface ZMConfirmation (Utils)

+ (instancetype)messageWithMessageID:(NSUUID *)messageID confirmationType:(ZMConfirmationType)confirmationType;

@end

