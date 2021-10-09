// 
// 


#import "ZMBaseManagedObjectTest.h"

extern NSString * const EventConversationAdd;
extern NSString * const EventConversationAddClientMessage;
extern NSString * const EventConversationAddOTRMessage;
extern NSString * const EventConversationAddAsset;
extern NSString * const EventConversationAddOTRAsset;
extern NSString * const EventConversationKnock;
extern NSString * const EventConversationHotKnock;
extern NSString * const IsExpiredKey;
extern NSString * const EventCallState;
extern NSString * const EventConversationTyping;
extern NSString * const EventConversationMemberJoin;
extern NSString * const EventConversationMemberLeave;
extern NSString * const EventConversationRename;
extern NSString * const EventConversationCreate;
extern NSString * const EventUserConnection;
extern NSString * const EventConversationConnectionRequest;
extern NSString * const EventConversationEncryptedMessage;
extern NSString * const EventNewConnection;

@interface ZMBaseManagedObjectTest (EventFactory)

/// Creates a call.state event payload for conversation with callParticipants and selfUser as active member
/// To use this method, set remoteIdentifiers on all managedObjects
- (NSDictionary *)payloadForCallStateEventInConversation:(ZMConversation *)conversation
                                         othersAreJoined:(BOOL)othersAreJoined
                                            selfIsJoined:(BOOL)selfIsJoined
                                                sequence:(NSNumber *)sequence;

- (NSDictionary *)payloadForCallStateEventInConversation:(ZMConversation *)conversation
                                         othersAreJoined:(BOOL)othersAreJoined
                                            selfIsJoined:(BOOL)selfIsJoined
                                     otherIsSendingVideo:(BOOL)otherIsSendingVideo
                                      selfIsSendingVideo:(BOOL)selfIsSendingVideo
                                                sequence:(NSNumber *)sequence;

- (NSDictionary *)payloadForCallStateEventInConversation:(ZMConversation *)conversation
                                             joinedUsers:(NSArray *)joinedUsers
                                       videoSendingUsers:(NSArray *)videoSendingUsers
                                                sequence:(NSNumber *)sequence;

- (ZMUpdateEvent *)callStateEventInConversation:(ZMConversation *)conversation
                                othersAreJoined:(BOOL)othersAreJoined
                                   selfIsJoined:(BOOL)selfIsJoined
                            otherIsSendingVideo:(BOOL)otherIsSendingVideo
                             selfIsSendingVideo:(BOOL)selfIsSendingVideo
                                       sequence:(NSNumber *)sequence;

- (ZMUpdateEvent *)callStateEventInConversation:(ZMConversation *)conversation
                                    joinedUsers:(NSArray *)joinedUsers
                              videoSendingUsers:(NSArray *)videoSendingUsers
                                       sequence:(NSNumber *)sequence;

- (ZMUpdateEvent *)callStateEventInConversation:(ZMConversation *)conversation
                                    joinedUsers:(NSArray *)joinedUsers
                              videoSendingUsers:(NSArray *)videoSendingUsers
                                       sequence:(NSNumber *)sequence
                                        session:(NSString *)session;

- (ZMUpdateEvent *)eventWithPayload:(NSDictionary *)data inConversation:(ZMConversation *)conversation type:(NSString *)type;

- (NSMutableDictionary *)payloadForMessageInConversation:(ZMConversation *)conversation
                                                  sender:(ZMUser *)sender
                                                    type:(NSString *)type
                                                    data:(NSDictionary *)data;

- (NSMutableDictionary *)payloadForMessageInConversation:(ZMConversation *)conversation type:(NSString *)type data:(id)data;
- (NSMutableDictionary *)payloadForMessageInConversation:(ZMConversation *)conversation type:(NSString *)type data:(id)data time:(NSDate *)date;
- (NSMutableDictionary *)payloadForMessageInConversation:(ZMConversation *)conversation type:(NSString *)type data:(id)data time:(NSDate *)date fromUser:(ZMUser *)fromUser;

@end
