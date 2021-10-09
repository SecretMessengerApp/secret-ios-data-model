// 
// 


#import "ZMManagedObject.h"
#import <CoreGraphics/CoreGraphics.h>

@class ZMUser;
@class ZMConversation;
@class UserClient;
@class LinkMetadata;
@class Mention;
@class ZMMessage;

@protocol ZMImageMessageData;
@protocol ZMSystemMessageData;
@protocol ZMKnockMessageData;
@protocol ZMFileMessageData;
@protocol UserClientType;
@class ServiceMessage;


#pragma mark - ZMImageMessageData


@protocol ZMImageMessageData <NSObject>

@property (nonatomic, readonly, nullable) NSData *imageData; ///< This will either returns the mediumData or the original image data. Useful only for newly inserted messages.
@property (nonatomic, readonly, nullable) NSString *imageDataIdentifier; /// This can be used as a cache key for @c -imageData

@property (nonatomic, readonly) BOOL isAnimatedGIF; // If it is GIF and has more than 1 frame
@property (nonatomic, readonly) BOOL isDownloaded; // If the image has been downloaded and cached locally
@property (nonatomic, readonly, nullable) NSString *imageType; // UTI e.g. kUTTypeGIF
@property (nonatomic, readonly) CGSize originalSize;

//@property (nonatomic, readonly, nullable) ZMMessage *quote;
///// Detect if user replies to a message sent from himself
//@property (nonatomic, readonly) BOOL isQuotingSelf;
//
///// Check if message has a quote
//@property (nonatomic, readonly) BOOL hasQuote;
- (void)fetchImageDataWithQueue:(dispatch_queue_t _Nonnull )queue completionHandler:(void (^_Nonnull)(NSData * _Nullable imageData))completionHandler;

/// Request the download of the image if not already present.
/// The download will be executed asynchronously. The caller can be notified by observing the message window.
/// This method can safely be called multiple times, even if the content is already available locally
- (void)requestFileDownload;

@end


#pragma mark - ZMSystemMessageData


typedef NS_ENUM(int16_t, ZMSystemMessageType) {
    ZMSystemMessageTypeInvalid = 0,
    ZMSystemMessageTypeParticipantsAdded,
    ZMSystemMessageTypeParticipantsRemoved,
    ZMSystemMessageTypeConversationNameChanged,
    ZMSystemMessageTypeConnectionRequest,
    ZMSystemMessageTypeConnectionUpdate,
    ZMSystemMessageTypeMissedCall,
    ZMSystemMessageTypeNewClient,
    ZMSystemMessageTypeIgnoredClient,
    ZMSystemMessageTypeConversationIsSecure,
    ZMSystemMessageTypePotentialGap,
    ZMSystemMessageTypeDecryptionFailed,
    ZMSystemMessageTypeDecryptionFailed_RemoteIdentityChanged,
    ZMSystemMessageTypeNewConversation,
    ZMSystemMessageTypeReactivatedDevice,
    ZMSystemMessageTypeUsingNewDevice,
    ZMSystemMessageTypeMessageDeletedForEveryone,
    ZMSystemMessageTypePerformedCall,
    ZMSystemMessageTypeTeamMemberLeave,
    ZMSystemMessageTypeMessageTimerUpdate,
    ZMSystemMessageTypeReadReceiptsEnabled,
    ZMSystemMessageTypeReadReceiptsDisabled,
    ZMSystemMessageTypeReadReceiptsOn,
    ZMSystemMessageTypeLegalHoldEnabled,
    ZMSystemMessageTypeLegalHoldDisabled,
    ZMSystemMessageTypeAllDisableSendMsg,
    ZMSystemMessageTypeMemberDisableSendMsg,
    ZMSystemMessageTypeServiceMessage,
    ZMSystemMessageTypeManagerMsg,
    ZMSystemMessageTypeCreatorChangeMsg,
    ZMSystemMessageTypeAllowAddFriend,
    ZMSystemMessageTypeMessageVisible,
    ZMSystemMessageTypeShowMemsum,
    ZMSystemMessageTypeEnabledEditMsg,
    ZMSystemMessageTypeAllowViewmen,
    ZMSystemMessageTypeEnabledEditPersonalMsg,
    ZMSystemMessageTypeScreenShotOpened,
    ZMSystemMessageTypeScreenShotClosed
};

typedef NS_ENUM(int16_t, ZMSystemManagerMessageType) {
    ZMSystemManagerMessageTypeMeBecameManager = 0,
    ZMSystemManagerMessageTypeOtherBecameManager,
    ZMSystemManagerMessageTypeMeDropManager,
    ZMSystemManagerMessageTypeOtherDropManager,
};

