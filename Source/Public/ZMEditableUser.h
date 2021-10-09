// 
// 


@import WireSystem;

#import <WireUtilities/ZMAccentColor.h>
#import "ZMUser.h"

@class ZMEmailCredentials;
@class ZMPhoneCredentials;

@protocol ZMEditableUser <NSObject>

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *reMark;
@property (nonatomic) ZMAccentColor accentColorValue;
@property (nonatomic, copy, readonly) NSString *emailAddress;
@property (nonatomic, copy, readonly) NSString *phoneNumber;
@property (nonatomic) BOOL readReceiptsEnabled;
@property (nonatomic) BOOL needsRichProfileUpdate;

@end
