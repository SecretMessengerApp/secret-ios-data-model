//
//

import Foundation
import WireImages
@testable import WireDataModel

class ZMConversationMessagesTests: ZMConversationTestsBase {
    
    func testThatWeCanInsertATextMessage() {
        
        self.syncMOC.performGroupedBlockAndWait {
            
            // given
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.remoteIdentifier = UUID()
    
            // when
            let messageText = "foo"
            let message = conversation.append(text: messageText) as! ZMMessage
    
            // then
            XCTAssertEqual(message.textMessageData?.messageText, messageText)
            XCTAssertEqual(message.conversation, conversation)
            XCTAssertEqual(conversation.lastMessage, message)
            XCTAssertEqual(selfUser, message.sender)
        }
    }

    
    func testThatItUpdatesTheLastModificationDateWhenInsertingMessagesIntoAnEmptyConversation()
    {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.lastModifiedDate = Date(timeIntervalSinceNow: -90000)
        
        // when
        guard let msg = conversation.append(text: "Foo") as? ZMMessage else {
            XCTFail()
            return
        }
    
        // then
        XCTAssertNotNil(msg.serverTimestamp)
        XCTAssertEqual(conversation.lastModifiedDate, msg.serverTimestamp)
    }
    
    func testThatItUpdatesTheLastModificationDateWhenInsertingMessages()
    {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        guard let msg1 = conversation.append(text: "Foo") as? ZMMessage else {
            XCTFail()
            return
        }
        msg1.serverTimestamp = Date(timeIntervalSinceNow: -90000)
        conversation.lastModifiedDate = msg1.serverTimestamp
    
        // when
        guard let msg2 = conversation.append(imageFromData: self.verySmallJPEGData()) as? ZMAssetClientMessage else {
            XCTFail()
            return
        }
    
        // then
        XCTAssertNotNil(msg2.serverTimestamp)
        XCTAssertEqual(conversation.lastModifiedDate, msg2.serverTimestamp)
    }
    
    func testThatItDoesNotUpdateTheLastModifiedDateForRenameAndLeaveSystemMessages()
    {
        let types = [
            ZMSystemMessageType.teamMemberLeave,
            ZMSystemMessageType.conversationNameChanged,
            ZMSystemMessageType.messageTimerUpdate
        ]

        for type in types {
            // given
            let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
            let lastModified = Date(timeIntervalSince1970: 10)
            conversation.lastModifiedDate = lastModified
    
            let systemMessage = ZMSystemMessage(nonce: UUID(), managedObjectContext: uiMOC)
            systemMessage.systemMessageType = type
            systemMessage.serverTimestamp = lastModified.addingTimeInterval(100)
    
            // when
            conversation.append(systemMessage)
    
            // then
            XCTAssertEqual(conversation.lastModifiedDate, lastModified)
        }
    }
    
    func testThatItIsSafeToPassInAMutableStringWhenCreatingATextMessage()
    {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID()
    
        // when
        let originalText = "foo";
        var messageText = originalText
        let message = conversation.append(text: messageText)!
    
        // then
        messageText.append("1234")
        XCTAssertEqual(message.textMessageData?.messageText, originalText)
    }
        
    func testThatWeCanInsertAnImageMessageFromAFileURL()
    {
        // given
        let selfUser = ZMUser.selfUser(in: self.uiMOC)
        let imageFileURL = self.fileURL(forResource: "1900x1500", extension: "jpg")!
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID()
    
        // when
        let message = conversation.append(imageAtURL: imageFileURL)! as! ZMAssetClientMessage
    
        // then
        XCTAssertNotNil(message)
        XCTAssertNotNil(message.nonce)
        XCTAssertTrue(message.imageMessageData!.originalSize.equalTo(CGSize(width: 1900, height: 1500)))
        XCTAssertEqual(message.conversation, conversation)
        XCTAssertEqual(conversation.lastMessage, message)
        XCTAssertNotNil(message.nonce)
        
        let expectedData = try! (try! Data(contentsOf: imageFileURL)).wr_removingImageMetadata()
        XCTAssertNotNil(expectedData)
        XCTAssertEqual(message.imageMessageData?.imageData, expectedData)
        XCTAssertEqual(selfUser, message.sender)
    }
    
