// 
// 


#import "ZMMessage+Internal.h"

@class UserClient;
@class MessageUpdateResult;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const DeliveredKey;

@interface ZMOTRMessage : ZMMessage


@property (nonatomic, readonly, nullable) NSString *dataSetDebugInformation;


- (void)missesRecipient:(UserClient *)recipient;
- (void)missesRecipients:(NSSet<UserClient *> *)recipients;
- (void)doesNotMissRecipient:(UserClient *)recipient;
- (void)doesNotMissRecipients:(NSSet<UserClient *> *)recipients;

- (void)updateWithGenericMessage:(ZMGenericMessage * )message updateEvent:(ZMUpdateEvent *)updateEvent initialUpdate:(BOOL)initialUpdate;

+ (ZMMessage * _Nullable)createOrUpdateMessageFromUpdateEvent:(ZMUpdateEvent *)updateEvent
                                        inManagedObjectContext:(NSManagedObjectContext *)moc
                                                prefetchResult:(ZMFetchRequestBatchResult * _Nullable)prefetchResult;

+ (NSMutableArray *)createNotificationMessageFromUpdateEvent:(ZMUpdateEvent *)updateEvent
                                           inManagedObjectContext:(NSManagedObjectContext *)moc;
@end

NS_ASSUME_NONNULL_END
