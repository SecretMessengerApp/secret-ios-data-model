// 
// 


@import WireTransport;

@class ZMConversation;
@class NSManagedObjectContext;

@interface ZMUpdateEvent (WireDataModel)

/// May be nil (e.g. transient events)
- (nullable NSDate *)timeStamp;
- (nullable NSUUID *)senderUUID;
- (nullable NSUUID *)conversationUUID;
- (nullable NSUUID *)messageNonce;
- (nullable NSString *)senderClientID;
- (nullable NSString *)recipientClientID;

- (nonnull NSMutableSet *)usersFromUserIDsInManagedObjectContext:(nonnull NSManagedObjectContext *)context createIfNeeded:(BOOL)createIfNeeded;

@end
