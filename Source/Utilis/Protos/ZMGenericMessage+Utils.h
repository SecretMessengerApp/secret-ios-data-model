// 
// 


@import UIKit;
@import WireImages;
@import WireProtos;

@class ZMIImageProperties;
@class ZMConversation;


@interface ZMImageAssetEncryptionKeys: NSObject

/// Key used for symmetric encryption of the asset
@property (nonatomic, copy, readonly, nonnull) NSData *otrKey;
/// HMAC key used to compute the digest
@property (nonatomic, copy, readonly, nullable) NSData *macKey;
/// HMAC digest
@property (nonatomic, copy, readonly, nullable) NSData *mac;
/// SHA-256 digest
@property (nonatomic, copy, readonly, nullable) NSData *sha256;
/// Wether it has a HMAC digest
@property (nonatomic, readonly) BOOL hasHMACDigest;
/// Wether it has a SHA256 digest
@property (nonatomic, readonly) BOOL hasSHA256Digest;


- (nonnull instancetype)initWithOtrKey:(nonnull NSData *)otrKey macKey:(nonnull NSData *)macKey mac:(nonnull NSData *)mac;
- (nonnull instancetype)initWithOtrKey:(nonnull NSData *)otrKey sha256:(nonnull NSData *)sha256;

@end


NS_ASSUME_NONNULL_BEGIN

@interface ZMGenericMessage (Utils)

- (BOOL)knownMessage;

@end

NS_ASSUME_NONNULL_END


@interface ZMImageAsset (Internal)

- (ZMImageFormat)imageFormat;
+ (nonnull instancetype)imageAssetWithMediumProperties:(nullable ZMIImageProperties *)mediumFormatProperties
                           processedProperties:(nullable ZMIImageProperties *)processedProperties
                                encryptionKeys:(nullable ZMImageAssetEncryptionKeys *)encryptionKeys
                                        format:(ZMImageFormat)format;
+ (nullable instancetype)imageAssetWithData:(nullable NSData *)imageData format:(ZMImageFormat)format;

@end