    func testThatNoMessageIsInsertedWhenTheImageFileURLIsPointingToSomethingThatIsNotAnImage()
    {
        // given
        let imageFileURL = self.fileURL(forResource: "1900x1500", extension: "jpg")!
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID()
    
        // when
        let message = conversation.append(imageAtURL: imageFileURL)! as! ZMAssetClientMessage
    
        // then
        XCTAssertNotNil(message)
        XCTAssertNotNil(message.nonce)
        XCTAssertTrue(message.imageMessageData!.originalSize.equalTo(CGSize(width: 1900, height: 1500)))
        XCTAssertEqual(message.conversation, conversation)
        XCTAssertEqual(conversation.lastMessage, message)
        XCTAssertNotNil(message.nonce)
        
        let expectedData = try! (try! Data(contentsOf: imageFileURL)).wr_removingImageMetadata()
        XCTAssertNotNil(expectedData)
        XCTAssertEqual(message.imageMessageData?.imageData, expectedData)
    }

    func testThatNoMessageIsInsertedWhenTheImageFileURLIsNotAFileURL()
    {
        // given
        let imageURL = URL(string:"http://www.placehold.it/350x150")!
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID()
        let start = self.uiMOC.insertedObjects
    
        // when
        var message: Any? = nil
        self.performIgnoringZMLogError {
            message = conversation.append(imageAtURL: imageURL)
        }
    
        // then
        XCTAssertNil(message)
        XCTAssertEqual(start, self.uiMOC.insertedObjects)
    }

    func testThatNoMessageIsInsertedWhenTheImageFileURLIsNotPointingToAFile()
    {
        // given
        let textFileURL = self.fileURL(forResource: "Lorem Ipsum", extension: "txt")!
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID()
        let start = self.uiMOC.insertedObjects
    
        // when
        var message: Any? = nil
        self.performIgnoringZMLogError {
            message = conversation.append(imageAtURL: textFileURL)
        }
    
        // then
        XCTAssertNil(message)
        XCTAssertEqual(start, self.uiMOC.insertedObjects);
    }

    func testThatWeCanInsertAnImageMessageFromImageData()
    {
        // given
        let imageData = try! self.data(forResource: "1900x1500", extension: "jpg").wr_removingImageMetadata()
        XCTAssertNotNil(imageData)
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID()
    
        // when
        guard let message = conversation.append(imageFromData: imageData) as? ZMAssetClientMessage else {
            XCTFail()
            return
        }
    
        // then
        XCTAssertNotNil(message)
        XCTAssertNotNil(message.nonce)
        XCTAssertTrue(message.imageMessageData!.originalSize.equalTo(CGSize(width: 1900, height: 1500)))
        XCTAssertEqual(message.conversation, conversation)
        XCTAssertEqual(conversation.lastMessage, message)
        XCTAssertNotNil(message.nonce)
        XCTAssertEqual(message.imageMessageData?.imageData?.count, imageData.count)
    }

    func testThatItIsSafeToPassInMutableDataWhenCreatingAnImageMessage()
    {
        // given
        let originalImageData = try! self.data(forResource: "1900x1500", extension: "jpg").wr_removingImageMetadata()
        var imageData = originalImageData
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID()
    
        // when
        guard let message = conversation.append(imageFromData: imageData) as? ZMAssetClientMessage else {
            XCTFail()
            return
        }
        
        // then
        imageData.append(contentsOf: [1,2])
        XCTAssertEqual(message.imageMessageData?.imageData?.count, originalImageData.count)
    }
    
    func testThatNoMessageIsInsertedWhenTheImageDataIsNotAnImage()
    {
        // given
        let textData = self.data(forResource: "Lorem Ipsum", extension: "txt")!
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID()
        let start = self.uiMOC.insertedObjects
    
        // when
        var message: ZMConversationMessage? = nil
        self.performIgnoringZMLogError {
            message = conversation.append(imageFromData: textData)
        }

        // then
        XCTAssertNil(message)
        XCTAssertEqual(start, self.uiMOC.insertedObjects)
    }

    func testThatLastReadUpdatesInSelfConversationDontExpire()
    {
        self.syncMOC.performGroupedBlockAndWait {
            // given
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.remoteIdentifier = UUID()
            conversation.lastReadServerTimeStamp = Date()
            
            // when
            guard let message = ZMConversation.appendSelfConversation(withLastReadOf: conversation) else {
                XCTFail()
                return
            }
            
            // then
            XCTAssertNil(message.expirationDate)
        }
    }
    
