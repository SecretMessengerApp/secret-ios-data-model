//
// 


import Foundation
@testable import WireDataModel

enum MimeType : String {
    case text = "text/plain"
}

class BaseZMAssetClientMessageTests : BaseZMClientMessageTests {
    
    var message: ZMAssetClientMessage!
    var currentTestURL : URL?
        
    override func tearDown() {
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 2))
        if let url = currentTestURL {
            removeTestFile(at: url)
        }
        currentTestURL = nil
        message = nil
        super.tearDown()
    }
    
    override func createFileMetadata(filename: String? = nil) -> ZMFileMetadata {
        let metadata = super.createFileMetadata()
        currentTestURL = metadata.fileURL
        return metadata
    }
    
    func appendFileMessage(to conversation: ZMConversation, fileMetaData: ZMFileMetadata? = nil) -> ZMAssetClientMessage? {
        let nonce = UUID.create()
        let data = fileMetaData ?? createFileMetadata()
        
        return conversation.append(file: data, nonce: nonce) as? ZMAssetClientMessage
    }
    
    func appendV2ImageMessage(to conversation: ZMConversation) {
        let imageData = verySmallJPEGData()
        let messageNonce = UUID.create()
        
        message = conversation.append(imageFromData: imageData, nonce: messageNonce) as? ZMAssetClientMessage
        
        let imageSize = ZMImagePreprocessor.sizeOfPrerotatedImage(with: imageData)
        let properties = ZMIImageProperties(size:imageSize, length:UInt(imageData.count), mimeType:"image/jpeg")!
        
        let keys = ZMImageAssetEncryptionKeys(otrKey: Data.randomEncryptionKey(), macKey: Data.zmRandomSHA256Key(), mac: Data.zmRandomSHA256Key())
        
        let mediumMessage = ZMImageAsset(mediumProperties: properties, processedProperties: properties, encryptionKeys: keys, format: .medium)
        let previewMessage = ZMImageAsset(mediumProperties: properties, processedProperties: properties, encryptionKeys: keys, format: .preview)
        
        message.add(ZMGenericMessage.message(content: mediumMessage, nonce: messageNonce))
        message.add(ZMGenericMessage.message(content: previewMessage, nonce: messageNonce))
    }
    
    func appendImageMessage(to conversation: ZMConversation, imageData: Data? = nil) -> ZMAssetClientMessage {
        let data = imageData ?? verySmallJPEGData()
        let nonce = UUID.create()
        let message = conversation.append(imageFromData: data, nonce: nonce) as! ZMAssetClientMessage

        let uploaded = ZMAsset.asset(withUploadedOTRKey: .randomEncryptionKey(), sha256: .zmRandomSHA256Key())
        message.add(ZMGenericMessage.message(content: uploaded, nonce: nonce))
        
        return message
    }
    
}

class ZMAssetClientMessageTests : BaseZMAssetClientMessageTests {
    
    func testThatItDeletesCopiesOfDownloadedFilesIntoTemporaryFolder() {
        // given
        let sut = appendFileMessage(to: conversation)!
        self.uiMOC.zm_fileAssetCache.storeAssetData(sut, format: .medium, encrypted: false, data: Data.secureRandomData(ofLength: 100))
        guard let tempFolder = sut.temporaryDirectoryURL else { XCTFail(); return }
        
        XCTAssertNotNil(sut.fileURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempFolder.path))
        
        //when
        sut.deleteContent()
        
        //then
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempFolder.path))
    }
    
}

// MARK: - ZMAsset / ZMFileMessageData

extension ZMAssetClientMessageTests {
    
    func testThatItCreatesFileAssetMessageInTheRightStateToBeUploaded()
    {
        // given
        let sut = appendFileMessage(to: conversation)!
        
        // then
        XCTAssertNotNil(sut)
        XCTAssertFalse(sut.delivered)
        XCTAssertEqual(sut.transferState, .uploading)
        XCTAssertEqual(sut.filename, currentTestURL!.lastPathComponent)
        XCTAssertNotNil(sut.fileMessageData)
        XCTAssertEqual(sut.version, 3)
    }
    
    func testThatTransferStateIsUpdated_WhenExpired() {
        // given
        let sut = appendFileMessage(to: conversation)!
        XCTAssertEqual(sut.transferState, .uploading)
        
        // when
        sut.expire()
        
        // then
        XCTAssertEqual(sut.transferState, .uploadingFailed)
    }
        
    func testThatTransferStateIsNotUpdated_WhenExpired_IfAlreadyUploaded() {
        // given
        let sut = appendFileMessage(to: conversation)!
        sut.transferState = .uploaded
        
        // when
        sut.expire()
        
        // then
        XCTAssertEqual(sut.transferState, .uploaded)
    }
    
    func testThatItHasDownloadedFileWhenTheFileIsOnDisk()
    {
        // given
        let sut = appendFileMessage(to: conversation)!
        
        // then
        XCTAssertTrue(sut.hasDownloadedFile)
    }
    
    func testThatItHasNoDownloadedFileWhenTheFileIsNotOnDisk()
    {
        // given
        let sut = appendFileMessage(to: conversation)!
        self.uiMOC.zm_fileAssetCache.deleteAssetData(sut, encrypted: false)
        
        // then
        XCTAssertFalse(sut.hasDownloadedFile)
    }
    
    func testThatItHasDownloadedImageWhenTheProcessedThumbnailIsOnDisk()
    {
        // given
        let sut = appendFileMessage(to: conversation)!
        
        self.uiMOC.zm_fileAssetCache.storeAssetData(sut, format: .medium, encrypted: false, data: Data.secureRandomData(ofLength: 100))
        defer { self.uiMOC.zm_fileAssetCache.deleteAssetData(sut, format: .medium, encrypted: false) }
        
        // then
        XCTAssertTrue(sut.hasDownloadedPreview)
    }
    
    func testThatItHasDownloadedImageWhenTheOriginalThumbnailIsOnDisk()
    {
        // given
        let sut = appendFileMessage(to: conversation)!
        
        self.uiMOC.zm_fileAssetCache.storeAssetData(sut, format: .original, encrypted: false, data: Data.secureRandomData(ofLength: 100))
        defer { self.uiMOC.zm_fileAssetCache.deleteAssetData(sut, format: .medium, encrypted: false) }
        
        // then
        XCTAssertTrue(sut.hasDownloadedPreview)
    }
    
    func testThatItSetsTheGenericAssetMessageWhenCreatingMessage()
    {
        // given
        let nonce = UUID.create()
        let mimeType = "text/plain"
        let filename = "document.txt"
        let url = testURLWithFilename(filename)
        let data = createTestFile(at: url)
        defer { removeTestFile(at: url) }
        let size = UInt64(data.count)
        let fileMetadata = ZMFileMetadata(fileURL: url)
        
        // when
        let sut = appendFileMessage(to: conversation, fileMetaData: fileMetadata)!
        
        XCTAssertNotNil(sut)
        
        // then
        let assetMessage = sut.genericAssetMessage
        XCTAssertNotNil(assetMessage)
        XCTAssertEqual(assetMessage?.messageId, sut.nonce?.transportString())
        XCTAssertTrue(assetMessage!.hasAsset())
        XCTAssertNotNil(assetMessage?.asset)
        XCTAssertTrue(assetMessage!.asset.hasOriginal())
        
        let original = assetMessage?.asset.original
        XCTAssertNotNil(original)
        XCTAssertEqual(original?.name, filename)
        XCTAssertEqual(original?.mimeType, mimeType)
        XCTAssertEqual(original?.size, size)
    }
    
