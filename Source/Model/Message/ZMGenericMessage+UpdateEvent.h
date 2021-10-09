// 
// 


@import WireProtos;
@import WireTransport;

@interface ZMGenericMessage (UpdateEvent)

+ (ZMGenericMessage *)genericMessageFromUpdateEvent:(ZMUpdateEvent *)updateEvent;

+ (ZMGenericMessage *)genericMessageWithBase64String:(NSString *)string updateEvent:(ZMUpdateEvent *)event;

+ (Class)entityClassForGenericMessage:(ZMGenericMessage *)genericMessage;

+ (Class)entityClassForPlainMessageForGenericMessage:(ZMGenericMessage *)genericMessage;

@end
