//
//

import Foundation
@testable import WireDataModel

class ZMAssetClientMessageTests_Ephemeral : BaseZMAssetClientMessageTests {
    
    override func setUp() {
        super.setUp()
        deletionTimer?.isTesting = true
        syncMOC.performGroupedBlockAndWait {
            self.obfuscationTimer?.isTesting = true
        }
    }
    
    override func tearDown() {
        syncMOC.performGroupedBlockAndWait {
            self.syncMOC.zm_teardownMessageObfuscationTimer()
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        uiMOC.performGroupedBlockAndWait {
            self.uiMOC.zm_teardownMessageDeletionTimer()
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        super.tearDown()
    }
    
    var obfuscationTimer : ZMMessageDestructionTimer? {
        return syncMOC.zm_messageObfuscationTimer
    }
    
    var deletionTimer : ZMMessageDestructionTimer? {
        return uiMOC.zm_messageDeletionTimer
    }
    
}

// MARK: Sending
extension ZMAssetClientMessageTests_Ephemeral {
    
    func testThatItInsertsAnEphemeralMessageForAssets(){
        // given
        conversation.messageDestructionTimeout = .local(MessageDestructionTimeoutValue(rawValue: 10))
        let fileMetadata = createFileMetadata()
        
        // when
        let message = conversation.append(file: fileMetadata) as! ZMAssetClientMessage
        
        // then
        XCTAssertTrue(message.genericAssetMessage!.hasEphemeral())
        XCTAssertTrue(message.genericAssetMessage!.ephemeral.hasAsset())
        XCTAssertEqual(message.genericAssetMessage!.ephemeral.expireAfterMillis, Int64(10*1000))
    }
    
    func assetWithImage() -> ZMAsset {
        let original = ZMAssetOriginal.original(withSize: 1000, mimeType: "image", name: "foo")
        let remoteData = ZMAssetRemoteData.remoteData(withOTRKey: Data(), sha256: Data(), assetId: "id", assetToken: "token")
        let imageMetaData = ZMAssetImageMetaData.imageMetaData(withWidth: 30, height: 40)
        let imageMetaDataBuilder = imageMetaData.toBuilder()!
        imageMetaDataBuilder.setTag("bar")
        
        let preview = ZMAssetPreview.preview(withSize: 2000, mimeType: "video", remoteData: remoteData, imageMetadata: imageMetaDataBuilder.build())
        let asset  = ZMAsset.asset(withOriginal: original, preview: preview)
        return asset
    }
    
    func thumbnailEvent(for message: ZMAssetClientMessage) -> ZMUpdateEvent {
        let payload : [String : Any] = [
            "id": UUID.create(),
            "conversation": conversation.remoteIdentifier!.transportString(),
            "from": selfUser.remoteIdentifier!.transportString(),
            "time": Date().transportString(),
            "data": [
                "id": "fooooo"
            ],
            "type": "conversation.otr-message-add"
        ]
        return ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: UUID())!
    }
    
    func testThatWhenUpdatingTheThumbnailAssetIDWeReplaceAnEphemeralMessageWithAnEphemeral(){
        // given
        conversation.messageDestructionTimeout = .local(MessageDestructionTimeoutValue(rawValue: 10))
        let fileMetadata = createFileMetadata()
        
        // when
        let message = conversation.append(file: fileMetadata) as! ZMAssetClientMessage
        let remoteMessage = ZMGenericMessage.message(content: assetWithImage(), nonce: message.nonce!)
        
        let event = thumbnailEvent(for: message)
        message.update(with: remoteMessage, updateEvent: event, initialUpdate: true)
    
        // then
        XCTAssertTrue(message.genericAssetMessage!.hasEphemeral())
        XCTAssertTrue(message.genericAssetMessage!.ephemeral.hasAsset())
        XCTAssertEqual(message.genericAssetMessage!.ephemeral.expireAfterMillis, Int64(10*1000))
    
    }
    
    func testThatItStartsTheTimerForMultipartMessagesWhenTheAssetIsUploaded(){
        self.syncMOC.performGroupedBlockAndWait {
            // given
            self.syncConversation.messageDestructionTimeout = .local(MessageDestructionTimeoutValue(rawValue: 10))
            let fileMetadata = self.createFileMetadata()
            let message = self.syncConversation.append(file: fileMetadata) as! ZMAssetClientMessage
            
            // when
            message.update(withPostPayload: [:], updatedKeys: Set([#keyPath(ZMAssetClientMessage.transferState)]))
            
            // then
            XCTAssertEqual(self.obfuscationTimer?.runningTimersCount, 1)
            XCTAssertEqual(self.obfuscationTimer?.isTimerRunning(for: message), true)
        }
    }
    
    func testThatItExtendsTheObfuscationTimer() {
        var oldTimer: ZMTimer?
        var message: ZMAssetClientMessage!
        
        // given
        self.syncMOC.performGroupedBlockAndWait {
            // set timeout
            self.syncConversation.messageDestructionTimeout = .local(MessageDestructionTimeoutValue(rawValue: 10))
            
            // send file
            let fileMetadata = self.createFileMetadata()
            message = self.syncConversation.append(file: fileMetadata) as? ZMAssetClientMessage
            message.update(withPostPayload: [:], updatedKeys: Set([#keyPath(ZMAssetClientMessage.transferState)]))
            
            // check a timer was started
            oldTimer = self.obfuscationTimer?.timer(for: message)
            XCTAssertNotNil(oldTimer)
        }
        
        // when timer extended by 5 seconds
        self.syncMOC.performGroupedBlockAndWait {
            message.extendDestructionTimer(to: Date(timeIntervalSinceNow: 15))
        }
        
        // then a new timer was created
        self.syncMOC.performGroupedBlockAndWait {
            let newTimer = self.obfuscationTimer?.timer(for: message)
            XCTAssertNotEqual(oldTimer, newTimer)
        }
    }
    
    func testThatItDoesNotExtendTheObfuscationTimerWhenNewDateIsEarlier() {
        var oldTimer: ZMTimer?
        var message: ZMAssetClientMessage!
        
        // given
        self.syncMOC.performGroupedBlockAndWait {
            // set timeout
            self.syncConversation.messageDestructionTimeout = .local(MessageDestructionTimeoutValue(rawValue: 10))
            
            // send file
            let fileMetadata = self.createFileMetadata()
            message = self.syncConversation.append(file: fileMetadata) as? ZMAssetClientMessage
            message.update(withPostPayload: [:], updatedKeys: Set([#keyPath(ZMAssetClientMessage.transferState)]))
            
            // check a timer was started
            oldTimer = self.obfuscationTimer?.timer(for: message)
            XCTAssertNotNil(oldTimer)
        }
        
        // when timer "extended" 5 seconds earlier
        self.syncMOC.performGroupedBlockAndWait {
            message.extendDestructionTimer(to: Date(timeIntervalSinceNow: 5))
        }
        
        // then no new timer created
        self.syncMOC.performGroupedBlockAndWait {
            let newTimer = self.obfuscationTimer?.timer(for: message)
            XCTAssertEqual(oldTimer, newTimer)
        }
    }
}


// MARK: Receiving

extension ZMAssetClientMessageTests_Ephemeral {
    
    
    func testThatItStartsATimerForImageAssetMessagesIfTheMessageIsAMessageOfTheOtherUser(){
        // given
        conversation.messageDestructionTimeout = .local(MessageDestructionTimeoutValue(rawValue: 10))
        conversation.lastReadServerTimeStamp = Date()
        let sender = ZMUser.insertNewObject(in: uiMOC)
        sender.remoteIdentifier = UUID.create()
        
        let fileMetadata = self.createFileMetadata()
        let message = conversation.append(file: fileMetadata) as! ZMAssetClientMessage
        message.sender = sender
        message.add(ZMGenericMessage.message(content: ZMAsset.asset(withUploadedOTRKey: Data(), sha256: Data()), nonce: message.nonce!))
        XCTAssertTrue(message.genericAssetMessage!.assetData!.hasUploaded())
        
        // when
        XCTAssertTrue(message.startSelfDestructionIfNeeded())
        
        // then
        XCTAssertEqual(self.deletionTimer?.runningTimersCount, 1)
        XCTAssertEqual(self.deletionTimer?.isTimerRunning(for: message), true)
    }
    
    func testThatItStartsATimerIfTheMessageIsAMessageOfTheOtherUser(){
        // given
        conversation.messageDestructionTimeout = .local(MessageDestructionTimeoutValue(rawValue: 10))
        conversation.lastReadServerTimeStamp = Date()
        let sender = ZMUser.insertNewObject(in: uiMOC)
        sender.remoteIdentifier = UUID.create()
        
        let nonce = UUID()
        let message = ZMAssetClientMessage(nonce: nonce, managedObjectContext: uiMOC)
        message.sender = sender
        message.visibleInConversation = conversation
        
        let imageData = verySmallJPEGData()
        let assetMessage = ZMGenericMessage.message(content: ZMAsset.asset(originalWithImageSize: .zero, mimeType: "", size: UInt64(imageData.count)), nonce: nonce, expiresAfter: 10)
        message.add(assetMessage)
        
        
        let uploaded = ZMGenericMessage.message(content: ZMAsset.asset(withUploadedOTRKey: .randomEncryptionKey(), sha256: .zmRandomSHA256Key()), nonce: message.nonce!, expiresAfter: conversation.messageDestructionTimeoutValue)
        message.add(uploaded)
        
        // when
        XCTAssertTrue(message.startSelfDestructionIfNeeded())
        
        // then
        XCTAssertEqual(self.deletionTimer?.runningTimersCount, 1)
        XCTAssertEqual(self.deletionTimer?.isTimerRunning(for: message), true)
    }
    
    func appendPreviewImageMessage() -> ZMAssetClientMessage {
        let imageData = verySmallJPEGData()
        let message = ZMAssetClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        conversation.append(message)
        
        let imageSize = ZMImagePreprocessor.sizeOfPrerotatedImage(with: imageData)
        let properties = ZMIImageProperties(size:imageSize, length:UInt(imageData.count), mimeType:"image/jpeg")
        let keys = ZMImageAssetEncryptionKeys(otrKey: Data.randomEncryptionKey(),
                                              macKey: Data.zmRandomSHA256Key(),
                                              mac: Data.zmRandomSHA256Key())
        
        
        let imageMessage = ZMGenericMessage.message(content: ZMImageAsset(mediumProperties: properties, processedProperties: properties, encryptionKeys: keys, format: .preview))
        message.add(imageMessage)
        return message
    }
    
    func testThatItDoesNotStartsATimerIfTheMessageIsAMessageOfTheOtherUser_NoMediumImage(){
        // given
        conversation.messageDestructionTimeout = .local(MessageDestructionTimeoutValue(rawValue: 10))
        conversation.lastReadServerTimeStamp = Date()
        let sender = ZMUser.insertNewObject(in: uiMOC)
        sender.remoteIdentifier = UUID.create()
        
        let message = appendPreviewImageMessage()
        message.sender = sender

        // when
        XCTAssertFalse(message.startSelfDestructionIfNeeded())
        
        // then
        XCTAssertEqual(self.deletionTimer?.runningTimersCount, 0)
        XCTAssertEqual(self.deletionTimer?.isTimerRunning(for: message), false)
    }
    
    func testThatItDoesNotStartATimerIfTheMessageIsAMessageOfTheOtherUser_NotUploadedYet(){
        // given
        conversation.messageDestructionTimeout = .local(MessageDestructionTimeoutValue(rawValue: 10))
        conversation.lastReadServerTimeStamp = Date()
        let sender = ZMUser.insertNewObject(in: uiMOC)
        sender.remoteIdentifier = UUID.create()
        
        let fileMetadata = self.createFileMetadata()
        let message = conversation.append(file: fileMetadata) as! ZMAssetClientMessage
        message.sender = sender
        XCTAssertFalse(message.genericAssetMessage!.assetData!.hasUploaded())
        
        // when
        XCTAssertFalse(message.startSelfDestructionIfNeeded())
        
        // then
        XCTAssertEqual(self.deletionTimer?.runningTimersCount, 0)
        XCTAssertEqual(self.deletionTimer?.isTimerRunning(for: message), false)
    }
    
    func testThatItStartsATimerIfTheMessageIsAMessageOfTheOtherUser_UploadCancelled(){
        // given
        conversation.messageDestructionTimeout = .local(MessageDestructionTimeoutValue(rawValue: 10))
        conversation.lastReadServerTimeStamp = Date()
        let sender = ZMUser.insertNewObject(in: uiMOC)
        sender.remoteIdentifier = UUID.create()
        
        let fileMetadata = self.createFileMetadata()
        let message = conversation.append(file: fileMetadata) as! ZMAssetClientMessage
        message.sender = sender
        message.add(ZMGenericMessage.message(content: ZMAsset.asset(withNotUploaded: .CANCELLED), nonce: message.nonce!))
        XCTAssertTrue(message.genericAssetMessage!.assetData!.hasNotUploaded())
        
        // when
        XCTAssertTrue(message.startSelfDestructionIfNeeded())
        
        // then
        XCTAssertEqual(self.deletionTimer?.runningTimersCount, 1)
        XCTAssertEqual(self.deletionTimer?.isTimerRunning(for: message), true)
    }
    
    func testThatItDoesNotStartATimerForAMessageOfTheSelfuser(){
        // given
        let timeout : TimeInterval = 0.1
        conversation.messageDestructionTimeout =  .local(MessageDestructionTimeoutValue(rawValue: timeout))
        let fileMetadata = self.createFileMetadata()
        let message = conversation.append(file: fileMetadata) as! ZMAssetClientMessage
        message.add(ZMGenericMessage.message(content: ZMAsset.asset(withUploadedOTRKey: Data(), sha256: Data()), nonce: message.nonce!))
        XCTAssertTrue(message.genericAssetMessage!.assetData!.hasUploaded())
        
        // when
        XCTAssertFalse(message.startDestructionIfNeeded())
        
        // then
        XCTAssertEqual(self.deletionTimer?.runningTimersCount, 0)
    }
    
    func testThatItCreatesADeleteForAllMessageWhenTheTimerFires(){
        // given
        let timeout : TimeInterval = 0.1
        conversation.messageDestructionTimeout = .local(MessageDestructionTimeoutValue(rawValue: timeout))
        
        let fileMetadata = self.createFileMetadata()
        let message = conversation.append(file: fileMetadata) as! ZMAssetClientMessage
        conversation.conversationType = .oneOnOne
        message.sender = ZMUser.insertNewObject(in: uiMOC)
        message.sender?.remoteIdentifier = UUID.create()
        message.add(ZMGenericMessage.message(content: ZMAsset.asset(withUploadedOTRKey: Data(), sha256: Data()), nonce: message.nonce!))
        XCTAssertTrue(message.genericAssetMessage!.assetData!.hasUploaded())
        
        // when
        XCTAssertTrue(message.startDestructionIfNeeded())
        XCTAssertEqual(self.deletionTimer?.runningTimersCount, 1)
        
        spinMainQueue(withTimeout: 0.5)
        
        // then
        guard let deleteMessage = conversation.hiddenMessages.first(where: { $0 is ZMClientMessage }) as? ZMClientMessage else { return XCTFail()}
        
        guard let genericMessage = deleteMessage.genericMessage, genericMessage.hasDeleted()
            else {return XCTFail()}
        
        XCTAssertNotEqual(deleteMessage, message)
        XCTAssertNotNil(message.sender)
        XCTAssertNil(message.genericAssetMessage)
        XCTAssertEqual(message.dataSet.count, 0)
        XCTAssertNil(message.destructionDate)
    }
    
    func testThatItExtendsTheDeletionTimer() {
        var oldTimer: ZMTimer?
        var message: ZMAssetClientMessage!
        
        // given
        self.conversation.messageDestructionTimeout = .local(MessageDestructionTimeoutValue(rawValue: 10))
        
        // send file
        let fileMetadata = self.createFileMetadata()
        message = self.conversation.append(file: fileMetadata) as? ZMAssetClientMessage
        message.sender = ZMUser.insertNewObject(in: self.uiMOC)
        message.sender?.remoteIdentifier = UUID.create()
        
        message.add(ZMGenericMessage.message(content: ZMAsset.asset(withUploadedOTRKey: Data(), sha256: Data()), nonce: message.nonce!))
        XCTAssertTrue(message.genericAssetMessage!.assetData!.hasUploaded())
        
        // check a timer was started
        XCTAssertTrue(message.startDestructionIfNeeded())
        oldTimer = self.deletionTimer?.timer(for: message)
        XCTAssertNotNil(oldTimer)
        
        // when timer extended by 5 seconds
        message.extendDestructionTimer(to: Date(timeIntervalSinceNow: 15))
        
        // force a wait so timer map is updated
        _ = wait(withTimeout: 0.5, verificationBlock: { return false })
        
        // then a new timer was created
        let newTimer = self.deletionTimer?.timer(for: message)
        XCTAssertNotEqual(oldTimer, newTimer)
    }
    
    func testThatItDoesNotExtendTheDeletionTimerWhenNewDateIsEarlier() {
        var oldTimer: ZMTimer?
        var message: ZMAssetClientMessage!
        
        // given
        self.conversation.messageDestructionTimeout = .local(MessageDestructionTimeoutValue(rawValue: 10))
        
        // send file
        let fileMetadata = self.createFileMetadata()
        message = self.conversation.append(file: fileMetadata) as? ZMAssetClientMessage
        message.sender = ZMUser.insertNewObject(in: self.uiMOC)
        message.sender?.remoteIdentifier = UUID.create()
        
        message.add(ZMGenericMessage.message(content: ZMAsset.asset(withUploadedOTRKey: Data(), sha256: Data()), nonce: message.nonce!))
        XCTAssertTrue(message.genericAssetMessage!.assetData!.hasUploaded())
        
        // check a timer was started
        XCTAssertTrue(message.startDestructionIfNeeded())
        oldTimer = self.deletionTimer?.timer(for: message)
        XCTAssertNotNil(oldTimer)
        
        // when timer "extended" by 5 seconds earlier
        message.extendDestructionTimer(to: Date(timeIntervalSinceNow: 5))
        
        // force a wait so timer map is updated
        _ = wait(withTimeout: 0.5, verificationBlock: { return false })
        
        // then a new timer was created
        let newTimer = self.deletionTimer?.timer(for: message)
        XCTAssertEqual(oldTimer, newTimer)
    }
}