    func testThatItMergesMultipleGenericAssetMessagesForFileMessages()
    {
        let nonce = UUID.create()
        let mimeType = "text/plain"
        let filename = "document.txt"
        let url = testURLWithFilename(filename)
        let data = createTestFile(at: url)
        defer { removeTestFile(at: url) }
        let fileMetadata = ZMFileMetadata(fileURL: url)
        
        // when
        let sut = appendFileMessage(to: conversation, fileMetaData: fileMetadata)!

        XCTAssertNotNil(sut)
        
        let otrKey = Data.randomEncryptionKey()
        let encryptedData = data.zmEncryptPrefixingPlainTextIV(key: otrKey)
        let sha256 = encryptedData.zmSHA256Digest()
        let builder = ZMAssetImageMetaData.builder()!
        builder.setWidth(10)
        builder.setHeight(10)
        let preview = ZMAssetPreview.preview(
            withSize: UInt64(data.count),
            mimeType: mimeType,
            remoteData: ZMAssetRemoteData.remoteData(withOTRKey: otrKey, sha256: sha256),
            imageMetadata: builder.build()!)
        let previewAsset = ZMAsset.asset(preview: preview)
        let previewMessage = ZMGenericMessage.message(content: previewAsset, nonce: nonce)

        
        // when
        sut.add(previewMessage)
        
        // then
        XCTAssertEqual(sut.genericAssetMessage?.messageId, nonce.transportString())
        
        guard let asset = sut.genericAssetMessage?.asset else { return XCTFail() }
        XCTAssertNotNil(asset)
        XCTAssertTrue(asset.hasOriginal())
        XCTAssertTrue(asset.hasPreview())
        XCTAssertEqual(asset.original.name, filename)
        XCTAssertEqual(sut.fileMessageData?.filename, filename)
        XCTAssertEqual(asset.original.mimeType, mimeType)
        XCTAssertEqual(asset.original.size, UInt64(data.count))
        XCTAssertEqual(asset.preview, preview)
    }
    
    func testThatItUpdatesTheMetaDataWhenOriginalAssetMessageGetMerged()
    {
        // given
        let nonce = UUID.create()
        let sut = ZMAssetClientMessage(nonce: UUID.create(), managedObjectContext: uiMOC)
        sut.sender = selfUser
        let mimeType = "text/plain"
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertNotNil(sut)
        
        // when
        let originalMessage = ZMGenericMessage.message(content: ZMAsset.asset(withOriginal: .original(withSize: 256, mimeType: mimeType, name: name), preview: nil), nonce: nonce)
        sut.update(with: originalMessage, updateEvent: ZMUpdateEvent(), initialUpdate: true)
        
        // then
        XCTAssertEqual(sut.fileMessageData?.size, 256)
        XCTAssertEqual(sut.fileMessageData?.mimeType, mimeType)
        XCTAssertEqual(sut.fileMessageData?.filename, name)
        XCTAssertEqual(sut.fileMessageData?.transferState, .uploading)
    }
    
    func testThatItUpdatesTheTransferStateWhenTheUploadedMessageIsMerged()
    {
        // given
        let nonce = UUID.create()
        let sut = ZMAssetClientMessage(nonce: nonce, managedObjectContext: uiMOC)
        sut.sender = selfUser
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertNotNil(sut)
        
        // when
        let originalMessage = ZMGenericMessage.message(content: ZMAsset.asset(withUploadedOTRKey: .zmRandomSHA256Key(), sha256: .zmRandomSHA256Key()), nonce: nonce)
        let uploadedMessage = originalMessage.updatedUploaded(withAssetId: "id", token: "token")!
        sut.update(with: uploadedMessage, updateEvent: ZMUpdateEvent(), initialUpdate: true)
        
        // then
        XCTAssertEqual(sut.fileMessageData?.transferState, .uploaded)
    }
    
    func testThatItDoesntUpdateTheTransferStateWhenTheUploadedMessageIsMergedButDoesntContainAssetId()
    {
        // given
        let nonce = UUID.create()
        let sut = ZMAssetClientMessage(nonce: nonce, managedObjectContext: uiMOC)
        sut.sender = selfUser
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertNotNil(sut)
        
        // when
        let originalMessage = ZMGenericMessage.message(content: ZMAsset.asset(withUploadedOTRKey: .zmRandomSHA256Key(), sha256: .zmRandomSHA256Key()), nonce: nonce)
        sut.update(with: originalMessage, updateEvent: ZMUpdateEvent(), initialUpdate: true)
        
        // then
        XCTAssertEqual(sut.fileMessageData?.transferState, .uploading)
    }
    
    func testThatItDeletesTheMessageWhenTheNotUploadedCanceledMessageIsMerged()
    {
        // given
        let nonce = UUID.create()
        let sut = ZMAssetClientMessage(nonce: nonce, managedObjectContext: uiMOC)
        sut.sender = selfUser
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertNotNil(sut)
        
        // when
        let originalMessage = ZMGenericMessage.message(content: ZMAsset.asset(withNotUploaded: .CANCELLED), nonce: nonce)
        sut.update(with: originalMessage, updateEvent: ZMUpdateEvent(), initialUpdate: true)
        
        // then
        XCTAssertTrue(sut.isZombieObject)
    }
    
    /// This is testing a race condition on the receiver side if the sender cancels but not fast enough, and he BE just got the entire payload
    func testThatItUpdatesTheTransferStateWhenTheCanceledMessageIsMergedAfterUploadingSuccessfully()
    {
        // given
        let nonce = UUID.create()
        let sut = ZMAssetClientMessage(nonce: nonce, managedObjectContext: uiMOC)
        sut.sender = selfUser
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertNotNil(sut)
        
        // when
        let originalMessage = ZMGenericMessage.message(content: ZMAsset.asset(withUploadedOTRKey: .zmRandomSHA256Key(), sha256: .zmRandomSHA256Key()), nonce: nonce)
        let uploadedMessage = originalMessage.updatedUploaded(withAssetId: "id", token: "token")!
        sut.update(with: uploadedMessage, updateEvent: ZMUpdateEvent(), initialUpdate: true)
        let canceledMessage = ZMGenericMessage.message(content: ZMAsset.asset(withNotUploaded: .CANCELLED), nonce: nonce)
        sut.update(with: canceledMessage, updateEvent: ZMUpdateEvent(), initialUpdate: true)
        
        // then
        XCTAssertEqual(sut.fileMessageData?.transferState, .uploaded)
    }
    
