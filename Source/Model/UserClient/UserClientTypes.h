// 
// 


@import Foundation;

typedef NSString * ZMUserClientType NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(DeviceType);

extern ZMUserClientType const _Nonnull ZMUserClientTypePermanent;
extern ZMUserClientType const _Nonnull ZMUserClientTypeTemporary;
extern ZMUserClientType const _Nonnull ZMUserClientTypeLegalHold;

typedef NSString * ZMUserClientDeviceClass NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(DeviceClass);

extern ZMUserClientDeviceClass const _Nonnull ZMUserClientDeviceClassPhone;
extern ZMUserClientDeviceClass const _Nonnull ZMUserClientDeviceClassTablet;
extern ZMUserClientDeviceClass const _Nonnull ZMUserClientDeviceClassDesktop;
extern ZMUserClientDeviceClass const _Nonnull ZMUserClientDeviceClassLegalHold;
