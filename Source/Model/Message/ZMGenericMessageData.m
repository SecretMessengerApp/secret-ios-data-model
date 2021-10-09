// 
// 


@import WireProtos;
@import WireUtilities;

#import "ZMGenericMessageData.h"
#import <WireDataModel/WireDataModel-Swift.h>

static NSString * const ZMGenericMessageDataDataKey = @"data";

NSString * const ZMGenericMessageDataMessageKey = @"message";
NSString * const ZMGenericMessageDataAssetKey = @"asset";

@implementation ZMGenericMessageData

@dynamic data;
@dynamic message;
@dynamic asset;

+ (NSString *)entityName
{
    return @"GenericMessageData";
}

- (ZMGenericMessage *)genericMessage
{
    ZMGenericMessageBuilder *builder = (ZMGenericMessageBuilder *)[[ZMGenericMessage builder] mergeFromData:self.data];
    return [builder build];
}

- (NSSet *)modifiedKeys
{
    return [NSSet set];
}

- (void)setModifiedKeys:(NSSet *)keys
{
    NOT_USED(keys);
}

@end