    func testThatItUpdatesTheTransferStateWhenTheNotUploadedFailedMessageIsMerged()
    {
        // given
        let nonce = UUID.create()
        let sut = ZMAssetClientMessage(nonce: nonce, managedObjectContext: uiMOC)
        sut.sender = selfUser
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertNotNil(sut)
        
        // when
        let originalMessage = ZMGenericMessage.message(content: ZMAsset.asset(withNotUploaded: .FAILED), nonce: nonce)
        sut.update(with: originalMessage, updateEvent: ZMUpdateEvent(), initialUpdate: true)
        
        // then
        XCTAssertEqual(sut.fileMessageData?.transferState, .uploadingFailed)
    }
    
    func testThatItReturnsAValidFileMessageData() {
        self.syncMOC.performAndWait {
            // given
            let sut = appendFileMessage(to: syncConversation)!
            
            // then
            XCTAssertNotNil(sut)
            XCTAssertNotNil(sut.fileMessageData)
        }
    }
    
    func testThatItReturnsTheEncryptedUploadedDataWhenItHasAUploadedGenericMessageInTheDataSet() {
        self.syncMOC.performAndWait { 
            // given
            let sut = appendFileMessage(to: syncConversation)!
            
            // when
            let otrKey = Data.randomEncryptionKey()
            let sha256 = Data.zmRandomSHA256Key()
            sut.add(ZMGenericMessage.message(content: ZMAsset.asset(withUploadedOTRKey: otrKey, sha256: sha256), nonce: sut.nonce!))
            
            // then
            XCTAssertNotNil(sut)
            guard let asset = sut.genericAssetMessage?.asset else { return XCTFail() }
            XCTAssertTrue(asset.hasUploaded())
            let uploaded = asset.uploaded!
            XCTAssertEqual(uploaded.otrKey, otrKey)
            XCTAssertEqual(uploaded.sha256, sha256)
        }
        
    }
    
    func testThatItCancelsUpload() {
        self.syncMOC.performAndWait {
            
            // given
            let sut = appendFileMessage(to: syncConversation)!
            
            XCTAssertNotNil(sut.fileMessageData)
            XCTAssertTrue(self.syncMOC.saveOrRollback())
            XCTAssertEqual(sut.transferState, .uploading)
            
            // when
            sut.fileMessageData?.cancelTransfer()
            
            // then
            XCTAssertEqual(sut.transferState, .uploadingCancelled)
            XCTAssertEqual(sut.progress, 0.0)
        }
    }
    
    func testThatItCanCancelsUploadMultipleTimes() {
        // given
        self.syncMOC.performAndWait {
            let sut = appendFileMessage(to: syncConversation)!
            
            XCTAssertNotNil(sut.fileMessageData)
            XCTAssertTrue(self.syncMOC.saveOrRollback())
            XCTAssertEqual(sut.transferState, .uploading)
            
            // when / then
            sut.fileMessageData?.cancelTransfer()
            XCTAssertEqual(sut.transferState, .uploadingCancelled)
            
            sut.resend()
            XCTAssertEqual(sut.transferState, .uploading)
            XCTAssertEqual(sut.progress, 0.0);
            
            sut.fileMessageData?.cancelTransfer()
            XCTAssertEqual(sut.transferState, .uploadingCancelled)
            
            sut.resend()
            XCTAssertEqual(sut.transferState, .uploading)
            XCTAssertEqual(sut.progress, 0.0)
        }
        
    }

    func testThatItPostsANotificationWhenTheDownloadOfTheMessageIsCancelled() {
        self.syncMOC.performAndWait {

            // given
            let sut = ZMAssetClientMessage(nonce: .create(), managedObjectContext: syncMOC)
            sut.sender = ZMUser.selfUser(in: syncMOC)
            sut.visibleInConversation = syncConversation
            let original = ZMGenericMessage.message(content: ZMAsset.asset(originalWithImageSize: CGSize(width: 10, height: 10), mimeType: "text/plain", size: 256), nonce: sut.nonce!)
            sut.add(original)
            sut.transferState = .uploaded
            XCTAssertTrue(self.syncMOC.saveOrRollback())

            let expectation = self.expectation(description: "Notification fired")
            let token = NotificationInContext.addObserver(
                name: ZMAssetClientMessage.didCancelFileDownloadNotificationName,
                context: self.uiMOC.notificationContext,
                object: sut.objectID) { note in
                    expectation.fulfill()
            }

            // when
            sut.fileMessageData?.cancelTransfer()

            // then
            withExtendedLifetime(token) { () -> () in
                XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
            }
        }
    }
    
    // MARK: Resending
    
    func testThatDeliveredIsReset_WhenResending() {
        // given
        let sut = appendFileMessage(to: conversation)!
        sut.delivered = true
        
        // when
        sut.resend()
        
        // then
        XCTAssertFalse(sut.delivered)
    }
    
    func testThatProgressIsReset_WhenResending() {
        // given
        let sut = appendFileMessage(to: conversation)!
        sut.progress = 56
        
        // when
        sut.resend()
        
        // then
        XCTAssertEqual(sut.progress, 0)
    }
    
    func testThatTransferStateIsUpdated_WhenResending() {
        // given
        let sut = appendFileMessage(to: conversation)!
        sut.transferState = .uploadingFailed
        
        // when
        sut.resend()
        
        // then
        XCTAssertEqual(sut.transferState, .uploading)
    }
    
    func testThatTransferStateIsNotUpdated_WhenResending_IfAlreadyUploaded() {
        // given
        let sut = appendFileMessage(to: conversation)!
        sut.transferState = .uploaded
        
        // when
        sut.resend()
        
        // then
        XCTAssertEqual(sut.transferState, .uploaded)
    }
    
    func testThatItReturnsNilAssetIdOnANewlyCreatedMessage() {
        self.syncMOC.performAndWait {
            
            // given
            let sut = appendFileMessage(to: syncConversation)!
            
            // then
            XCTAssertNil(sut.fileMessageData?.thumbnailAssetID)
        }
    }
    
    // MARK: Updating AssetId
    
    func testThatItReturnsAssetIdWhenSettingItDirectly() {
        self.syncMOC.performAndWait {
            
            // given
            let previewSize : UInt64 = 46
            let previewMimeType = "image/jpg"
            let remoteData = ZMAssetRemoteData.remoteData(withOTRKey: Data.zmRandomSHA256Key(), sha256: Data.zmRandomSHA256Key())
            let imageMetadata = ZMAssetImageMetaData.imageMetaData(withWidth: 4235, height: 324)
            
            let uuid = "asset-id"
            let sut = appendFileMessage(to: syncConversation)!
            
            let asset = ZMAsset.asset(withOriginal: nil, preview: ZMAssetPreview.preview(withSize: previewSize, mimeType: previewMimeType, remoteData: remoteData, imageMetadata: imageMetadata))
            sut.add(ZMGenericMessage.message(content: asset, nonce: sut.nonce!))
            
            XCTAssertNil(sut.fileMessageData?.thumbnailAssetID)
            
            // when
            sut.fileMessageData!.thumbnailAssetID = uuid
            
            // then
            XCTAssertEqual(sut.fileMessageData?.thumbnailAssetID, uuid)
            // testing that other properties are kept
            XCTAssertEqual(sut.genericAssetMessage?.asset.preview.remote.otrKey, remoteData.otrKey)
            XCTAssertEqual(sut.genericAssetMessage?.asset.preview.remote.sha256, remoteData.sha256)
            XCTAssertEqual(sut.genericAssetMessage?.asset.preview.image.width, imageMetadata.width)
            XCTAssertEqual(sut.genericAssetMessage?.asset.original.name, sut.filename)
        }
    }
    
