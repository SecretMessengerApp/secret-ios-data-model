// 
// 


@import CoreData;
#import "ZMManagedObject.h"

@class ZMGenericMessage;
@class ZMMessage;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const ZMGenericMessageDataMessageKey;
extern NSString * const ZMGenericMessageDataAssetKey;

NS_ASSUME_NONNULL_END

@interface ZMGenericMessageData: ZMManagedObject

@property (nonatomic, nonnull) NSData *data;
@property (nonatomic, readonly, nullable) ZMGenericMessage *genericMessage;
@property (nonatomic, nullable) ZMMessage *message;
@property (nonatomic, nullable) ZMMessage *asset;

+ (NSString * _Nonnull)entityName;

@end
