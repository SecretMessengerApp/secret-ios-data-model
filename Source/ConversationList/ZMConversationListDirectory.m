// 
// 


#import "ZMConversationListDirectory.h"
#import "ZMConversation+Internal.h"
#import "ZMConversationList+Internal.h"
#import <WireDataModel/WireDataModel-Swift.h>

static NSString * const ConversationListDirectoryKey = @"ZMConversationListDirectoryMap";

static NSString * const AllKey = @"All";
static NSString * const UnarchivedKey = @"Unarchived";
static NSString * const ArchivedKey = @"Archived";
static NSString * const PendingKey = @"Pending";

NSString *const SaveHugeNoMuteConversationsNotificationName = @"SaveHugeNoMuteConversationsNotificationName";
NSString *const AllConversationListCacheNameKey = @"AllConversationListCacheNameKey";


@interface ZMConversationListDirectory () <ZMUserObserver>

@property (nonatomic) ZMConversationList* hugeGroupConversations;
@property (nonatomic) ZMConversationList* unarchivedConversations;
@property (nonatomic) ZMConversationList* pendingConnectionConversations;
@property (nonatomic) ZMConversationList* topIncludeUnreadMessageConversations;
@property (nonatomic) ZMConversationList* topExcludeUnreadMessageConversations;
@property (nonatomic) ZMConversationList* excludeTopAndNotDisturbedConversations;
@property (nonatomic) ZMConversationList*
    topConversations;
@property (nonatomic) ZMConversationList*
    doNotDisturbedConversations;
@property (nonatomic) ZMConversationList*
    unreadMessageConversations;

@property (nonatomic, readwrite) NSMutableDictionary<NSManagedObjectID *, ZMConversationList *> *listsByFolder;
@property (nonatomic) FolderList *folderList;

@property (nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) NSFetchedResultsController *fetchAllConversationController;

@end



@implementation ZMConversationListDirectory

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)moc
{
    self = [super init];
    if (self) {
        self.managedObjectContext = moc;
        
        NSArray *allConversations = [self fetchAllConversations:moc];

        self.unarchivedConversations = [[ZMConversationList alloc] initWithAllConversations:allConversations
                                                                         filteringPredicate:ZMConversation.predicateForConversationsExcludingArchived
                                                                                        moc:moc
                                                                                description:@"unarchivedConversations"];
        
        self.pendingConnectionConversations = [[ZMConversationList alloc] initWithAllConversations:allConversations
                                                                                filteringPredicate:ZMConversation.predicateForPendingConversations
                                                                                               moc:moc
                                                                                  description:@"pendingConnectionConversations"];
        
        self.doNotDisturbedConversations = [[ZMConversationList alloc] initWithAllConversations:allConversations
                                                                             filteringPredicate:ZMConversation.predicateForDoNotDisturbedConversations
                                                                                            moc:moc
                                                                                    description:@"doNotDisturbedConversations"];
        
        self.hugeGroupConversations = [[ZMConversationList alloc] initWithAllConversations:allConversations
                                                                        filteringPredicate:ZMConversation.predicateForHugeGroupConversations
                                                                                       moc:moc
                                                                               description:@"hugeGroupConversations"];
        
        self.topIncludeUnreadMessageConversations = [[ZMConversationList alloc] initWithAllConversations:allConversations
                                                                        filteringPredicate: ZMConversation.predicateForIncludeUnreadMessageTopGroupConversations
                                                                                       moc:moc
                                                                               description:@"topIncludeUnreadMessageConversations"];
        
        self.topExcludeUnreadMessageConversations = [[ZMConversationList alloc] initWithAllConversations:allConversations
                                                                        filteringPredicate:ZMConversation. predicateForExcludeUnreadMessageTopGroupConversations
                                                                                       moc:moc
                                                                               description:@"topExcludeUnreadMessageConversations"];
        
        
        self.topConversations = [[ZMConversationList alloc] initWithAllConversations:allConversations
                                                                        filteringPredicate:ZMConversation. predicateForTopGroupConversations
                                                                                       moc:moc
                                                                               description:@"topeConversations"];
        
        self.excludeTopAndNotDisturbedConversations = [[ZMConversationList alloc] initWithAllConversations:allConversations
                                                                        filteringPredicate:ZMConversation. predicateForExcludeTopAndNotDisturbedGroupConversations
                                                                                       moc:moc
                                                                               description:@"excludeTopAndNotDisturbedConversations"];
        self.unreadMessageConversations = [[ZMConversationList alloc] initWithAllConversations:allConversations
                                                                            filteringPredicate:ZMConversation. predicateForUnreadMessageConversations
                                                                                           moc:moc
                                                                                   description:@"unreadMessageConversations"];
    }
    return self;
}