    func testThatItDoesNotSetAssetIdWhenUpdatingFromAnUploadedMessage() {
        self.syncMOC.performAndWait {
            
            // given
            let previewSize : UInt64 = 46
            let previewMimeType = "image/jpg"
            let remoteData = ZMAssetRemoteData.remoteData(withOTRKey: Data.zmRandomSHA256Key(), sha256: Data.zmRandomSHA256Key())
            let imageMetadata = ZMAssetImageMetaData.imageMetaData(withWidth: 4235, height: 324)
            let sut = appendFileMessage(to: syncConversation)!
            
            let assetWithUploaded = ZMAsset.asset(withUploadedOTRKey: Data.zmRandomSHA256Key(), sha256: Data.zmRandomSHA256Key())
            let assetWithPreview = ZMAsset.asset(withOriginal: nil, preview: ZMAssetPreview.preview(withSize: previewSize, mimeType: previewMimeType, remoteData: remoteData, imageMetadata: imageMetadata))
            let builder = ZMAssetBuilder()
            builder.merge(from: assetWithUploaded)
            builder.mergePreview(assetWithPreview.preview)
            let asset = builder.build()!
            
            let genericMessage = ZMGenericMessage.message(content: asset, nonce: sut.nonce!)
            let payload : [String : AnyObject] = [
                "type" : "conversation.otr-asset-add" as AnyObject,
                "data" : [
                    "id" : UUID.create().uuidString
                ] as AnyObject
            ]
            let updateEvent = ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: UUID.create())!
            XCTAssertNil(sut.fileMessageData?.thumbnailAssetID)
            
            
            // when
            sut.update(with: genericMessage, updateEvent: updateEvent, initialUpdate: true)
            
            // then
            XCTAssertNil(sut.fileMessageData?.thumbnailAssetID)
            // testing that other properties are kept
            XCTAssertEqual(sut.genericAssetMessage?.asset.preview.remote.otrKey, remoteData.otrKey)
            XCTAssertEqual(sut.genericAssetMessage?.asset.preview.remote.sha256, remoteData.sha256)
            XCTAssertEqual(sut.genericAssetMessage?.asset.preview.image.width, imageMetadata.width)
            XCTAssertEqual(sut.genericAssetMessage?.asset.original.name, sut.filename)
        }
    }
    
    func testThatItClearsGenericAssetMessageCacheWhenFaulting() {
        // given
        let previewSize : UInt64 = 46
        let previewMimeType = "image/jpg"
        let remoteData = ZMAssetRemoteData.remoteData(withOTRKey: Data.zmRandomSHA256Key(), sha256: Data.zmRandomSHA256Key())
        let imageMetadata = ZMAssetImageMetaData.imageMetaData(withWidth: 4235, height: 324)
        
        let uuid = UUID.create()
        let sut = appendFileMessage(to: conversation)!
        
        XCTAssertFalse(sut.genericAssetMessage!.asset.hasPreview())
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // when
        uiMOC.refresh(sut, mergeChanges: false) // Turn object into fault
        
        self.syncMOC.performAndWait {
            let sutInSyncContext = self.syncMOC.object(with: sut.objectID) as! ZMAssetClientMessage
            let asset = ZMAsset.asset(withOriginal: nil, preview: ZMAssetPreview.preview(withSize: previewSize, mimeType: previewMimeType, remoteData: remoteData, imageMetadata: imageMetadata))
            let genericMessage = ZMGenericMessage.message(content: asset, nonce: sut.nonce!)
            let payload : [String : AnyObject] = [
                "type" : "conversation.otr-asset-add" as AnyObject,
                "data" : [
                    "id" : uuid
                ] as AnyObject
            ]
            let updateEvent = ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: UUID.create())!
            XCTAssertNil(sutInSyncContext.fileMessageData?.thumbnailAssetID)
            
            sutInSyncContext.update(with: genericMessage, updateEvent: updateEvent, initialUpdate: true) // Append preview
            XCTAssertTrue(self.syncMOC.saveOrRollback())
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        // properties changed in sync context are visible
        XCTAssertEqual(sut.genericAssetMessage?.asset.preview.remote.otrKey, remoteData.otrKey)
        XCTAssertEqual(sut.genericAssetMessage?.asset.preview.remote.sha256, remoteData.sha256)
        XCTAssertEqual(sut.genericAssetMessage?.asset.preview.image.width, imageMetadata.width)
    }
}

// MARK: Helpers

extension ZMAssetClientMessageTests {
    
    func createOtherClientAndConversation() -> (UserClient, ZMConversation) {
        let otherUser = ZMUser.insertNewObject(in:self.syncMOC)
        otherUser.remoteIdentifier = .create()
        let otherClient = createClient(for: otherUser, createSessionWithSelfUser: true)
        let conversation = ZMConversation.insertNewObject(in:self.syncMOC)
        conversation.conversationType = .group
        conversation.internalAddParticipants([otherUser])
        XCTAssertTrue(self.syncMOC.saveOrRollback())
        
        return (otherClient, conversation)
    }
}

// MARK: - Associated Task Identifier
extension ZMAssetClientMessageTests {
    
    func testThatItStoresTheAssociatedTaskIdentifier() {
        // given
        let sut = ZMAssetClientMessage(nonce: .create(), managedObjectContext: uiMOC)
        
        // when
        let identifier = ZMTaskIdentifier(identifier: 42, sessionIdentifier: "foo")
        sut.associatedTaskIdentifier = identifier
        XCTAssertTrue(self.uiMOC.saveOrRollback())
        self.uiMOC.refresh(sut, mergeChanges: false)
        
        // then
        XCTAssertEqual(sut.associatedTaskIdentifier, identifier)
    }
    
}

// MARK: - Message generation
extension ZMAssetClientMessageTests {
    
    func testThatItSavesTheOriginalFileWhenCreatingMessage()
    {
        // given
        let sut = appendImageMessage(to: conversation)
        
        // then
        XCTAssertNotNil(uiMOC.zm_fileAssetCache.assetData(sut, format: .original, encrypted: false))
    }