    func testThatWeCanInsertAFileMessage()
    {
        // given
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let fileURL = URL(fileURLWithPath: documents).appendingPathComponent("secret_file.txt")
        let data = Data.randomEncryptionKey()
        let size = data.count
        try! data.write(to: fileURL)
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID()

        // when
        let fileMetaData = ZMFileMetadata(fileURL: fileURL)
        let fileMessage = conversation.append(file: fileMetaData) as! ZMAssetClientMessage
    
        // then
        XCTAssertEqual(conversation.lastMessage, fileMessage)
    
        XCTAssertNotNil(fileMessage)
        XCTAssertNotNil(fileMessage.nonce)
        XCTAssertNotNil(fileMessage.fileMessageData)
        XCTAssertNotNil(fileMessage.genericAssetMessage)
        XCTAssertNil(fileMessage.assetId)
        XCTAssertFalse(fileMessage.delivered)
        XCTAssertTrue(fileMessage.hasDownloadedFile)
        XCTAssertEqual(fileMessage.size, UInt64(size))
        XCTAssertEqual(fileMessage.progress, 0)
        XCTAssertEqual(fileMessage.filename, "secret_file.txt")
        XCTAssertEqual(fileMessage.mimeType, "text/plain")
        XCTAssertFalse(fileMessage.fileMessageData!.isVideo)
        XCTAssertFalse(fileMessage.fileMessageData!.isAudio)
    }

    func testThatWeCanInsertAPassFileMessage() {
        // given
        let filename = "ticket.pkpass"
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let fileURL = URL(fileURLWithPath: documents).appendingPathComponent(filename)
        let data = Data.randomEncryptionKey()
        let size = data.count
        try! data.write(to: fileURL)
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID()

        // when
        let fileMetaData = ZMFileMetadata(fileURL: fileURL)
        let fileMessage = conversation.append(file: fileMetaData) as! ZMAssetClientMessage

        // then
        XCTAssertEqual(conversation.lastMessage, fileMessage)

        XCTAssertNotNil(fileMessage)
        XCTAssertNotNil(fileMessage.nonce)
        XCTAssertNotNil(fileMessage.fileMessageData)
        XCTAssertNotNil(fileMessage.genericAssetMessage)
        XCTAssertNil(fileMessage.assetId)
        XCTAssertFalse(fileMessage.delivered)
        XCTAssertTrue(fileMessage.hasDownloadedFile)
        XCTAssertEqual(fileMessage.size, UInt64(size))
        XCTAssertEqual(fileMessage.progress, 0)
        XCTAssertEqual(fileMessage.filename, filename)
        XCTAssertEqual(fileMessage.mimeType, "application/vnd.apple.pkpass")
        XCTAssertFalse(fileMessage.fileMessageData!.isVideo)
        XCTAssertFalse(fileMessage.fileMessageData!.isAudio)
        XCTAssert(fileMessage.fileMessageData!.isPass)
    }

    func locationData() -> LocationData {
        let latitude = Float(48.53775)
        let longitude = Float(9.041169)
        let zoomLevel = Int32(16)
        let name = " နေပြည်တော် Test"
        let locationData = LocationData(latitude: latitude,
                                        longitude: longitude,
                                        name: name,
                                        zoomLevel: zoomLevel)

        return locationData
    }
    
    func testThatWeCanInsertALocationMessage()
    {
        // given
        let latitude = Float(48.53775)
        let longitude = Float(9.041169)
        let zoomLevel = Int32(16)
        let name = " နေပြည်တော် Test"
        let locationData = self.locationData()
        
        // when
        self.syncMOC.performGroupedBlockAndWait {
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.remoteIdentifier = UUID()
            let message = conversation.append(location: locationData) as! ZMMessage
        
            XCTAssertEqual(conversation.lastMessage, message)
    
            guard let locationMessageData = message.locationMessageData else {
                XCTFail()
                return
            }
            XCTAssertEqual(locationMessageData.longitude, longitude)
            XCTAssertEqual(locationMessageData.latitude, latitude)
            XCTAssertEqual(locationMessageData.zoomLevel, zoomLevel)
            XCTAssertEqual(locationMessageData.name, name)
        }
    }
    
    func testThatLocationMessageHasNoImage() {
        // given
        let locationData = self.locationData()

        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.messageDestructionTimeout = .local(.fiveMinutes)
        conversation.remoteIdentifier = UUID()
        // when
        let message = conversation.append(location: locationData) as! ZMClientMessage
        
        // then
        XCTAssertNil(message.underlyingMessage?.imageAssetData)
        XCTAssertNotNil(message.underlyingMessage?.locationData)
        XCTAssertNotNil(message.expirationDate)
    }
    
