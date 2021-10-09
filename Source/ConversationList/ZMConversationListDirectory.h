// 
// 


@import Foundation;
@import CoreData;

@protocol LabelType;

@class Label;
@class ZMConversationList;
@class ZMSharableConversations;
@class NSManagedObjectContext;
@class ZMConversation;


extern NSString * _Nonnull const SaveHugeNoMuteConversationsNotificationName;

@interface ZMConversationListDirectory : NSObject <NSFetchedResultsControllerDelegate>

@property (nonatomic, readonly, nonnull) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, readonly, nonnull) ZMConversationList* pendingConnectionConversations; ///< pending
@property (nonatomic, readonly, nonnull) ZMConversationList* unarchivedConversations; /// < unarchived, not pending
@property (nonatomic, readonly, nonnull) ZMConversationList *hugeGroupConversations; /// conversations with type == 5
@property (nonatomic, readonly, nonnull) ZMConversationList *topIncludeUnreadMessageConversations;
@property (nonatomic, readonly, nonnull) ZMConversationList *topExcludeUnreadMessageConversations;
@property (nonatomic, readonly, nonnull) ZMConversationList *topConversations;
@property (nonatomic, readonly, nonnull) ZMConversationList *excludeTopAndNotDisturbedConversations;
@property (nonatomic, readonly, nonnull) ZMConversationList *doNotDisturbedConversations;
@property (nonatomic, readonly, nonnull) ZMConversationList *unreadMessageConversations;


@property (nonatomic, readonly, nonnull) NSMutableDictionary<NSManagedObjectID *, ZMConversationList *> *listsByFolder;
@property (nonatomic, readonly, nonnull) NSArray<id<LabelType>> *allFolders;

- (nonnull NSArray<ZMConversationList *> *)allConversationLists;


/// Refetches all conversation lists and resets the snapshots
/// Call this when the app re-enters the foreground
- (void)refetchAllListsInManagedObjectContext:(NSManagedObjectContext * _Nonnull)moc;
- (void)insertFolders:(NSArray<Label *> * _Nonnull)labels;
- (void)deleteFolders:(NSArray<Label *> * _Nonnull)labels;

@end



@interface NSManagedObjectContext (ZMConversationListDirectory)

- (nonnull ZMConversationListDirectory *)conversationListDirectory;


- (nonnull NSArray<ZMConversation *> *)sharedConversationList;


- (nonnull NSArray<ZMConversation *> *)filterSharedConversationListWithSearchText:(NSString * _Nonnull)text;
@end