    func testThatItSetsTheOriginalImageSize()
    {
        // given
        let image = self.verySmallJPEGData()
        let expectedSize = ZMImagePreprocessor.sizeOfPrerotatedImage(with: image)
        
        // when
        let sut = appendImageMessage(to: conversation, imageData: image)
//        let imageMessageStorage = sut.imageAssetStorage
        
        // then
        XCTAssertEqual(expectedSize, sut.imageMessageData?.originalSize)
    }
}


// MARK: - Post event
extension ZMAssetClientMessageTests {

    func testThatItDoesSetConversationLastServerTimestampWhenPostingAsset_MessageIsImage() {
        // given
        syncMOC.performGroupedBlockAndWait {
            let message = self.appendImageMessage(to: self.syncConversation)
            let emptyDict = [String: String]()
            let payload: [AnyHashable: Any] = ["deleted": emptyDict, "missing": emptyDict, "redundant": emptyDict, "time": Date().transportString()]
//            message.uploadState = .uploadingFullAsset

            // when
            message.update(withPostPayload: payload, updatedKeys: Set([#keyPath(ZMAssetClientMessage.transferState)]))

            // then
            XCTAssertEqual(message.serverTimestamp, message.conversation?.lastServerTimeStamp)
        }
    }
    
    func testThatItDoesSetExpectsReadConfirmationWhenPostingAsset_MessageIsImage_HasReceiptsEnabled() {
        // given
        syncMOC.performGroupedBlockAndWait {
            self.syncConversation.hasReadReceiptsEnabled = true
            let message = self.appendImageMessage(to: self.syncConversation)
            let emptyDict = [String: String]()
            let payload: [AnyHashable: Any] = ["deleted": emptyDict, "missing": emptyDict, "redundant": emptyDict, "time": Date().transportString()]
//            message.transferState = .uploadingFullAsset
            
            // when
            message.update(withPostPayload: payload, updatedKeys: Set([#keyPath(ZMAssetClientMessage.transferState)]))
            
            // then
            XCTAssertTrue(message.expectsReadConfirmation)
        }
    }
    
    func testThatItDoesNotSetExpectsReadConfirmationWhenPostingAsset_MessageIsImage_HasReceiptsDisabled() {
        // given
        syncMOC.performGroupedBlockAndWait {
            self.syncConversation.hasReadReceiptsEnabled = false
            let message = self.appendImageMessage(to: self.syncConversation)
            let emptyDict = [String: String]()
            let payload: [AnyHashable: Any] = ["deleted": emptyDict, "missing": emptyDict, "redundant": emptyDict, "time": Date().transportString()]
            
            // when
            message.update(withPostPayload: payload, updatedKeys: Set([#keyPath(ZMAssetClientMessage.transferState)]))
            
            // then
            XCTAssertFalse(message.expectsReadConfirmation)
        }
    }
    
}

// MARK: - Assets V2

extension ZMAssetClientMessageTests {
    
    func sampleImageData() -> Data {
        return self.verySmallJPEGData()
    }
    
    func sampleProcessedImageData(_ format: ZMImageFormat) -> Data {
        return "\(StringFromImageFormat(format)) fake data".data(using: String.Encoding.utf8, allowLossyConversion: true)!
    }
    
    func sampleImageProperties(_ format: ZMImageFormat) -> ZMIImageProperties {
        let mult = format == .medium ? 100 : 1
        return ZMIImageProperties(size: CGSize(width: CGFloat(300*mult), height: CGFloat(100*mult)), length: UInt(100*mult), mimeType: "image/jpeg")!
    }

    func createV2AssetClientMessageWithSampleImageAndEncryptionKeys(_ storeOriginal: Bool, storeEncrypted: Bool, storeProcessed: Bool, imageData: Data? = nil) -> ZMAssetClientMessage {
        let directory = self.uiMOC.zm_fileAssetCache
        let nonce = UUID.create()
        let imageData = imageData ?? sampleImageData()
        var genericMessage : [ZMImageFormat : ZMGenericMessage] = [:]
        let assetMessage = ZMAssetClientMessage(nonce: nonce, managedObjectContext: uiMOC)
        assetMessage.sender = selfUser
        assetMessage.visibleInConversation = conversation
        
        for format in [ZMImageFormat.medium, ZMImageFormat.preview] {
            let processedData = sampleProcessedImageData(format)
            let otrKey = Data.randomEncryptionKey()
            let encryptedData = processedData.zmEncryptPrefixingPlainTextIV(key: otrKey)
            let sha256 = encryptedData.zmSHA256Digest()
            let encryptionKeys = ZMImageAssetEncryptionKeys(otrKey: otrKey, sha256: sha256)
            let imageAsset = ZMImageAsset(mediumProperties: storeProcessed ? self.sampleImageProperties(.medium) : nil,
                                          processedProperties: storeProcessed ? self.sampleImageProperties(format) : nil,
                                          encryptionKeys: storeEncrypted ? encryptionKeys : nil,
                                          format: format)
            
            genericMessage[format] = ZMGenericMessage.message(content: imageAsset, nonce: nonce)
            
            if (storeProcessed) {
                directory.storeAssetData(assetMessage, format: format, encrypted: false, data: processedData)
            }
            if (storeEncrypted) {
                directory.storeAssetData(assetMessage, format: format, encrypted: true, data: encryptedData)
            }
        }
        
        if (storeOriginal) {
            directory.storeAssetData(assetMessage, format: .original, encrypted: false, data: imageData)
        }
        
        
        assetMessage.add(genericMessage[.preview]!)
        assetMessage.add(genericMessage[.medium]!)
        assetMessage.assetId = nonce
        return assetMessage
    }

    func testThatImageDataCanBeFetchedAsynchrounously() {
        // given
        let message = self.createV2AssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: true)
        uiMOC.saveOrRollback()
        
        // expect
        let expectation = self.expectation(description: "Image arrived")
        
        // when
        message.imageMessageData?.fetchImageData(with: DispatchQueue.global(qos: .background), completionHandler: { (imageData) in
            XCTAssertNotNil(imageData)
            expectation.fulfill()
        })
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }
    
    func testThatItReturnsImageDataIdentifier() {
        // given
        let message1 = self.createV2AssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: false)
        let message2 = self.createV2AssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: false)
        
        // when
        let id1 = message1.imageMessageData?.imageDataIdentifier
        let id2 = message2.imageMessageData?.imageDataIdentifier
        
        
        // then
        XCTAssertNotNil(id1)
        XCTAssertNotNil(id2)
        XCTAssertNotEqual(id1, id2)
        
        XCTAssertEqual(id1, message1.imageMessageData?.imageDataIdentifier) // not random!
    }
        
    func testThatItHasDownloadedFileWhenTheImageIsOnDisk() {
        
        // given
        let message = self.createV2AssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: true)
        
        // then
        XCTAssertTrue(message.hasDownloadedFile)
    }
    
    func testThatItHasDownloadedFileWhenTheOriginalIsOnDisk() {
        
        // given
        let message = self.createV2AssetClientMessageWithSampleImageAndEncryptionKeys(true, storeEncrypted: false, storeProcessed: false)
        
        // then
        XCTAssertTrue(message.hasDownloadedFile)
    }
    
    func testThatDoesNotHaveDownloadedFileWhenTheImageIsNotOnDisk() {
        
        // given
        let message = self.createV2AssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: true)
        
        // when
        self.uiMOC.zm_fileAssetCache.deleteAssetData(message, format: .medium, encrypted: false)
        
        // then
        XCTAssertFalse(message.hasDownloadedFile)
    }
    
    func testThatRequestingFileDownloadFiresANotification() {
        
        // given
        let message = self.createV2AssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: true)
        message.managedObjectContext?.saveOrRollback()
        
        // expect
        let expectation = self.expectation(description: "Notified")
        let token = NotificationInContext.addObserver(name: ZMAssetClientMessage.imageDownloadNotificationName,
                                                      context: self.uiMOC.notificationContext,
                                                      object: message.objectID,
                                                      queue: nil)
        { _ in
            expectation.fulfill()
        }
        
        // when
        message.imageMessageData?.requestFileDownload()

        // then
        withExtendedLifetime(token) { () -> () in
            XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        }
    }
}


// MARK: - UpdateEvents

extension ZMAssetClientMessageTests {

        
    func testThatItCreatesOTRAssetMessagesFromAssetNotUploadedFailedUpdateEvent() {
        
        // given
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        conversation.remoteIdentifier = UUID.create()
        let nonce = UUID.create()
        let thumbnailId = "uuid"
        let asset = ZMAsset.asset(withNotUploaded: ZMAssetNotUploaded.FAILED)
//        let asset = ZMAsset.asset(withOriginal: original, preview: nil)
        
        let genericMessage = ZMGenericMessage.message(content: asset, nonce: nonce)
        
        let dataPayload = [
            "info" : genericMessage.data().base64String(),
            "id" : thumbnailId
            ] as [String : Any]
        
        let payload = self.payloadForMessage(in: conversation, type: EventConversationAddOTRAsset, data: dataPayload)!
        let updateEvent = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)!
        
        // when
        var sut: ZMAssetClientMessage!
        performPretendingUiMocIsSyncMoc {
            sut = ZMAssetClientMessage.createOrUpdate(from: updateEvent, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut.conversation?.remoteIdentifier, conversation.remoteIdentifier)
        XCTAssertEqual(sut.sender?.remoteIdentifier!.transportString(), payload["from"] as? String)
        XCTAssertEqual(sut.serverTimestamp?.transportString(), payload["time"] as? String)
        XCTAssertEqual(sut.nonce, nonce)
        XCTAssertNotNil(sut.fileMessageData)
    }
    
    func testThatItCreatesOTRAssetMessagesFromAssetOriginalUpdateEvent() {
        
        // given
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        conversation.remoteIdentifier = UUID.create()
        let nonce = UUID.create()
        let thumbnailId = "uuid"
        let imageMetadata = ZMAssetImageMetaData.imageMetaData(withWidth: 4235, height: 324)
        let original  = ZMAssetOriginal.original(withSize: 12321, mimeType: "image/jpeg", name: nil, imageMetaData: imageMetadata)
        let asset = ZMAsset.asset(withOriginal: original, preview: nil)
        
        let genericMessage = ZMGenericMessage.message(content: asset, nonce: nonce)
        
        let dataPayload = [
            "info" : genericMessage.data().base64String(),
            "id" : thumbnailId
            ] as [String : Any]
        
        let payload = self.payloadForMessage(in: conversation, type: EventConversationAddOTRAsset, data: dataPayload)!
        let updateEvent = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)!
        
        // when
        var sut: ZMAssetClientMessage!
        performPretendingUiMocIsSyncMoc {
            sut = ZMAssetClientMessage.createOrUpdate(from: updateEvent, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut.conversation?.remoteIdentifier, conversation.remoteIdentifier)
        XCTAssertEqual(sut.sender?.remoteIdentifier!.transportString(), payload["from"] as? String)
        XCTAssertEqual(sut.serverTimestamp?.transportString(), payload["time"] as? String)
        XCTAssertEqual(sut.nonce, nonce)
        XCTAssertNotNil(sut.fileMessageData)
    }
    
    func testThatItDoesNotUpdateTheTimestampIfLater() {
        self.syncMOC.performGroupedBlockAndWait {
            // given
            let conversation = ZMConversation.insertNewObject(in:self.syncMOC)
            conversation.remoteIdentifier = UUID.create()
            let nonce = UUID.create()
            let thumbnailId = UUID.create()
            let remoteData = ZMAssetRemoteData.remoteData(withOTRKey: Data.zmRandomSHA256Key(), sha256: Data.zmRandomSHA256Key())
            let imageMetadata = ZMAssetImageMetaData.imageMetaData(withWidth: 4235, height: 324)
            let asset = ZMAsset.asset(withOriginal: nil, preview: ZMAssetPreview.preview(withSize: 256, mimeType: "video/mp4", remoteData: remoteData, imageMetadata: imageMetadata))
            let firstDate = Date(timeIntervalSince1970: 12334)
            let secondDate = firstDate.addingTimeInterval(234444)
            
            let genericMessage = ZMGenericMessage.message(content: asset, nonce: nonce)
            
            let dataPayload = [
                "info" : genericMessage.data().base64String(),
                "id" : thumbnailId.transportString()
            ]
            
            let payload1 = self.payloadForMessage(in: conversation, type: EventConversationAddOTRAsset, data: dataPayload, time: firstDate)!
            let updateEvent1 = ZMUpdateEvent(fromEventStreamPayload: payload1, uuid: nil)!
            let payload2 = self.payloadForMessage(in: conversation, type: EventConversationAddOTRAsset, data: dataPayload, time: secondDate)!
            let updateEvent2 = ZMUpdateEvent(fromEventStreamPayload: payload2, uuid: nil)!
            
            
            // when
            let sut = ZMAssetClientMessage.createOrUpdate(from: updateEvent1, in: self.syncMOC, prefetchResult: nil)
            sut?.update(with: updateEvent2, for: conversation)
            
            // then
            XCTAssertEqual(sut?.serverTimestamp, firstDate)

        }
    }
}

// MARK: - Message Deletion

extension ZMAssetClientMessageTests {
    
    func testThatAnAssetClientMessageWithFileDataCanBeDeleted_Sent() {
        checkThatFileMessageCanBeDeleted(true, .sent)
    }
    
    func testThatAnAssetClientMessageWithFileDataCanBeDeleted_Delivered() {
        checkThatFileMessageCanBeDeleted(true, .delivered)
    }
    
    func testThatAnAssetClientMessageWithFileDataCanBeDeleted_Expired() {
        checkThatFileMessageCanBeDeleted(true, .failedToSend)
    }
    
    func testThatAnAssetClientMessageWithFileDataCan_Not_BeDeleted_Pending() {
        checkThatFileMessageCanBeDeleted(false, .pending)
    }
    
    func testThatAnAssetClientMessageWithImageDataCanBeDeleted_Sent() {
        checkThatImageAssetMessageCanBeDeleted(true, .sent)
    }
    
    func testThatAnAssetClientMessageWithImageDataCanBeDeleted_Delivered() {
        checkThatImageAssetMessageCanBeDeleted(true, .delivered)
    }
    
    func testThatAnAssetClientMessageWithImageDataCanBeDeleted_Expired() {
        checkThatImageAssetMessageCanBeDeleted(true, .failedToSend)
    }
    
    func testThatAnAssetClientMessageWithImageDataCan_Not_BeDeleted_Pending() {
        checkThatImageAssetMessageCanBeDeleted(false, .pending)
    }
}

extension ZMAssetClientMessageTests {

    // MARK: Helper
    func checkThatFileMessageCanBeDeleted(_ canBeDeleted: Bool, _ state: ZMDeliveryState, line: UInt = #line) {
        syncMOC.performAndWait {
            // given
            let sut = appendFileMessage(to: syncConversation)!
            XCTAssertNotNil(sut.fileMessageData, line: line)
            XCTAssertTrue(self.syncMOC.saveOrRollback(), line: line)
            
            // when
            self.updateMessageState(sut, state: state)
            XCTAssertEqual(sut.deliveryState.rawValue, state.rawValue, line: line)
            
            // then
            XCTAssertEqual(sut.canBeDeleted, canBeDeleted, line: line)
        }
    }
    
    func checkThatImageAssetMessageCanBeDeleted(_ canBeDeleted: Bool, _ state: ZMDeliveryState, line: UInt = #line) {
        // given
         let sut = appendImageMessage(to: conversation)
        XCTAssertNotNil(sut.imageMessageData, line: line)
        XCTAssertTrue(uiMOC.saveOrRollback(), line: line)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5), line: line)
        
        // when
        updateMessageState(sut, state: state)
        XCTAssertEqual(sut.deliveryState, state, line: line)
        
        // then
        XCTAssertEqual(sut.canBeDeleted, canBeDeleted, line: line)
    }
    
    func updateMessageState(_ message: ZMOTRMessage, state: ZMDeliveryState) {
        if state == .sent || state == .delivered {
            message.delivered = true
        } else if state == .failedToSend {
            message.expire()
        }
        if state == .delivered {
            _ = ZMMessageConfirmation(type: .delivered, message: message, sender: message.sender!, serverTimestamp: Date(), managedObjectContext: message.managedObjectContext!)
            message.managedObjectContext?.saveOrRollback()
        }
    }
    
}


// MARK: - Asset V3

// MARK: Receiving


extension ZMAssetClientMessageTests {

