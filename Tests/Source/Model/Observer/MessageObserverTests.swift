//
//

import Foundation
@testable import WireDataModel

class MessageObserverTests : NotificationDispatcherTestBase {
    
    var messageObserver : MessageObserver!
    
    override func setUp() {
        super.setUp()
        messageObserver = MessageObserver()
    }

    override func tearDown() {
        messageObserver = nil
        super.tearDown()
    }
    
    func checkThatItNotifiesTheObserverOfAChange<T: ZMMessage>(
        _ message: T,
        modifier: (T) -> Void,
        expectedChangedField: String?,
        customAffectedKeys: AffectedKeys? = nil
        ) {
        let fields: Set<String> = expectedChangedField == nil ? [] : [expectedChangedField!]
        checkThatItNotifiesTheObserverOfAChange(message, modifier: modifier, expectedChangedFields: fields, customAffectedKeys: customAffectedKeys)
    }
    
    func checkThatItNotifiesTheObserverOfAChange<T: ZMMessage>(
        _ message: T,
        modifier: (T) -> Void,
        expectedChangedFields: Set<String>,
        customAffectedKeys: AffectedKeys? = nil
        ) {
        
        // given
        withExtendedLifetime(MessageChangeInfo.add(observer: self.messageObserver, for: message, managedObjectContext: self.uiMOC)) { () -> () in
            
            self.uiMOC.saveOrRollback()
            
            // when
            modifier(message)
            self.uiMOC.saveOrRollback()
            self.spinMainQueue(withTimeout: 0.5)
            
            // then
            XCTAssertEqual(messageObserver.notifications.count, expectedChangedFields.isEmpty ? 0 : 1)
            
            // and when
            self.uiMOC.saveOrRollback()
            
            // then
            XCTAssertTrue(messageObserver.notifications.count <= 1, "Should have changed only once")
            
            let messageInfoKeys: Set<String> = [
                #keyPath(MessageChangeInfo.imageChanged),
                #keyPath(MessageChangeInfo.deliveryStateChanged),
                #keyPath(MessageChangeInfo.senderChanged),
                #keyPath(MessageChangeInfo.linkPreviewChanged),
                #keyPath(MessageChangeInfo.isObfuscatedChanged),
                #keyPath(MessageChangeInfo.childMessagesChanged),
                #keyPath(MessageChangeInfo.reactionsChanged),
                #keyPath(MessageChangeInfo.transferStateChanged),
                #keyPath(MessageChangeInfo.confirmationsChanged),
                #keyPath(MessageChangeInfo.genericMessageChanged),
                #keyPath(MessageChangeInfo.linkAttachmentsChanged)
            ]

            guard !expectedChangedFields.isEmpty else { return }
            guard let changes = messageObserver.notifications.first else { return }
            changes.checkForExpectedChangeFields(userInfoKeys: messageInfoKeys,
                                                 expectedChangedFields: expectedChangedFields)
        }
    }

    func testThatItNotifiesObserverWhenTheFileTransferStateChanges() {
        // given
        let message = ZMAssetClientMessage(nonce: UUID.create(), managedObjectContext: self.uiMOC)
        message.transferState = .uploading
        uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(
            message,
            modifier: { $0.transferState = .uploaded },
            expectedChangedField: #keyPath(MessageChangeInfo.transferStateChanged)
        )
    }
    
    
    func testThatItNotifiesObserverWhenTheMediumImageDataChanges() {
        // given
        let message = ZMAssetClientMessage(nonce: UUID.create(), managedObjectContext: self.uiMOC)
        uiMOC.saveOrRollback()

        let imageData = verySmallJPEGData()
        let imageSize = ZMImagePreprocessor.sizeOfPrerotatedImage(with: imageData)
        let properties = ZMIImageProperties(size:imageSize, length:UInt(imageData.count), mimeType:"image/jpeg")
        let keys = ZMImageAssetEncryptionKeys(otrKey: Data.randomEncryptionKey(),
                                              macKey: Data.zmRandomSHA256Key(),
                                              mac: Data.zmRandomSHA256Key())

        let imageMessage = ZMGenericMessage.message(content: ZMImageAsset(mediumProperties: properties,
                                                                          processedProperties: properties,
                                                                          encryptionKeys: keys,
                                                                          format: .preview),
                                                    nonce: UUID.create())

        // when
        self.checkThatItNotifiesTheObserverOfAChange(
            message,
            modifier: { $0.add(imageMessage) },
            expectedChangedField: #keyPath(MessageChangeInfo.imageChanged)
        )
    }

