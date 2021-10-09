// 
// 


#import "ZMGenericMessage+UpdateEvent.h"
#import "ZMClientMessage.h"
#import "ZMGenericMessage+External.h"
#import "ZMGenericMessage+Utils.h"
#import "WireDataModel/WireDataModel-Swift.h"

@implementation ZMGenericMessage (UpdateEvent)

+ (ZMGenericMessage *)genericMessageFromUpdateEvent:(ZMUpdateEvent *)updateEvent
{
    ZMGenericMessage *message;
    
    switch (updateEvent.type) {
        case ZMUpdateEventTypeConversationClientMessageAdd: {
            NSString *base64Content = [updateEvent.payload stringForKey:@"data"];
            message = [self genericMessageWithBase64String:base64Content updateEvent:updateEvent];
        }
            break;
            
        case ZMUpdateEventTypeConversationBgpMessageAdd:
        case ZMUpdateEventTypeConversationOtrMessageAdd: {
            NSString *base64Content = [[updateEvent.payload dictionaryForKey:@"data"] stringForKey:@"text"];
            message = [self genericMessageWithBase64String:base64Content updateEvent:updateEvent];
        }
            break;
            
        case ZMUpdateEventTypeConversationOtrAssetAdd: {
            NSString *base64Content = [[updateEvent.payload dictionaryForKey:@"data"] stringForKey:@"info"];
            VerifyReturnNil(base64Content != nil);
            @try {
                message = [ZMGenericMessage messageWithBase64String:base64Content];
            }
            @catch(NSException *e) {
                message = nil;
            }
        }
            break;
            
        case ZMUpdateEventTypeConversationServiceMessageAdd: {
            message = [self serviceGenericMessageWithUpdateEvent:updateEvent];
            VerifyReturnNil(message != nil);
        }
            break;
            
        case ZMUpdateEventTypeConversationMemberJoinask: {
            message = [self memberJoinAskGenericMessageWithUpdateEvent:updateEvent];
            VerifyReturnNil(message != nil);
        }
            break;
        case ZMUpdateEventTypeConversationJsonMessageAdd: {
            message = [self jsonGenericMessageWithUpdateEvent:updateEvent];
            VerifyReturnNil(message != nil);
        }
            break;
        default:
            break;
    }

    if (message.hasExternal) {
        return [self genericMessageFromUpdateEventWithExternal:updateEvent external:message.external];
    }
    
    return message;
}

+ (ZMGenericMessage *)genericMessageWithBase64String:(NSString *)string updateEvent:(ZMUpdateEvent *)event
{
    VerifyReturnNil(nil != string);
    ZMGenericMessage *message;
    @try {
        message = [ZMGenericMessage messageWithBase64String:string];
    } @catch (NSException *exception) {
        ZMLogError(@"Cannot create message from protobuffer: %@ event: %@", exception, event);
        return nil;
    }
    return message;
}

+ (Class)entityClassForGenericMessage:(ZMGenericMessage *)genericMessage
{
    if (genericMessage.imageAssetData != nil || genericMessage.assetData != nil) {
        return [ZMAssetClientMessage class];
    }
    
    return ZMClientMessage.class;
}

+ (Class)entityClassForPlainMessageForGenericMessage:(ZMGenericMessage *)genericMessage
{
    if (genericMessage.hasText) {
        return ZMTextMessage.class;
    }
    
    if (genericMessage.hasImage) {
        return ZMImageMessage.class;
    }
    
    if (genericMessage.hasKnock) {
        return ZMKnockMessage.class;
    }
    
    return nil;
}


@end
