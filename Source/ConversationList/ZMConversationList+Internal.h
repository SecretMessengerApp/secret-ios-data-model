// 
// 


#import <Foundation/Foundation.h>
#import "ZMConversationList.h"

@class NSManagedObjectContext;
@class NSFetchRequest;
@class ZMConversation;


@interface ZMConversationList ()

@property (nonatomic, readonly) NSManagedObjectContext* managedObjectContext;

- (instancetype)initWithAllConversations:(NSArray *)conversations
                      filteringPredicate:(NSPredicate *)filteringPredicate
                                     moc:(NSManagedObjectContext *)moc
                            description:(NSString *)description;

- (instancetype)initWithAllConversations:(NSArray *)conversations
                      filteringPredicate:(NSPredicate *)filteringPredicate
                                     moc:(NSManagedObjectContext *)moc
                             description:(NSString *)description
                                   label:(Label *)label NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithObjects:(const id [])objects count:(NSUInteger)cnt NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

@end


@protocol ZMConversationListObserver;
@interface ZMConversationList (ZMUpdates)

- (BOOL)predicateMatchesConversation:(ZMConversation *)conversation;
- (BOOL)sortingIsAffectedByConversationKeys:(NSSet *)conversationKeys;
- (void)removeConversations:(NSSet *)conversations;
- (void)insertConversations:(NSSet *)conversations;
- (void)resortConversation:(ZMConversation *)conversation;

@end