    typealias PreviewMeta = (otr: Data, sha: Data, assetId: String?, token: String?)

    private func originalGenericMessage(nonce: UUID, image: ZMAssetImageMetaData? = nil, preview: ZMAssetPreview? = nil, mimeType: String = "image/jpg", name: String? = nil) -> ZMGenericMessage {
        let asset = ZMAsset.asset(withOriginal: .original(withSize: 128, mimeType: mimeType, name: name, imageMetaData: image), preview: preview)
        return ZMGenericMessage.message(content: asset, nonce: nonce)
    }

    private func uploadedGenericMessage(nonce: UUID, otr: Data = .randomEncryptionKey(), sha: Data = .zmRandomSHA256Key(), assetId: UUID? = UUID.create(), token: UUID? = UUID.create()) -> ZMGenericMessage {

        let assetBuilder = ZMAsset.builder()!
        let remoteBuilder = ZMAssetRemoteData.builder()!

        _ = remoteBuilder.setOtrKey(otr)
        _ = remoteBuilder.setSha256(sha)
        if let assetId = assetId {
            _ = remoteBuilder.setAssetId(assetId.transportString())
        }
        if let token = token {
            _ = remoteBuilder.setAssetToken(token.transportString())
        }

        assetBuilder.setUploaded(remoteBuilder)
        return ZMGenericMessage.message(content: assetBuilder.build(), nonce: nonce)
    }