@protocol ZMJsonTextMessageData <NSObject>

@property (nonatomic, readonly, nullable) NSString *jsonMessageText;

@end

@protocol ZMTextMessageData <NSObject>

@property (nonatomic, readonly, nullable) NSString *messageText;
@property (nonatomic, readonly, nullable) LinkMetadata *linkPreview;
@property (nonatomic, readonly, nonnull) NSArray<Mention *> *mentions;
@property (nonatomic, readonly, nullable) ZMMessage *quote;

/// Returns true if the link preview will have an image
@property (nonatomic, readonly) BOOL linkPreviewHasImage;

@property (nonatomic, readonly) BOOL isMarkDown;

/// Unique identifier for link preview image.
@property (nonatomic, readonly, nullable) NSString *linkPreviewImageCacheKey;

/// Detect if user replies to a message sent from himself
@property (nonatomic, readonly) BOOL isQuotingSelf;

/// Check if message has a quote
@property (nonatomic, readonly) BOOL hasQuote;

/// Fetch linkpreview image data from disk on the given queue
- (void)fetchLinkPreviewImageDataWithQueue:(dispatch_queue_t _Nonnull )queue completionHandler:(void (^_Nonnull)(NSData * _Nullable imageData))completionHandler;

/// Request link preview image to be downloaded
- (void)requestLinkPreviewImageDownload;

/// Edit the text content
- (void)editText:(NSString * _Nonnull)text mentions:(NSArray<Mention *> * _Nonnull)mentions fetchLinkPreview:(BOOL)fetchLinkPreview;

@end


@protocol ZMSystemMessageData <NSObject>

@property (nonatomic, readonly) ZMSystemMessageType systemMessageType;
@property (nonatomic, readonly, nonnull) NSSet <ZMUser *>*users;
@property (nonatomic, readonly, nonnull) NSSet <id<UserClientType>>*clients;
@property (nonatomic, nonnull) NSSet<ZMUser *> *addedUsers; // Only filled for ZMSystemMessageTypePotentialGap
@property (nonatomic, nonnull) NSSet<ZMUser *> *removedUsers; // Only filled for ZMSystemMessageTypePotentialGap
@property (nonatomic, readonly, copy, nullable) NSString *text;
@property (nonatomic) BOOL needsUpdatingUsers;
@property (nonatomic) NSTimeInterval duration;
/**
  Only filled for .performedCall & .missedCall
 */
@property (nonatomic, nonnull) NSSet<id <ZMSystemMessageData>>  *childMessages;
@property (nonatomic, nullable) id <ZMSystemMessageData> parentMessage;
@property (nonatomic, readonly) BOOL userIsTheSender;
@property (nonatomic, nullable) NSNumber *messageTimer;
@property (nonatomic, nullable) NSNumber *blockTime;
@property (nonatomic, nullable) NSString *opt_id;
@property (nonatomic, nullable) NSNumber *blockDuration;
@property (nonatomic, nullable) NSString *blockUser;
@property (nonatomic, nullable) NSString *add_friend;
@property (nonatomic, nullable) NSString *changeCreatorId;
@property (nonatomic, nullable) NSString *showMemsum;
@property (nonatomic, nullable) NSString *enabledEditMsg;
@property (nonatomic, nullable) NSString *viewmem;
//@property (nonatomic, nullable) NSString *enabledEditPersonalMsgStr;

@property (nonatomic) ZMSystemManagerMessageType managerType;
@property (nonatomic, nullable) ServiceMessage *serviceMessage;
@property (nonatomic, readonly, nullable) NSOrderedSet <NSString *>*userIDs;
@property (nonatomic, readonly, nullable) NSArray <NSString *>*userNames;
@property (nonatomic, readonly, nullable) NSString *messageVisible;
@end


#pragma mark - ZMKnockMessageData


@protocol ZMKnockMessageData <NSObject>

@end

typedef NS_ENUM(int16_t, ZMLinkPreviewState) {
    /// Link preview has been sent or message did not contain any preview
    ZMLinkPreviewStateDone = 0,
    /// Message text needs to be parsed to see if it contain any links
    ZMLinkPreviewStateWaitingToBeProcessed,
    /// Link preview have been downloaded
    ZMLinkPreviewStateDownloaded,
    /// Link preview assets have been processed & encrypted
    ZMLinkPreviewStateProcessed,
    /// Link preview assets have been uploaded
    ZMLinkPreviewStateUploaded
};
