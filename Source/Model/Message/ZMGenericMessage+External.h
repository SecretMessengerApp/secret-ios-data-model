// 
// 


@import WireProtos;
@class ZMUpdateEvent;

@interface ZMEncryptionKeyWithChecksum: NSObject

/// AES Key used for the symmetric encryption of the data
@property (nonatomic, readonly) NSData *aesKey;
/// SHA-256 digest
@property (nonatomic, readonly) NSData *sha256;

@end


@interface ZMExternalEncryptedDataWithKeys : NSObject

/// The encrypted data
@property (nonatomic, readonly) NSData *data;
/// The AES Key used to encrypt @c data and the sha-256 digest of @c data
@property (nonatomic, readonly) ZMEncryptionKeyWithChecksum *keys;

@end


@interface ZMGenericMessage (External)

/// @abstract Helper to generate the payload for a generic message of type @c external
/// @discussion In case the payload of a regular (text) message is to large,
/// we need to symmetrically encrypt the original generic message using a generated
/// symmetric key. A generic message of type @c external which contains the key
/// used for the symmetric encryption and the sha-256 checksum og the encoded data needs to be created.
/// When sending the @c external message the encrypted original message should be attached to the payload
/// in the @c blob field of the protocol buffer.
/// @param message The message that should be encrypted to sent it as attached payload in a @c external message
/// @return The encrypted original message, the encryption key and checksum warpped in a @c ZMExternalEncryptedDataWithKeys
+ (ZMExternalEncryptedDataWithKeys *)encryptedDataWithKeysFromMessage:(ZMGenericMessage *)message;

/// @abstract Creates a genericMessage from a @c ZMUpdateEvent and @c ZMExternal
/// @discussion The symetrically encrypted data (representing the original @c ZMGenericMessage)
/// contained in the update event will be decrypted using the encryption keys in the @c ZMExternal
/// @param updateEvent The decrypted @c ZMUpdateEvent containing the external data
/// @param external @c The @c ZMExternal containing the otrKey used for the symmetric encryption and the sha256 checksum
/// @return The decrypted original @c ZMGenericMessage that was contained in the update event
+ (ZMGenericMessage *)genericMessageFromUpdateEventWithExternal:(ZMUpdateEvent *)updateEvent external:(ZMExternal *)external;

@end