    func previewGenericMessage(with nonce: UUID, assetId: String? = UUID.create().transportString(), token: String? = UUID.create().transportString(), otr: Data = .randomEncryptionKey(), sha: Data = .randomEncryptionKey()) -> (ZMGenericMessage, PreviewMeta) {
        let assetBuilder = ZMAsset.builder()
        let previewBuilder = ZMAssetPreview.builder()
        let remoteBuilder = ZMAssetRemoteData.builder()

        _ = remoteBuilder?.setOtrKey(otr)
        _ = remoteBuilder?.setSha256(sha)
        if let assetId = assetId {
            _ = remoteBuilder?.setAssetId(assetId)
        }
        if let token = token {
            _ = remoteBuilder?.setAssetToken(token)
        }
        _ = previewBuilder?.setSize(512)
        _ = previewBuilder?.setMimeType("image/jpg")
        _ = previewBuilder?.setRemote(remoteBuilder)
        _ = assetBuilder?.setPreview(previewBuilder)

        let previewMeta = (otr, sha, assetId, token)
        return (ZMGenericMessage.message(content: assetBuilder!.build(), nonce: nonce), previewMeta)
    }

    func createMessageWithNonce() -> (ZMAssetClientMessage, UUID) {
        let nonce = UUID.create()
        let sut = ZMAssetClientMessage(nonce: nonce, managedObjectContext: self.uiMOC)
        sut.sender = selfUser
        sut.visibleInConversation = conversation
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertNotNil(sut)
        return (sut, nonce)
    }

    func testThatItReportsDownloadedFileWhenThereIsAFileOnDisk_V3() {
        // given
        let (sut, nonce) = createMessageWithNonce()

        // when
        let assetId = UUID.create()
        let assetData = Data.secureRandomData(length: 512)

        sut.update(with: originalGenericMessage(nonce: nonce, name: "document.pdf"), updateEvent: ZMUpdateEvent(), initialUpdate: true)
        sut.update(with: uploadedGenericMessage(nonce: nonce, assetId: assetId), updateEvent: ZMUpdateEvent(), initialUpdate: false)
        uiMOC.zm_fileAssetCache.storeAssetData(sut, encrypted: false, data: assetData)


        // then
        XCTAssertTrue(sut.hasDownloadedFile)
        XCTAssertEqual(sut.version, 3)
    }

    func testThatItReportsDownloadedFileWhenThereIsAnImageFileInTheCache_V3() {
        // given
        let (sut, nonce) = createMessageWithNonce()

        // when
        let assetId = UUID.create()
        let assetData = Data.secureRandomData(length: 512)
        let image = ZMAssetImageMetaData.imageMetaData(withWidth: 123, height: 4569)
        sut.update(with: originalGenericMessage(nonce: nonce, image: image, preview: nil), updateEvent: ZMUpdateEvent(), initialUpdate: false)
        sut.update(with: uploadedGenericMessage(nonce: nonce, assetId: assetId), updateEvent: ZMUpdateEvent(), initialUpdate: false)
        uiMOC.zm_fileAssetCache.storeAssetData(sut, format: .medium, encrypted: false, data: assetData)

        // then
        XCTAssertTrue(sut.hasDownloadedFile)
        XCTAssertEqual(sut.version, 3)
    }

