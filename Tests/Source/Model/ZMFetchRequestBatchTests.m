// 
// 


@import WireDataModel;
@import WireTesting;

#import "ZMBaseManagedObjectTest.h"
#import "ZMFetchRequestBatch.h"

@interface ZMFetchRequestBatchTests : ZMBaseManagedObjectTest

@property (nonatomic) ZMFetchRequestBatch *sut;

@end

@implementation ZMFetchRequestBatchTests

- (void)setUp {
    [super setUp];
    self.sut = [[ZMFetchRequestBatch alloc] init];
}

- (void)tearDown {
    self.sut = nil;
    [super tearDown];
}

- (void)testThatItAddsNoncesToNoncesToFetch {
    
    // given
    NSSet *nonces = [self returnNoncesInsertingAndFaultingMessagesCount:2 inContext:self.uiMOC];
    
    // when
    [self.sut addNoncesToPrefetchMessages:nonces];
    [self.sut addNoncesToPrefetchMessages:nonces];
    
    // then
    NSSet *noncesToFetch = self.sut.noncesToFetch;
    
    XCTAssertEqual(noncesToFetch.count, 2lu);
    XCTAssertEqualObjects(noncesToFetch, nonces);
}

- (void)testThatItAddsRemoteIdentifiersToIdentifiersToFetch {
    
    // given
    NSUUID *identifier = NSUUID.createUUID;
    
    // when
    [self.sut addConversationRemoteIdentifiersToPrefetchConversations:[NSSet setWithObject:identifier]];
    [self.sut addConversationRemoteIdentifiersToPrefetchConversations:[NSSet setWithObject:identifier]];
    
    // then
    NSSet *identifiersToFetch = self.sut.remoteIdentifiersToFetch;
    
    XCTAssertEqual(identifiersToFetch.count, 1lu);
    XCTAssertEqualObjects(identifiersToFetch.anyObject, identifier);
}

- (void)testThatItFetchesMessagesAndConversationsAndReturnsTheCorrectResult
{
    // given
    NSSet *nonces = [self returnNoncesInsertingAndFaultingMessagesCount:5 inContext:self.uiMOC];
    [self returnNoncesInsertingAndFaultingMessagesCount:5 inContext:self.uiMOC];
    
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeOneOnOne;
    conversation.remoteIdentifier = NSUUID.createUUID;
    NSUUID *unavailableUUID = NSUUID.createUUID;
    NSSet *remoteIdentifiers = [NSSet setWithObjects:conversation.remoteIdentifier, unavailableUUID, nil];
    
    // when
    [self.sut addNoncesToPrefetchMessages:nonces];
    [self.sut addConversationRemoteIdentifiersToPrefetchConversations:remoteIdentifiers];
    ZMFetchRequestBatchResult *result = [self.uiMOC executeFetchRequestBatchOrAssert:self.sut];
    
    // then
    XCTAssertNotNil(result.messagesByNonce);
    XCTAssertEqual(result.messagesByNonce.count, 5lu);
    
    NSArray <ZMConversation *>*fetchedConversations = result.conversationsByRemoteIdentifier.allValues;
    NSArray <ZMMessage *> *fetchedMessages = [result.messagesByNonce.allValues flattenWithBlock:^NSArray *(NSSet *messages) {
        return messages.allObjects;
    }];

    for (NSManagedObject *object in [(NSArray *)fetchedMessages arrayByAddingObjectsFromArray:fetchedConversations]) {
        XCTAssertFalse(object.isFault);
    }
    
    XCTAssertEqual(fetchedMessages.count, 5lu);
    
    XCTAssertNotNil(result.conversationsByRemoteIdentifier);
    XCTAssertEqual(result.conversationsByRemoteIdentifier.count, 1lu);
    
    NSSet *fetchedNonces = [NSSet setWithArray:[fetchedMessages mapWithBlock:^NSUUID *(ZMMessage *msg) { return msg.nonce; }]];
    
    XCTAssertEqualObjects(fetchedNonces, nonces);
    XCTAssertEqualObjects(conversation.remoteIdentifier, result.conversationsByRemoteIdentifier.allValues.firstObject.remoteIdentifier);
}

#pragma mark - Helper

- (NSSet *)returnNoncesInsertingAndFaultingMessagesCount:(NSUInteger)count inContext:(NSManagedObjectContext *)moc
{
    NSMutableSet *nonces = [NSMutableSet set];
    for (NSUInteger idx = 0; idx < count; idx++) {
        NSUUID *nonce = NSUUID.createUUID;
        ZMMessage *message = [[ZMMessage alloc] initWithNonce:nonce managedObjectContext:moc];
        NOT_USED(message);
        [nonces addObject:nonce];
    }
    
    [moc refreshAllObjects];
    
    return nonces;
}

@end
