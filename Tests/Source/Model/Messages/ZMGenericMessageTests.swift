//
//

import Foundation

@testable import WireDataModel

class GenericMessageTests: ZMTBaseTest {
    func testThatItChecksTheCommonMessageTypesAsKnownMessage() {
        let generators: [()->(ZMGenericMessage)] = [
            {
                return ZMGenericMessage.message(content: ZMText.text(with: "hello"))
            },
            {
                return ZMGenericMessage.message(content: ZMImageAsset(data: self.verySmallJPEGData(), format: .medium)!)
            },
            {
                return ZMGenericMessage.message(content: ZMKnock.knock())
            },
            {
                return ZMGenericMessage.message(content: ZMLastRead(timestamp: Date(), conversationRemoteID: UUID.create()))
            },
            {
                return ZMGenericMessage.message(content: ZMCleared(timestamp: Date(), conversationRemoteID: UUID.create()))
            },
            {
                var externalBuilder = ZMExternal.builder()!
                let base64SHA = "47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU="
                let base64OTRKey = "4H1nD6bG2sCxC/tZBnIG7avLYhkCsSfv0ATNqnfug7w="
                externalBuilder = externalBuilder.setOtrKey(Data(base64Encoded: base64OTRKey))
                externalBuilder = externalBuilder.setSha256(Data(base64Encoded: base64SHA))
                
                let messageBuilder = ZMGenericMessageBuilder()
                messageBuilder.setExternal(externalBuilder.build()!)
                messageBuilder.setMessageId(UUID.create().transportString())
                return messageBuilder.build()!
            },
            {
                return ZMGenericMessage.clientAction(.RESETSESSION)
            },
            {
                return ZMGenericMessage.message(content: ZMCalling.calling(message: "Calling"))
            },
            {
                return ZMGenericMessage.message(content: ZMAsset.asset(originalWithImageSize: .zero, mimeType: "image/jpeg", size: 0))
            },
            {
                return ZMGenericMessage.message(content: ZMMessageHide.hide(conversationId: UUID.create(), messageId: UUID.create()))
            },
            {
                return ZMGenericMessage.message(content: ZMLocation.location(withLatitude: 1, longitude: 2))
            },
            {
                return ZMGenericMessage.message(content: ZMMessageDelete.delete(messageId: UUID.create()))
            },
            {
                return ZMGenericMessage.message(content: ZMText.text(with: "Test"))
            },
            {
                return ZMGenericMessage.message(content: ZMReaction(emoji: "test", messageID: UUID.create()))
            },
            {
                return ZMGenericMessage.message(content: ZMKnock.knock(), expiresAfter: 10)
            },
            {
                return ZMGenericMessage.message(content: ZMAvailability.availability(.away))
            }
        ]
        
        generators.forEach { generator in
            // GIVEN
            let message = generator()
            // WHEN & THEN
            XCTAssertTrue(message.knownMessage())
        }
    }

}

