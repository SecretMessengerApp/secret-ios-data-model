// 
// 

@import WireTesting;
@import WireDataModel;

@implementation ZMConversation (Testing)

- (void)setUnreadCount:(NSUInteger)count;
{
    self.lastServerTimeStamp = [NSDate date];
    self.lastReadServerTimeStamp = self.lastServerTimeStamp;
    
    for (NSUInteger idx = 0; idx < count; idx++) {
        ZMMessage *message = [[ZMMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.managedObjectContext];
        message.serverTimestamp = [self.lastServerTimeStamp dateByAddingTimeInterval:5];
        self.lastServerTimeStamp = message.serverTimestamp;
    }
}

- (void)addUnreadMissedCall
{
    ZMSystemMessage *systemMessage = [[ZMSystemMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.managedObjectContext];
    systemMessage.systemMessageType = ZMSystemMessageTypeMissedCall;
    systemMessage.serverTimestamp = self.lastReadServerTimeStamp ?
    [self.lastReadServerTimeStamp dateByAddingTimeInterval:1000] :
    [NSDate dateWithTimeIntervalSince1970:1231234];
    [self calculateLastUnreadMessages];
}

- (void)setHasExpiredMessage:(BOOL)hasUnreadUnsentMessage
{
    self.hasUnreadUnsentMessage = hasUnreadUnsentMessage;
}

@end

