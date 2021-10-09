// 
// 


@import WireTesting;
@import WireProtos;
@import WireUtilities;
@import WireDataModel;


@interface ZMGenericMessage_ExternalTests : ZMTBaseTest

@property (nonatomic, nonnull) ZMGenericMessage *sut;

@end


@implementation ZMGenericMessage_ExternalTests

- (void)setUp {
    [super setUp];
    ZMGenericMessageBuilder *builder = ZMGenericMessage.builder;
    ZMTextBuilder *textBuilder = ZMText.builder;
    textBuilder.content = @"She sells sea shells";
    builder.text = textBuilder.build;
    builder.messageId = NSUUID.createUUID.transportString;
    self.sut = builder.build;
    XCTAssertTrue(self.sut.hasText);
}

- (void)tearDown {
    _sut = nil;
    [super tearDown];
}

- (void)testThatItEncryptsTheMessageAndReturnsTheCorrectKeyAndDigest
{
    // given & when
    ZMExternalEncryptedDataWithKeys *dataWithKeys = [ZMGenericMessage encryptedDataWithKeysFromMessage:self.sut];
    XCTAssertNotNil(dataWithKeys);
    
    ZMEncryptionKeyWithChecksum *keysWithDigest = dataWithKeys.keys;
    NSData *data = dataWithKeys.data;
    
    // then
    XCTAssertEqualObjects(data.zmSHA256Digest, keysWithDigest.sha256);
    XCTAssertEqualObjects([data zmDecryptPrefixedPlainTextIVWithKey:keysWithDigest.aesKey], self.sut.data);
}

- (void)testThatItUsesADifferentKeyForEachCall
{
    // given & when
    ZMExternalEncryptedDataWithKeys *firstDataWithKeys = [ZMGenericMessage encryptedDataWithKeysFromMessage:self.sut];
    ZMExternalEncryptedDataWithKeys *secondDataWithKeys = [ZMGenericMessage encryptedDataWithKeysFromMessage:self.sut];

    // then
    XCTAssertNotEqualObjects(firstDataWithKeys.keys.aesKey, secondDataWithKeys.keys.aesKey);
    XCTAssertNotEqualObjects(firstDataWithKeys, secondDataWithKeys);
    NSData *firstEncrypted = [firstDataWithKeys.data zmDecryptPrefixedPlainTextIVWithKey:firstDataWithKeys.keys.aesKey];
    NSData *secondEncrypted = [secondDataWithKeys.data zmDecryptPrefixedPlainTextIVWithKey:secondDataWithKeys.keys.aesKey];
    
    XCTAssertEqualObjects(firstEncrypted, self.sut.data);
    XCTAssertEqualObjects(secondEncrypted, self.sut.data);
}

- (void)testThatDifferentKeysAreNotConsideredEqual
{
    // given & when
    ZMEncryptionKeyWithChecksum *firstKeys = [ZMGenericMessage encryptedDataWithKeysFromMessage:self.sut].keys;
    ZMEncryptionKeyWithChecksum *secondKeys = [ZMGenericMessage encryptedDataWithKeysFromMessage:self.sut].keys;
    
    // then
    XCTAssertFalse([firstKeys.aesKey isEqualToData:secondKeys.aesKey]);
    XCTAssertFalse([firstKeys.sha256 isEqualToData:secondKeys.sha256]);
    XCTAssertEqualObjects(firstKeys, firstKeys);
    XCTAssertNotEqualObjects(firstKeys, secondKeys);
}

@end
