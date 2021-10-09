// 
// 


@import WireImages;
#import "ZMMessage+Internal.h"
#import "ZMOTRMessage.h"

@class UserClient;
@class EncryptionSessionsDirectory;
@protocol ZMConversationMessage;

extern NSString * _Nonnull const ZMFailedToCreateEncryptedMessagePayloadString;
extern NSUInteger const ZMClientMessageByteSizeExternalThreshold;
extern NSString * _Nonnull const ZMClientMessageLinkPreviewStateKey;
extern NSString * _Nonnull const ZMClientMessageLinkPreviewKey;


@interface ZMClientMessage : ZMOTRMessage

- (BOOL)hasDownloadedImage;

@end



@interface ZMClientMessage (Testing)

+ (ZMNewOtrMessage * _Nullable)otrMessageForGenericMessage:(ZMGenericMessage * _Nonnull)genericMessage
                                                selfClient:(UserClient * _Nonnull)selfClient
                                              conversation:(ZMConversation * _Nonnull)conversation
                                              externalData:(NSData * _Nullable)externalData
                                         sessionsDirectory:(EncryptionSessionsDirectory * _Nonnull)sessionsDirectory;

@end