    func testThatItReportsIsImageWhenItHasImageMetaData() {
        // given
        let (sut, nonce) = createMessageWithNonce()

        let image = ZMAssetImageMetaData.imageMetaData(withWidth: 123, height: 4569)
        let original = originalGenericMessage(nonce: nonce, image: image, preview: nil)
        let uploaded = uploadedGenericMessage(nonce: nonce)

        // when
        sut.update(with: original, updateEvent: ZMUpdateEvent(), initialUpdate: false)
        sut.update(with: uploaded, updateEvent: ZMUpdateEvent(), initialUpdate: false)

        // then
        XCTAssertTrue(sut.genericAssetMessage!.v3_isImage)
        XCTAssertEqual(sut.imageMessageData?.originalSize, CGSize(width: 123, height: 4569))
        XCTAssertEqual(sut.version, 3)
    }

    func testThatItReturnsAValidImageDataIdentifierEqualToTheCacheKeyOfTheAsset() {
        // given
        let (sut, nonce) = createMessageWithNonce()
        let assetId = UUID.create()

        let image = ZMAssetImageMetaData.imageMetaData(withWidth: 123, height: 4569)
        let original = originalGenericMessage(nonce: nonce, image: image, preview: nil)
        let uploaded = uploadedGenericMessage(nonce: nonce, assetId: assetId)

        // when
        sut.update(with: original, updateEvent: ZMUpdateEvent(), initialUpdate: false)
        sut.update(with: uploaded, updateEvent: ZMUpdateEvent(), initialUpdate: false)

        // then
        XCTAssertEqual(FileAssetCache.cacheKeyForAsset(sut, format: .medium), sut.imageMessageData?.imageDataIdentifier)
    }

    func testThatItReturnsTheThumbnailIdWhenItHasAPreviewRemoteData_V3() {
        // given
        let (sut, nonce) = createMessageWithNonce()

        // when
        let (preview, previewMeta) = previewGenericMessage(with: nonce)
        sut.update(with: preview, updateEvent: ZMUpdateEvent(), initialUpdate: false)

        // then
        XCTAssertEqual(sut.fileMessageData?.thumbnailAssetID, previewMeta.assetId)
    }

    func testThatItReturnsTheThumbnailDataWhenItHasItOnDisk_V3() {
        // given
        let (sut, nonce) = createMessageWithNonce()

        // when
        let previewData = Data.secureRandomData(length: 512)
        let (preview, _) = previewGenericMessage(with: nonce)
        sut.update(with: preview, updateEvent: ZMUpdateEvent(), initialUpdate: false)
        uiMOC.zm_fileAssetCache.storeAssetData(sut, format: .medium, encrypted: false, data: previewData)

        // then
        XCTAssertFalse(sut.hasDownloadedFile)
        XCTAssertTrue(sut.hasDownloadedPreview)
        XCTAssertEqual(sut.version, 3)
        
        let expectation = self.expectation(description: "preview data was retreived")
        sut.fileMessageData?.fetchImagePreviewData(queue: .global(qos: .background), completionHandler: { (previewDataResult) in
            XCTAssertEqual(previewDataResult, previewData)
            expectation.fulfill()
        })
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatIsHasDownloadedFileAndReturnsItWhenTheImageIsOnDisk_V3() {
        // given
        let (sut, nonce) = createMessageWithNonce()

        let data = verySmallJPEGData()
        let image = ZMAssetImageMetaData.imageMetaData(withWidth: 123, height: 4569)
        let original = originalGenericMessage(nonce: nonce, image: image, preview: nil)
        let uploaded = uploadedGenericMessage(nonce: nonce)

        // when
        sut.update(with: original, updateEvent: ZMUpdateEvent(), initialUpdate: false)
        sut.update(with: uploaded, updateEvent: ZMUpdateEvent(), initialUpdate: false)

        uiMOC.zm_fileAssetCache.storeAssetData(sut, format: .medium, encrypted: false, data: data)

        // then
        XCTAssertTrue(sut.genericAssetMessage!.v3_isImage)
        XCTAssertTrue(sut.hasDownloadedFile)
        XCTAssertEqual(sut.imageMessageData?.imageData, data)
        XCTAssertEqual(sut.version, 3)
    }
    
    func testThatRequestingImagePreviewDownloadFiresANotification_V3() {
        // given
        let (sut, nonce) = createMessageWithNonce()
        let (preview, _) = previewGenericMessage(with: nonce)
        sut.update(with: preview, updateEvent: ZMUpdateEvent(), initialUpdate: false)
        uiMOC.saveOrRollback()
        
        // expect
        let expectation = self.expectation(description: "Notified")
        let token = NotificationInContext.addObserver(name: ZMAssetClientMessage.imageDownloadNotificationName,
                                                      context: self.uiMOC.notificationContext,
                                                      object: sut.objectID,
                                                      queue: nil)
        { _ in
            expectation.fulfill()
        }
        
        // when
        sut.fileMessageData?.requestImagePreviewDownload()
        
        // then
        withExtendedLifetime(token) { () -> () in
            XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        }
    }

    func testThatRequestingFileDownloadFiresANotification_V3() {
        
        // given
        let (sut, nonce) = createMessageWithNonce()
        let image = ZMAssetImageMetaData.imageMetaData(withWidth: 123, height: 4569)
        let original = originalGenericMessage(nonce: nonce, image: image, preview: nil)
        let uploaded = uploadedGenericMessage(nonce: nonce)
        
        sut.update(with: original, updateEvent: ZMUpdateEvent(), initialUpdate: false)
        sut.update(with: uploaded, updateEvent: ZMUpdateEvent(), initialUpdate: false)
        uiMOC.saveOrRollback()
        
        // expect
        let expectation = self.expectation(description: "Notified")
        let token = NotificationInContext.addObserver(name: ZMAssetClientMessage.assetDownloadNotificationName,
                                                      context: self.uiMOC.notificationContext,
                                                      object: sut.objectID,
                                                      queue: nil)
        { _ in
            expectation.fulfill()
        }
        
        // when
        sut.imageMessageData?.requestFileDownload()
        
        // then
        withExtendedLifetime(token) { () -> () in
            XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        }
    }
    
}

// MARK: - isGIF
extension ZMAssetClientMessageTests {
    func testThatItDetectsGIF_MIME() {
        // GIVEN
        let gifMIME = "image/gif"
        // WHEN
        let isGif = UTType(mimeType: gifMIME)!.isGIF
        // THEN
        XCTAssertTrue(isGif)
    }
    
    func testThatItRejectsNonGIF_MIME() {
        // GIVEN
        
        ["text/plain", "application/pdf", "image/jpeg", "video/mp4"].forEach {
            // WHEN
            let isGif = UTType(mimeType: $0)!.isGIF
            
            // THEN
            XCTAssertFalse(isGif)
        }
    }
}