    func testThatWeCanInsertAVideoMessage()
    {
        // given
        let fileName = "video.mp4"
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let fileURL = URL(fileURLWithPath: documents).appendingPathComponent(fileName)
        let videoData = Data.secureRandomData(length: 500)
        let thumbnailData = Data.secureRandomData(length: 250)
        let duration = 12333
        let dimensions = CGSize(width: 1900, height: 800)
        try! videoData.write(to: fileURL)
    
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID()

        // when
        let videoMetadata = ZMVideoMetadata(fileURL: fileURL,
                                            duration: TimeInterval(duration),
                                            dimensions: dimensions,
                                            thumbnail: thumbnailData)
        
        guard let fileMessage = conversation.append(file: videoMetadata) as? ZMAssetClientMessage else {
            XCTFail()
            return
        }
    
        // then
        XCTAssertEqual(conversation.lastMessage, fileMessage)
    
        XCTAssertNotNil(fileMessage)
        XCTAssertNotNil(fileMessage.nonce)
        XCTAssertNotNil(fileMessage.fileMessageData)
        XCTAssertNotNil(fileMessage.genericAssetMessage)
        XCTAssertNil(fileMessage.assetId)
        XCTAssertFalse(fileMessage.delivered)
        XCTAssertTrue(fileMessage.hasDownloadedFile)
        XCTAssertEqual(fileMessage.size, UInt64(videoData.count))
        XCTAssertEqual(fileMessage.progress, 0)
        XCTAssertEqual(fileMessage.filename, fileName)
        XCTAssertEqual(fileMessage.mimeType, "video/mp4")
        guard let fileMessageData = fileMessage.fileMessageData else {
            XCTFail()
            return
        }
        XCTAssertTrue(fileMessageData.isVideo)
        XCTAssertFalse(fileMessageData.isAudio)
        XCTAssertEqual(fileMessageData.durationMilliseconds, UInt64(duration * 1000))
        XCTAssertEqual(fileMessageData.videoDimensions.height, dimensions.height)
        XCTAssertEqual(fileMessageData.videoDimensions.width, dimensions.width)
    }

    func testThatWeCanInsertAnAudioMessage() {
        
        // given
        let fileName = "audio.m4a"
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let fileURL = URL(fileURLWithPath: documents).appendingPathComponent(fileName)
        let videoData = Data.secureRandomData(length: 500)
        let thumbnailData = Data.secureRandomData(length: 250)
        let duration = 12333
        try! videoData.write(to: fileURL)
        
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID()
        
        // when
        let audioMetadata = ZMAudioMetadata(fileURL: fileURL,
                                            duration: TimeInterval(duration),
                                            normalizedLoudness: [],
                                            thumbnail: thumbnailData)
        
        let fileMessage = conversation.append(file: audioMetadata) as! ZMAssetClientMessage
        
        // then
        XCTAssertEqual(conversation.lastMessage, fileMessage)
        
        XCTAssertNotNil(fileMessage)
        XCTAssertNotNil(fileMessage.nonce)
        XCTAssertNotNil(fileMessage.fileMessageData)
        XCTAssertNotNil(fileMessage.genericAssetMessage)
        XCTAssertNil(fileMessage.assetId)
        XCTAssertFalse(fileMessage.delivered)
        XCTAssertTrue(fileMessage.hasDownloadedFile)
        XCTAssertEqual(fileMessage.size, UInt64(videoData.count))
        XCTAssertEqual(fileMessage.progress, 0)
        XCTAssertEqual(fileMessage.filename, fileName)
        XCTAssertEqual(fileMessage.mimeType, "audio/x-m4a")
        guard let fileMessageData = fileMessage.fileMessageData else {
            XCTFail()
            return
        }
        XCTAssertFalse(fileMessageData.isVideo)
        XCTAssertTrue(fileMessageData.isAudio)
    }
    
    func testThatItDoesNotFetchMessageWhenMissing() {
        // GIVEN
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID()
        
        // WHEN
        let lastMessage = conversation.lastMessageSent(by: selfUser)
        
        // THEN
        XCTAssertEqual(lastMessage, nil)
    }
    
    func testThatItFetchesMessageForUser() {
        // GIVEN
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID()
        
        let message = conversation.append(text: "Test Message") as! ZMMessage
        
        // WHEN
        let lastMessage = conversation.lastMessageSent(by: selfUser)
        
        // THEN
        XCTAssertEqual(lastMessage, message)
    }
    
    func testThatItFetchesLastMessageForUser() {
        // GIVEN
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID()
        
        let _ = conversation.append(text: "Test Message") as! ZMMessage
        let message2 = conversation.append(text: "Test Message 2") as! ZMMessage
        
        // WHEN
        let lastMessage = conversation.lastMessageSent(by: selfUser)
        
        // THEN
        XCTAssertEqual(lastMessage, message2)
    }
    
    func testThatItIgnoreMessagesFromOtherUsers() {
        // GIVEN
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID()
        
        let message1 = conversation.append(text: "Test Message") as! ZMMessage
        message1.sender = self.createUser()
        
        self.uiMOC.processPendingChanges()
        
        // WHEN
        let lastMessage = conversation.lastMessageSent(by: selfUser)
        
        // THEN
        XCTAssertEqual(lastMessage, nil)
    }
}