    func testThatItNotifiesObserverWhenTheLinkPreviewStateChanges() {
        // when
        checkThatItNotifiesTheObserverOfAChange(
            ZMClientMessage(nonce: UUID.create(), managedObjectContext: uiMOC),
            modifier: { $0.linkPreviewState = .downloaded },
            expectedChangedField: #keyPath(MessageChangeInfo.linkPreviewChanged)
        )
    }

    func testThatItNotifiesObserverWhenTheLinkPreviewStateChanges_NewGenericMessageData() {
        // given
        let clientMessage = ZMClientMessage(nonce: UUID.create(), managedObjectContext: uiMOC)
        let nonce = UUID.create()
        clientMessage.add(ZMGenericMessage.message(content: ZMText.text(with: name), nonce: nonce).data())
        let preview = ZMLinkPreview.linkPreview(
            withOriginalURL: "www.example.com",
            permanentURL: "www.example.com/permanent",
            offset: 42,
            title: "title",
            summary: "summary",
            imageAsset: nil
        )
        let updateGenericMessage = ZMGenericMessage.message(content: ZMText.text(with: name, linkPreviews: [preview]), nonce: nonce)
        uiMOC.saveOrRollback()
        
        // when
        checkThatItNotifiesTheObserverOfAChange(
            clientMessage,
            modifier: { $0.add(updateGenericMessage.data()) },
            expectedChangedFields: [#keyPath(MessageChangeInfo.linkPreviewChanged), #keyPath(MessageChangeInfo.genericMessageChanged)]
        )
    }
    
    func testThatItDoesNotNotifiyObserversWhenTheSmallImageDataChanges() {
        // given
        let message = ZMImageMessage(nonce: UUID.create(), managedObjectContext: uiMOC)
        uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(
            message,
            modifier: { $0.previewData = verySmallJPEGData() },
            expectedChangedField: nil
        )
    }
    
    func testThatItNotifiesWhenAReactionIsAddedOnMessage() {
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        let message = conversation.append(text: "foo") as! ZMClientMessage
        uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(
            message,
            modifier: { $0.addReaction("LOVE IT, HUH", forUser: ZMUser.selfUser(in: self.uiMOC))},
            expectedChangedField: #keyPath(MessageChangeInfo.reactionsChanged)
        )
    }
    
    func testThatItNotifiesWhenAReactionIsAddedOnMessageFromADifferentUser() {
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        let message = conversation.append(text: "foo") as! ZMClientMessage

        let otherUser = ZMUser.insertNewObject(in:uiMOC)
        otherUser.name = "Hans"
        otherUser.remoteIdentifier = .create()
        uiMOC.saveOrRollback()

        // when
        checkThatItNotifiesTheObserverOfAChange(
            message,
            modifier: { $0.addReaction("👻", forUser: otherUser) },
            expectedChangedField: #keyPath(MessageChangeInfo.reactionsChanged)
        )
    }
    
    func testThatItNotifiesWhenAReactionIsUpdateForAUserOnMessage() {
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        let message = conversation.append(text: "foo") as! ZMClientMessage

        let selfUser = ZMUser.selfUser(in: self.uiMOC)
        message.addReaction("LOVE IT, HUH", forUser: selfUser)
        uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(
            message,
            modifier: {$0.addReaction(nil, forUser: selfUser)},
            expectedChangedField: #keyPath(MessageChangeInfo.reactionsChanged)
        )
    }
    
    func testThatItNotifiesWhenAReactionFromADifferentUserIsAddedOnTopOfSelfReaction() {
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        let message = conversation.append(text: "foo") as! ZMClientMessage

        let otherUser = ZMUser.insertNewObject(in:uiMOC)
        otherUser.name = "Hans"
        otherUser.remoteIdentifier = .create()
        
        let selfUser = ZMUser.selfUser(in: self.uiMOC)
        message.addReaction("👻", forUser: selfUser)
        uiMOC.saveOrRollback()

        // when
        checkThatItNotifiesTheObserverOfAChange(
            message,
            modifier: { $0.addReaction("👻", forUser: otherUser) },
            expectedChangedField: #keyPath(MessageChangeInfo.reactionsChanged)
        )
    }

    func testThatItNotifiesObserversWhenDeliveredChanges(){
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        let message = conversation.append(text: "foo") as! ZMClientMessage
        XCTAssertFalse(message.delivered)
        uiMOC.saveOrRollback()
        
        // when
        checkThatItNotifiesTheObserverOfAChange(
            message,
            modifier: { $0.markAsSent(); XCTAssertTrue($0.delivered) },
            expectedChangedField: #keyPath(MessageChangeInfo.deliveryStateChanged)
        )
    }
    
    func testThatItStopsNotifyingAfterUnregisteringTheToken() {
        
        // given
        let message = ZMClientMessage(nonce: UUID.create(), managedObjectContext: uiMOC)
        self.uiMOC.saveOrRollback()
        
        self.performIgnoringZMLogError{
            _ = MessageChangeInfo.add(observer: self.messageObserver, for: message, managedObjectContext: self.uiMOC)
        }
        // when
        message.serverTimestamp = Date()
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(messageObserver.notifications.count, 0)
    }

    func testThatItNotifiesWhenTheChildMessagesOfASystemMessageChange() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        let message = conversation.appendPerformedCallMessage(with: 42, caller: .selfUser(in: uiMOC))
        let otherMessage = ZMSystemMessage(nonce: UUID.create(), managedObjectContext: uiMOC)

        checkThatItNotifiesTheObserverOfAChange(
            message,
            modifier: { $0.mutableSetValue(forKey: #keyPath(ZMSystemMessage.childMessages)).add(otherMessage) },
            expectedChangedField: #keyPath(MessageChangeInfo.childMessagesChanged)
        )
    }

    func testThatItNotifiesWhenUserReadsTheMessage() {
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        let message = conversation.append(text: "foo") as! ZMClientMessage
        uiMOC.saveOrRollback()
        
        
        // when
        self.checkThatItNotifiesTheObserverOfAChange(
            message,
            modifier: { _ in
                let _ = ZMMessageConfirmation(type: .read, message: message, sender: ZMUser.selfUser(in: uiMOC), serverTimestamp: Date(), managedObjectContext: uiMOC)
            },
            expectedChangedFields: [#keyPath(MessageChangeInfo.confirmationsChanged), #keyPath(MessageChangeInfo.deliveryStateChanged)]
        )
    }
    
    func testThatItNotifiesWhenUserReadsTheMessage_Asset() {
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        let message = conversation.append(imageFromData: verySmallJPEGData())  as! ZMAssetClientMessage
        uiMOC.saveOrRollback()
        
        // when
        self.checkThatItNotifiesTheObserverOfAChange(
            message,
            modifier: { _ in
                let _ = ZMMessageConfirmation(type: .read, message: message, sender: ZMUser.selfUser(in: uiMOC), serverTimestamp: Date(), managedObjectContext: uiMOC)
        },
            expectedChangedFields: [#keyPath(MessageChangeInfo.confirmationsChanged), #keyPath(MessageChangeInfo.deliveryStateChanged)]
        )
    }
    
    func testThatItNotifiesConversationWhenMessageGenericDataIsChanged() {
        
        let clientMessage = ZMClientMessage(nonce: UUID.create(), managedObjectContext: uiMOC)
        let nonce = UUID.create()
        clientMessage.add(ZMGenericMessage.message(content: ZMText.text(with: "foo"), nonce: nonce).data())
        let update = ZMGenericMessage.message(content: ZMText.text(with: "bar"), nonce: nonce)
        uiMOC.saveOrRollback()
        
        // when
        self.checkThatItNotifiesTheObserverOfAChange(
            clientMessage,
            modifier: { $0.add(update.data()) },
            expectedChangedFields: [ #keyPath(MessageChangeInfo.genericMessageChanged), #keyPath(MessageChangeInfo.linkPreviewChanged)]
        )

    }

    func testThatItNotifiesWhenLinkAttachmentIsAdded() {
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        let message = conversation.append(text: "foo") as! ZMClientMessage
        uiMOC.saveOrRollback()

        let attachment = LinkAttachment(type: .youTubeVideo, title: "Pingu Season 1 Episode 1",
                                        permalink: URL(string: "https://www.youtube.com/watch?v=hyTNGkBSjyo")!,
                                        thumbnails: [URL(string: "https://i.ytimg.com/vi/hyTNGkBSjyo/hqdefault.jpg")!],
                                        originalRange: NSRange(location: 20, length: 43))

        // when
        self.checkThatItNotifiesTheObserverOfAChange(
            message,
            modifier: { _ in
                return message.linkAttachments = [attachment]
            },
            expectedChangedFields: [#keyPath(MessageChangeInfo.linkAttachmentsChanged)]
        )
    }

}
