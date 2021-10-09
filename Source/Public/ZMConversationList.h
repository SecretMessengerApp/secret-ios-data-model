// 
// 


@class ZMUserSession;
@protocol ZMManagedObjectContextProvider;


/// Use @c ZMConversationListChangeNotification to get notified about changes.
@interface ZMConversationList : NSArray

@property (nonatomic, readonly, nonnull) NSString *identifier;
@property (nonatomic, readonly, nullable) Label *label;

- (void)resort;

/// Call this when the app enters the background and reenters the foreground
/// It recreates the backinglist and notifies the conversationlist observer center about the update
- (void)recreateWithAllConversations:( NSArray * _Nonnull )conversations;

@end


@interface ZMConversationList (UserSession)

/// Refetches all conversation lists and resets the snapshots
/// Call this when the app re-enters the foreground
+ (void)refetchAllListsInUserSession:(nonnull id<ZMManagedObjectContextProvider>)session;

+ (nonnull ZMConversationList *)conversationsIncludingArchivedInUserSession:(nonnull id<ZMManagedObjectContextProvider>)session;
+ (nonnull ZMConversationList *)conversationsInUserSession:(nonnull id<ZMManagedObjectContextProvider>)session;
+ (nonnull ZMConversationList *)archivedConversationsInUserSession:(nonnull id<ZMManagedObjectContextProvider>)session;
+ (nonnull ZMConversationList *)pendingConnectionConversationsInUserSession:(nonnull id<ZMManagedObjectContextProvider>)session;
+ (nonnull ZMConversationList *)clearedConversationsInUserSession:(nonnull id<ZMManagedObjectContextProvider>)session;
+ (nonnull ZMConversationList *)excludeUnreadTopConversationsInUserSession:(nonnull id<ZMManagedObjectContextProvider>)session;
+ (nonnull ZMConversationList *)excludeTopAndNoDisturdedConversationsInUserSession:(nonnull id<ZMManagedObjectContextProvider>)session;
+ (nonnull ZMConversationList *)noDisturdedConversationsInUserSession:(nonnull id<ZMManagedObjectContextProvider>)session;
@end
