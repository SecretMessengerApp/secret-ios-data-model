// 
// 


#import "ZMManagedObject.h"

@class ZMUser;
@class ZMConversation;

typedef NS_ENUM(int16_t, ZMConnectionStatus) {
    ZMConnectionStatusInvalid = 0,
    ZMConnectionStatusAccepted, ///< Both users have accepted
    ZMConnectionStatusPending, ///< The other user has sent us a request
    ZMConnectionStatusIgnored, ///< We have ignored this user
    ZMConnectionStatusBlocked, ///< We have blocked this user
    ZMConnectionStatusSent, ///< We have sent a request to connect
    ZMConnectionStatusCancelled, ///< We cancel sent reqeust to connect
};



@interface ZMConnection : ZMManagedObject

+ (instancetype)insertNewSentConnectionToUser:(ZMUser *)user;
+ (instancetype)insertNewSentConnectionToUser:(ZMUser *)user existingConversation:(ZMConversation *)conversation;

@property (nonatomic) NSDate *lastUpdateDate;
@property (nonatomic, copy) NSString *message;
@property (nonatomic) ZMConnectionStatus status;
@property (readonly, nonatomic) ZMUser *to;
@property (nonatomic,readonly) BOOL hasValidConversation;
@property (nonatomic) int16_t triggerCode;

+ (NSArray *)connectionsInMangedObjectContext:(NSManagedObjectContext *)moc;

@end