- (NSArray *)fetchAllConversations:(NSManagedObjectContext *)context
{
    NSFetchRequest *allConversationsRequest = [ZMConversation sortedFetchRequest];
    ZMUser *user = [ZMUser selfUserInContext:context];
    allConversationsRequest.returnsObjectsAsFaults = NO;
    // Since this is extremely likely to trigger the "lastServerSyncedActiveParticipants" and "connection" relationships, we make sure these gets prefetched:
    NSMutableArray *keyPaths = [NSMutableArray arrayWithArray:allConversationsRequest.relationshipKeyPathsForPrefetching];
    [keyPaths addObject:ZMConversationLastServerSyncedActiveParticipantsKey];
    [keyPaths addObject:@"connection.status"];
    [keyPaths addObject:@"connection.to"];
    [keyPaths addObject:ZMConversationConnectionKey];
    [keyPaths addObject:ZMConversationLastServerSyncedActiveParticipantsKey];
    [keyPaths addObject:LastVisibleMessage];
    allConversationsRequest.propertiesToFetch = @[ZMConversationConversationTypeKey, ZMConversationIsPlacedTopKey, LastModifiedDateKey, ZMConversationRemoteIdentifierDataKey];
    allConversationsRequest.relationshipKeyPathsForPrefetching = keyPaths;
    self.fetchAllConversationController = [[NSFetchedResultsController alloc] initWithFetchRequest:allConversationsRequest managedObjectContext: context sectionNameKeyPath:nil cacheName: AllConversationListCacheNameKey];
    self.fetchAllConversationController.delegate = self;
    NSError *error;
    [self.fetchAllConversationController performFetch: &error];
    return self.fetchAllConversationController.fetchedObjects;
}

- (NSArray *)fetchAllFolders:(NSManagedObjectContext *)context
{
    return [context executeFetchRequestOrAssert:[Label sortedFetchRequest]];
}

- (NSMutableDictionary *)createListsFromFolders:(NSArray<Label *> *)folders allConversations:(NSArray<ZMConversation *> *)allConversations
{
    NSMutableDictionary *listsByFolder = [NSMutableDictionary new];

    for (Label *folder in folders) {
        listsByFolder[folder.objectID] = [self createListForFolder:folder allConversations:allConversations];
    }
    
    return listsByFolder;
}

- (ZMConversationList *)createListForFolder:(Label *)folder allConversations:(NSArray<ZMConversation *> *)allConversations
{
    return [[ZMConversationList alloc] initWithAllConversations:allConversations
                                             filteringPredicate:[ZMConversation predicateForLabeledConversations:folder]
                                                            moc:self.managedObjectContext
                                                    description:folder.objectIDURLString
                                                          label:folder];
}

- (void)insertFolders:(NSArray<Label *> *)labels
{
    if (labels.count == 0) {
        return;
    }
    
    NSArray<ZMConversation *> *allConversations = [self fetchAllConversations:self.managedObjectContext];
    for (Label *label in labels) {        
        ZMConversationList *folderList = [self createListForFolder:label allConversations:allConversations];
        self.listsByFolder[label.objectID] = folderList;
        [self.folderList insertLabel:label];
    }
}

- (void)deleteFolders:(NSArray<Label *> *)labels
{
    if (labels.count == 0) {
        return;
    }
    
    for (Label *label in labels) {
        [self.listsByFolder removeObjectForKey:label.objectID];
        [self.folderList removeLabel:label];
    }
}

- (void)refetchAllListsInManagedObjectContext:(NSManagedObjectContext *)moc
{
    NSArray *allConversations = [self fetchAllConversations:moc];
    for (ZMConversationList* list in self.allConversationLists){
        [list recreateWithAllConversations:allConversations];
    }
    
    NSArray *allFolders = [self fetchAllFolders:moc];
    self.folderList = [[FolderList alloc] initWithLabels:allFolders];
    self.listsByFolder = [self createListsFromFolders:allFolders allConversations:allConversations];
}

- (NSArray *)allConversationLists;
{
    return @[
             self.pendingConnectionConversations,
             self.unarchivedConversations,
             self.topIncludeUnreadMessageConversations,
             self.topExcludeUnreadMessageConversations,
             self.topConversations,
             self.doNotDisturbedConversations,
             self.excludeTopAndNotDisturbedConversations
             ];
}

- (NSArray<id<LabelType>> *)allFolders
{
    return self.folderList.backingList;
}



@end



@implementation NSManagedObjectContext (ZMConversationListDirectory)

- (ZMConversationListDirectory *)conversationListDirectory;
{
    ZMConversationListDirectory *directory = self.userInfo[ConversationListDirectoryKey];
    if (directory == nil) {
        directory = [[ZMConversationListDirectory alloc] initWithManagedObjectContext:self];
        self.userInfo[ConversationListDirectoryKey] = directory;
    }
    return directory;
}

- (NSArray<ZMConversation *> *)sharedConversationList;
{
    NSFetchRequest *request = [ZMConversation sortedFetchRequest];
    request.fetchLimit = 100;
    
    NSError *error;
    return [self executeFetchRequest:request error:&error];
    NSAssert(error != nil, @"Failed to fetch");
}

- (NSArray<ZMConversation *> *)filterSharedConversationListWithSearchText:(NSString *)text;
{
    NSPredicate *predicate = [ZMConversation predicateInSharedConversationsForSearchQuery:text];
    NSFetchRequest *fetchRequest = [ZMConversation sortedFetchRequestWithPredicate:predicate];
    fetchRequest.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"normalizedUserDefinedName" ascending:YES]];
    fetchRequest.fetchLimit = 50;
    
    NSError *error;
    return [self executeFetchRequest:fetchRequest error:&error];
    NSAssert(error != nil, @"Failed to fetch");
}
@end


