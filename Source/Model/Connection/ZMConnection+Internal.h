// 
// 


#import "ZMConnection.h"
#import "ZMManagedObject+Internal.h"

@class ZMConversation;
@class ZMUser;

extern NSString * const ZMConnectionStatusKey;

@interface ZMConnection (Internal)

@property (nonatomic) ZMConversation *conversation;
@property (nonatomic) ZMUser *to;
@property (nonatomic) BOOL existsOnBackend;
@property (nonatomic) NSDate *lastUpdateDateInGMT;

@property (nonatomic, readonly) NSString *statusAsString;

+ (ZMConnectionStatus)statusFromString:(NSString *)string;
+ (NSString *)stringForStatus:(ZMConnectionStatus)status;
/// Creates a connection for an already existing remote connection to the user with the given UUID. It also creates the user if it doesn't already exist and marks it for download.
+ (instancetype)connectionWithUserUUID:(NSUUID *)UUID inContext:(NSManagedObjectContext *)moc;
+ (ZMConnection *)connectionFromTransportData:(NSDictionary *)transportData managedObjectContext:(NSManagedObjectContext *)moc;

- (void)updateFromTransportData:(NSDictionary *)transportData;
- (void)updateConversationType;

@end
