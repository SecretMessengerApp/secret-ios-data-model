// 
// 


@import CoreData;

#import "ZMFetchRequestBatch.h"
#import "ZMMessage+Internal.h"
#import "ZMConversation+Internal.h"

#import "NSManagedObjectContext+zmessaging.h"


@interface ZMFetchRequestBatchResult ()

@property (nonatomic, readwrite) ZMMessageMapping *messagesByNonce;
@property (nonatomic, readwrite) ZMConversationMapping *conversationsByRemoteIdentifier;

@end



@implementation ZMFetchRequestBatchResult

- (instancetype)init
{
    if (self = [super init]) {
        self.messagesByNonce = [[ZMMessageMapping alloc] init];
        self.conversationsByRemoteIdentifier = [[ZMConversationMapping alloc] init];
    }

    return self;
}

- (void)addMessages:(NSArray <ZMMessage *>*)messages
{
    NSMutableDictionary *mutableMessagesByNonce = self.messagesByNonce.mutableCopy;
    
    for (ZMMessage *message in messages) {
        if (nil != self.messagesByNonce[message.nonce]) {
            [mutableMessagesByNonce[message.nonce] addObject:message];
        } else {
            mutableMessagesByNonce[message.nonce] = [NSMutableSet setWithObject:message];
        }
    }
    
    self.messagesByNonce = mutableMessagesByNonce.copy;
}

- (void)addConversations:(NSArray <ZMConversation *>*)conversations
{
    NSMutableDictionary *mutableConversationsByRemoteIdentifier = self.conversationsByRemoteIdentifier.mutableCopy;
    for (ZMConversation *conversation in conversations) {
        mutableConversationsByRemoteIdentifier[conversation.remoteIdentifier] = conversation;
    }
    
    self.conversationsByRemoteIdentifier = mutableConversationsByRemoteIdentifier.copy;
}

@end




@interface ZMFetchRequestBatch ()

@property (nonatomic, readwrite) NSMutableSet *noncesToFetch;
@property (nonatomic, readwrite) NSMutableSet *remoteIdentifiersToFetch;

@end



@implementation ZMFetchRequestBatch

- (instancetype)init {
    self = [super init];
    if(self) {
        self.noncesToFetch = [NSMutableSet set];
        self.remoteIdentifiersToFetch = [NSMutableSet set];
    }
    return self;
}

- (void)addNoncesToPrefetchMessages:(NSSet<NSUUID *> *)nonces
{
    [self.noncesToFetch unionSet:nonces];
}

- (void)addConversationRemoteIdentifiersToPrefetchConversations:(NSSet <NSUUID *>*)identifiers
{
    [self.remoteIdentifiersToFetch unionSet:identifiers];
}

- (ZMFetchRequestBatchResult *)executeInManagedObjectContext:(NSManagedObjectContext *)moc;
{
    ZMFetchRequestBatchResult *batchResult = [[ZMFetchRequestBatchResult alloc] init];
    NSArray <ZMMessage *>*fetchedMessages = [self fetchMessagesInManagedObjectContext:moc];
    [batchResult addMessages:fetchedMessages];

    NSArray <ZMConversation *> *fetchedConversations = [self fetchConversationsInManagedObjectContext:moc];
    [batchResult addConversations:fetchedConversations];
    
    return batchResult;
}

- (NSArray <ZMMessage *>*)fetchMessagesInManagedObjectContext:(NSManagedObjectContext *)moc
{
    NSSet *noncesData = [self.noncesToFetch mapWithBlock:^NSData *(NSUUID *nonce) { return nonce.data; }];
    NSPredicate *messagePredicate = [self predicateForKey:ZMMessageNonceDataKey matchingValues:noncesData];
    NSFetchRequest *messagesRequest = [ZMMessage sortedFetchRequestWithPredicate:messagePredicate];
    messagesRequest.returnsObjectsAsFaults = NO;
    
    return [moc executeFetchRequestOrAssert:messagesRequest];
}

- (NSArray <ZMConversation *>*)fetchConversationsInManagedObjectContext:(NSManagedObjectContext *)moc
{
    NSSet *identifierData = [self.remoteIdentifiersToFetch mapWithBlock:^NSData *(NSUUID *identifier) { return identifier.data; }];
    NSPredicate *conversationPredicate = [self predicateForKey:ZMConversationRemoteIdentifierDataKey matchingValues:identifierData];
    NSFetchRequest *conversationRequest = [ZMConversation sortedFetchRequestWithPredicate:conversationPredicate];
    conversationRequest.returnsObjectsAsFaults = NO;
    return [moc executeFetchRequestOrAssert:conversationRequest];
}

- (NSPredicate *)predicateForKey:(NSString *)key matchingValues:(NSSet *)values
{
    return [NSPredicate predicateWithFormat:@"%@ CONTAINS %K", values, key];
}

@end



@implementation NSManagedObjectContext (ZMFetchRequestBatch)

- (ZMFetchRequestBatchResult *)executeFetchRequestBatchOrAssert:(ZMFetchRequestBatch *)fetchRequestbatch
{
    return [fetchRequestbatch executeInManagedObjectContext:self];
}

@end
