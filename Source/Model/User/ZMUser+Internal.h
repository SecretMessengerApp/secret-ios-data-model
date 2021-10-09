// 
// 


@import WireImages;

#import "ZMUser.h"
#import "ZMEditableUser.h"
#import "ZMManagedObject+Internal.h"
#import "ZMUser+OneOnOne.h"

@class ZMConnection;
@class Team;

extern NSString * __nonnull const SessionObjectIDKey;
extern NSString * __nonnull const UserClientsKey;
extern NSString * __nonnull const AvailabilityKey;
extern NSString * __nonnull const ReadReceiptsEnabledKey;

@interface ZMUser (Internal)

@property (null_unspecified, nonatomic) NSUUID *remoteIdentifier;
@property (nullable, nonatomic) ZMConnection *connection;

@property (nullable, nonatomic) NSUUID *teamIdentifier;

@property (nonnull, nonatomic) NSSet *showingUserAdded;
@property (nonnull, nonatomic) NSSet *showingUserRemoved;

@property (nonnull, nonatomic) NSSet<Team *> *createdTeams;

@property (nonnull, nonatomic, readonly) NSString *normalizedName;
@property (nonnull, nonatomic, readonly) NSString *normalizedRemark;
@property (nonnull, nonatomic, readonly) NSString *normalizedEmailAddress;

@property (nullable, nonatomic, readonly) NSData *imageMediumData;
@property (nullable, nonatomic, readonly) NSData *imageSmallProfileData;

- (void)updateWithTransportData:(nonnull NSDictionary *)transportData authoritative:(BOOL)authoritative;

+ (nullable instancetype)userWithRemoteID:(nonnull NSUUID *)UUID createIfNeeded:(BOOL)create inContext:(nonnull NSManagedObjectContext *)moc;

+ (nullable instancetype)userNoRowCacheWithRemoteID:(nonnull NSUUID *)UUID createIfNeeded:(BOOL)create inContext:(nonnull NSManagedObjectContext *)moc;
+ (nullable instancetype)userWithRemoteID:(nonnull NSUUID *)uuid createIfNeeded:(BOOL)create inConversation:(nonnull ZMConversation *)conversation inContext:(nonnull NSManagedObjectContext *)moc;
+ (nullable instancetype)userWithEmailAddress:(nonnull NSString *)emailAddress inContext:(nonnull NSManagedObjectContext *)context;
+ (nullable instancetype)userWithPhoneNumber:(nonnull NSString *)phoneNumber inContext:(nonnull NSManagedObjectContext *)context;


+ (nullable instancetype)userWithAiAddress:(nonnull NSString *)aiAddress inContext:(nonnull NSManagedObjectContext *)context;

+ (nonnull NSSet <ZMUser *> *)usersWithRemoteIDs:(nonnull NSSet <NSUUID *>*)UUIDs inContext:(nonnull NSManagedObjectContext *)moc;


+ (ZMAccentColor)accentColorFromPayloadValue:(nullable NSNumber *)payloadValue;

/// @method Updates the user with a name or handle received through a search
/// Should be called when creating a @c ZMSearchUser to ensure it's underlying user is updated.
- (void)updateWithSearchResultName:(nullable NSString *)name handle:(nullable NSString *)handle;


@end

@interface ZMUser (SelfUser)

+ (nonnull instancetype)selfUserInContext:(nonnull NSManagedObjectContext *)moc;
+ (void)boxSelfUser:(ZMUser * __nonnull)selfUser inContextUserInfo:(NSManagedObjectContext * __nonnull)moc;

@end



@interface ZMUser (Editable) <ZMEditableUser>

@property (nullable, nonatomic, copy) NSString *emailAddress;
@property (nullable, nonatomic, copy) NSString *phoneNumber;
@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, copy) NSString *reMark;
@property (nonatomic) ZMAccentColor accentColorValue;

- (void)setHandle:(NSString * __nullable)handle;
@property (nonatomic) BOOL needsPropertiesUpdate;
@property (nonatomic) BOOL readReceiptsEnabledChangedRemotely;
@property (nonatomic) BOOL needsRichProfileUpdate;

@end



@interface ZMUser (ImageData)

+ (nonnull NSPredicate *)predicateForSelfUser;
+ (nonnull NSPredicate *)predicateForUsersOtherThanSelf;

@end



@interface NSUUID (SelfUser)

- (BOOL)isSelfUserRemoteIdentifierInContext:(nonnull NSManagedObjectContext *)moc;

@end




@interface ZMSession : ZMManagedObject

@property (nonnull, nonatomic, strong) ZMUser *selfUser;

@end




@interface ZMUser (OTR)

- (nullable UserClient *)selfClient;

@end




@class ZMUserId;

@interface ZMUser (Protobuf)

- (nonnull ZMUserId *)userId;

@end

