// 
// 


#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ZMMessage;
@class ZMConversation;


typedef NSDictionary <NSUUID *, NSSet <ZMMessage *> *> ZMMessageMapping;
typedef NSDictionary <NSUUID *, ZMConversation *> ZMConversationMapping;


@interface ZMFetchRequestBatchResult : NSObject

@property (nonatomic, readonly) ZMMessageMapping *messagesByNonce;
@property (nonatomic, readonly) ZMConversationMapping *conversationsByRemoteIdentifier;

@end



/// A batch used to fetch as many messages and conversations
/// as possible using the least number of fetch requests
@interface ZMFetchRequestBatch : NSObject

/// Sets containing the current NSUUIDs for messages and conversations to fetch
@property (nonatomic, readonly) NSMutableSet *noncesToFetch;
@property (nonatomic, readonly) NSMutableSet *remoteIdentifiersToFetch;

/// Adds a the given set of message nonces to the batch fetch request
- (void)addNoncesToPrefetchMessages:(NSSet <NSUUID *>*)nonces;

/// Adds a the given set of conversation remote identifiers to the batch fetch request
- (void)addConversationRemoteIdentifiersToPrefetchConversations:(NSSet <NSUUID *>*)identifiers;

- (ZMFetchRequestBatchResult *)executeInManagedObjectContext:(NSManagedObjectContext *)moc;

@end



@interface NSManagedObjectContext (ZMFetchRequestBatch)

- (ZMFetchRequestBatchResult *)executeFetchRequestBatchOrAssert:(ZMFetchRequestBatch *)fetchRequestbatch;

@end
