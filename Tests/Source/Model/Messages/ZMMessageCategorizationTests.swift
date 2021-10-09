//
//

import XCTest
import WireUtilities
@testable import WireDataModel
import WireLinkPreview

extension ZMConversationMessage {
    fileprivate var categorization : MessageCategory {
        guard let message = self as? ZMMessage else {
            return .none
        }
        return message.category
    }
}

class ZMMessageCategorizationTests : ZMBaseManagedObjectTest {
    
    var conversation : ZMConversation!
    
    override func setUp() {
        super.setUp()
        self.conversation = ZMConversation.insertNewObject(in: uiMOC)
        self.conversation.conversationType = .group
        self.conversation.remoteIdentifier = UUID.create()
        
        let selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.remoteIdentifier = UUID()
        
        uiMOC.saveOrRollback()
    }
    
    override func tearDown() {
        self.conversation = nil
        super.tearDown()
    }
    
    func testThatItCategorizesATextMessage() {
        
        // GIVEN
        let message = self.conversation.append(text: "ramble on!")!
        
        // THEN
        XCTAssertEqual(message.categorization, MessageCategory.text)
    }
    
    func testThatItCategorizeTimedMessages() {
        
        // GIVEN
        let otherUser = ZMUser.insertNewObject(in: self.conversation.managedObjectContext!)
        otherUser.remoteIdentifier = UUID.create()
        
        self.conversation.mutableLastServerSyncedActiveParticipants.addObjects(from: [otherUser])
        self.conversation.messageDestructionTimeout = .local(.fiveMinutes)
        let message = self.conversation.append(text: "ramble on!")! as! ZMMessage
        
        // THEN
        XCTAssertEqual(message.categorization, MessageCategory.text)
    }

    func testThatItCategorizesATextMessageWithLink() {
        
        // GIVEN
        let message = self.conversation.append(text: "ramble on https://en.wikipedia.org/wiki/Ramble_On here")!
        
        // THEN
        XCTAssertEqual(message.categorization, [MessageCategory.text, MessageCategory.link])
    }
    
    func testThatItCategorizesALinkPreviewMessage() {
        
        // GIVEN
        let article = ArticleMetadata(
            originalURLString: "www.example.com/article/original",
            permanentURLString: "http://www.example.com/article/1",
            resolvedURLString: "http://www.example.com/article/1",
            offset: 12
        )
        article.title = "title"
        article.summary = "summary"
        let linkPreview = article.protocolBuffer.update(withOtrKey: Data(), sha256: Data())
        let genericMessage = ZMGenericMessage.message(content: ZMText.text(with: "foo", linkPreviews: [linkPreview]), nonce: UUID.create())
        let message = self.conversation.appendClientMessage(with: genericMessage)
        message?.linkPreviewState = .processed
        
        // THEN
        XCTAssertEqual(message?.categorization, [MessageCategory.text, MessageCategory.link, MessageCategory.linkPreview])
    }
    
    func testThatItCategorizesAnImageMessage() {
        
        // GIVEN
        let message = self.conversation.append(imageFromData: self.verySmallJPEGData())!
        
        // THEN
        XCTAssertEqual(message.categorization, MessageCategory.image)
    }

    func testThatItCategorizesAnImageMessage_WithoutData() {
        
        // GIVEN
        let message = self.conversation.append(imageFromData: self.verySmallJPEGData())!
        uiMOC.zm_fileAssetCache.deleteAssetData(message, format: .original, encrypted: false)
        
        // THEN
        XCTAssertEqual(message.categorization, [MessageCategory.image, MessageCategory.excludedFromCollection])
    }

    func testThatItCategorizesAGifImageMessage() {

        // GIVEN
        let data = self.data(forResource: "animated", extension: "gif")!
        let message = conversation.append(imageFromData: data) as! ZMAssetClientMessage

        // THEN
        XCTAssertEqual(message.categorization, [MessageCategory.image, MessageCategory.GIF])
    }

    func testThatItCategorizesKnocks() {
        
        // GIVEN
        let message = self.conversation.appendKnock() as! ZMClientMessage
        
        // THEN
        XCTAssertEqual(message.categorization, MessageCategory.knock)
    }
    
    func testThatItCategorizesFile() {
        
        // GIVEN
        let message = self.conversation.append(file: ZMFileMetadata(fileURL: self.fileURL(forResource: "Lorem Ipsum", extension: "txt")!))!
        
        // THEN
        XCTAssertEqual(message.categorization, MessageCategory.file)
    }
    
    func testThatItDoesCategorizeAFailedToUploadFile_ExcludedFromCollection() {
        
        // GIVEN
        let message = self.conversation.append(file: ZMFileMetadata(fileURL: self.fileURL(forResource: "Lorem Ipsum", extension: "txt")!)) as! ZMAssetClientMessage
        message.transferState = .uploadingFailed
        message.updateCategoryCache()
        
        // THEN
        XCTAssertEqual(message.categorization, [MessageCategory.file, MessageCategory.excludedFromCollection])
    }
    
    func testThatItDoesNotCategorizeACancelledToUploadFile_ExcludedFromCollection() {
        
        // GIVEN
        let message = self.conversation.append(file: ZMFileMetadata(fileURL: self.fileURL(forResource: "Lorem Ipsum", extension: "txt")!)) as! ZMAssetClientMessage
        message.transferState = .uploadingCancelled
        message.updateCategoryCache()
        
        // THEN
        XCTAssertEqual(message.categorization, [MessageCategory.file, MessageCategory.excludedFromCollection])
    }
    
    func testThatItCategorizesAudioFile() {
        
        // GIVEN
        let message = self.conversation.append(file: ZMAudioMetadata(fileURL: self.fileURL(forResource: "audio", extension: "m4a"), duration: 12.2))!
        
        // THEN
        XCTAssertEqual(message.categorization, [MessageCategory.file, MessageCategory.audio])
    }
    
    func testThatItCategorizesVideoFile() {
        
        // GIVEN
        let message = self.conversation.append(file: ZMVideoMetadata(fileURL: self.fileURL(forResource: "video", extension: "mp4"), thumbnail: self.verySmallJPEGData()))!
        
        // THEN
        XCTAssertEqual(message.categorization, [MessageCategory.file, MessageCategory.video])
    }
    
    func testThatItCategorizesLocation() {
        
        // GIVEN
        let message = self.conversation.append(location: LocationData.locationData(withLatitude: 40.42, longitude: 50.2, name: "Fooland", zoomLevel: Int32(2)))!
        
        // THEN
        XCTAssertEqual(message.categorization, MessageCategory.location)
    }
    
    func testThatItCategorizesV3Images() {
        
        // GIVEN
        let message = self.conversation.append(imageFromData: self.verySmallJPEGData())!
        
        // THEN
        XCTAssertEqual(message.categorization, MessageCategory.image)
    }
    
    func testThatItCategorizesSystemMessage() {
        
        // GIVEN
        let message = ZMSystemMessage(nonce: UUID(), managedObjectContext: conversation.managedObjectContext!)
        message.systemMessageType = .conversationNameChanged
        
        // THEN
        XCTAssertEqual(message.categorization, MessageCategory.systemMessage)
    }
    
    func testThatItCategorizesLikedTextMessageWhenLikedBySelfUser() {
        
        // GIVEN
        let message = self.conversation.append(text: "ramble on!")! as! ZMClientMessage
        message.delivered = true
        ZMMessage.addReaction(.like, toMessage: message)
        XCTAssertFalse(message.usersReaction.isEmpty)
        self.conversation.managedObjectContext?.saveOrRollback()
        
        // THEN
        XCTAssertEqual(message.categorization, [MessageCategory.text, MessageCategory.liked])
    }
    
    func testThatItCategorizesLikedFileMessageWhenLikedBySelfUser() {
        
        // GIVEN
        let message = self.conversation.append(file: ZMFileMetadata(fileURL: self.fileURL(forResource: "Lorem Ipsum", extension: "txt")!))! as! ZMAssetClientMessage
        message.delivered = true
        ZMMessage.addReaction(.like, toMessage: message)
        XCTAssertFalse(message.usersReaction.isEmpty)
        self.conversation.managedObjectContext?.saveOrRollback()
        
        // THEN
        XCTAssertEqual(message.categorization, [MessageCategory.file, MessageCategory.liked])
    }
    
    func testThatItCategorizesLikedTextMessageWhenNotLikedBySelfUser() {
        
        // GIVEN
        let otherUser = ZMUser.insertNewObject(in: self.conversation.managedObjectContext!)
        otherUser.remoteIdentifier = UUID.create()
        let message = self.conversation.append(text: "ramble on!")! as! ZMClientMessage
        message.delivered = true
        message.addReaction("❤️", forUser: otherUser)
        XCTAssertFalse(message.usersReaction.isEmpty)
        self.conversation.managedObjectContext?.saveOrRollback()
        
        // THEN
        XCTAssertEqual(message.categorization, MessageCategory.text)
    }
}

// MARK: - Cache
extension ZMMessageCategorizationTests {
    
    func testThatItComputesTheCachedCategoryLazily() {
        
        // GIVEN
        let message = self.conversation.append(text: "ramble on!")! as! ZMMessage
        message.setPrimitiveValue(NSNumber(value: 0), forKey: ZMMessageCachedCategoryKey)
        XCTAssertEqual(message.primitiveValue(forKey: ZMMessageCachedCategoryKey) as? NSNumber, NSNumber(value: 0))
        
        // WHEN
        let category = message.cachedCategory
        
        // THEN
        XCTAssertEqual(category, MessageCategory.text)
        XCTAssertEqual(message.primitiveValue(forKey: ZMMessageCachedCategoryKey) as? NSNumber, NSNumber(value: MessageCategory.text.rawValue))
    }
    
    func testThatItUsedCachedCategoryValueIfPresent() {
        
        // GIVEN
        let message = self.conversation.append(text: "ramble on!")! as! ZMMessage
        message.willChangeValue(forKey: ZMMessageCachedCategoryKey)
        message.setPrimitiveValue(NSNumber(value: MessageCategory.audio.rawValue), forKey: ZMMessageCachedCategoryKey)
        message.didChangeValue(forKey: ZMMessageCachedCategoryKey)
        
        // WHEN
        let category = message.cachedCategory
        
        // THEN
        XCTAssertEqual(category, MessageCategory.audio)
        XCTAssertEqual(message.primitiveValue(forKey: ZMMessageCachedCategoryKey) as? NSNumber, NSNumber(value: MessageCategory.audio.rawValue))

    }
    
    func testThatItComputestheCachedCategoryWhenAsked() {
        
        // GIVEN
        let message = self.conversation.append(text: "ramble on!")! as! ZMMessage
        message.setPrimitiveValue(NSNumber(value: 0), forKey: ZMMessageCachedCategoryKey)
        XCTAssertEqual(message.primitiveValue(forKey: ZMMessageCachedCategoryKey) as? NSNumber, NSNumber(value: 0))
        
        // WHEN
        message.updateCategoryCache()
        
        // THEN
        message.willAccessValue(forKey: ZMMessageCachedCategoryKey)
        let category = message.primitiveValue(forKey: ZMMessageCachedCategoryKey) as? NSNumber
        message.didAccessValue(forKey: ZMMessageCachedCategoryKey)
        
        XCTAssertEqual(category?.int32Value, MessageCategory.text.rawValue)
    }
}

// MARK: - Fetch request
extension ZMMessageCategorizationTests {
    
    func testThatItCreatesAFetchRequestToFetchText() {
        
        // GIVEN
        let textMessage = self.conversation.append(text: "in the still of the night")! as! ZMMessage
        textMessage.cachedCategory = MessageCategory.text
        textMessage.serverTimestamp = Date(timeIntervalSince1970: 100)
        let knockMessage = self.conversation.append(text: "in the still of the night")! as! ZMMessage
        knockMessage.cachedCategory = MessageCategory.knock
        knockMessage.serverTimestamp = Date(timeIntervalSince1970: 2000)
        let linkTextMessage = self.conversation.append(text: "in the still of the night")! as! ZMMessage
        linkTextMessage.cachedCategory = [MessageCategory.link, MessageCategory.text]
        linkTextMessage.serverTimestamp = Date(timeIntervalSince1970: 3000)
        let likedTextMessage = self.conversation.append(text: "in the still of the night")! as! ZMMessage
        likedTextMessage.cachedCategory = [MessageCategory.liked, MessageCategory.text]
        likedTextMessage.serverTimestamp = Date(timeIntervalSince1970: 5000)
        self.conversation.managedObjectContext?.saveOrRollback()
        
        // WHEN
        let fetchRequest = ZMMessage.fetchRequestMatching(categories: Set(arrayLiteral: MessageCategory.text))
        let results = try? self.conversation.managedObjectContext!.fetch(fetchRequest)
        
        // THEN
        guard let messages = results as? [ZMMessage] else {
            XCTFail("Result is \(String(describing: results))")
            return
        }
        XCTAssertTrue(messages.contains(textMessage))
        XCTAssertFalse(messages.contains(knockMessage))
        XCTAssertTrue(messages.contains(linkTextMessage))
        XCTAssertTrue(messages.contains(likedTextMessage))
    }
    
    func testThatItCreatesAFetchRequestToFetchTextOrKnock() {
        
        // GIVEN
        let textMessage = self.conversation.append(text: "in the still of the night")! as! ZMMessage
        textMessage.cachedCategory = MessageCategory.text
        textMessage.serverTimestamp = Date(timeIntervalSince1970: 100)
        let knockMessage = self.conversation.append(text: "in the still of the night")! as! ZMMessage
        knockMessage.cachedCategory = MessageCategory.knock
        knockMessage.serverTimestamp = Date(timeIntervalSince1970: 2000)
        let linkTextMessage = self.conversation.append(text: "in the still of the night")! as! ZMMessage
        linkTextMessage.cachedCategory = [MessageCategory.link, MessageCategory.text]
        linkTextMessage.serverTimestamp = Date(timeIntervalSince1970: 3000)
        let likedTextMessage = self.conversation.append(text: "in the still of the night")! as! ZMMessage
        likedTextMessage.cachedCategory = [MessageCategory.liked, MessageCategory.text]
        likedTextMessage.serverTimestamp = Date(timeIntervalSince1970: 5000)
        self.conversation.managedObjectContext?.saveOrRollback()
        
        // WHEN
        let fetchRequest = ZMMessage.fetchRequestMatching(categories: Set(arrayLiteral: MessageCategory.text, MessageCategory.knock))
        let results = try? self.conversation.managedObjectContext!.fetch(fetchRequest)
        
        // THEN
        guard let messages = results as? [ZMMessage] else {
            XCTFail("Result is \(String(describing: results))")
            return
        }
        XCTAssertTrue(messages.contains(textMessage))
        XCTAssertTrue(messages.contains(knockMessage))
        XCTAssertTrue(messages.contains(linkTextMessage))
        XCTAssertTrue(messages.contains(likedTextMessage))
    }
    
    func testThatItCreatesAFetchRequestToFetchLikedText() {
        
        // GIVEN
        let textMessage = self.conversation.append(text: "в ночной тиши")! as! ZMMessage
        textMessage.cachedCategory = MessageCategory.text
        textMessage.serverTimestamp = Date(timeIntervalSince1970: 100)
        let knockMessage = self.conversation.append(text: "in the still of the night")! as! ZMMessage
        knockMessage.cachedCategory = MessageCategory.knock
        knockMessage.serverTimestamp = Date(timeIntervalSince1970: 2000)
        let linkTextMessage = self.conversation.append(text: "in the still of the night")! as! ZMMessage
        linkTextMessage.cachedCategory = [MessageCategory.link, MessageCategory.text]
        linkTextMessage.serverTimestamp = Date(timeIntervalSince1970: 3000)
        let likedTextMessage = self.conversation.append(text: "in the still of the night")! as! ZMMessage
        likedTextMessage.cachedCategory = [MessageCategory.liked, MessageCategory.text]
        likedTextMessage.serverTimestamp = Date(timeIntervalSince1970: 5000)
        self.conversation.managedObjectContext?.saveOrRollback()
        
        // WHEN
        let fetchRequest = ZMMessage.fetchRequestMatching(categories: Set(arrayLiteral: [MessageCategory.text, MessageCategory.liked]))
        let results = try? self.conversation.managedObjectContext!.fetch(fetchRequest)
        
        // THEN
        guard let messages = results as? [ZMMessage] else {
            XCTFail("Result is \(String(describing: results))")
            return
        }
        XCTAssertFalse(messages.contains(textMessage))
        XCTAssertFalse(messages.contains(knockMessage))
        XCTAssertFalse(messages.contains(linkTextMessage))
        XCTAssertTrue(messages.contains(likedTextMessage))
    }
    
    func testThatItCreatesAFetchRequestToFetchLikedTextOrKnock() {
        
        // GIVEN
        let textMessage = self.conversation.append(text: "in the still of the night")! as! ZMMessage
        textMessage.cachedCategory = MessageCategory.text
        textMessage.serverTimestamp = Date(timeIntervalSince1970: 100)
        let knockMessage = self.conversation.append(text: "in the still of the night")! as! ZMMessage
        knockMessage.cachedCategory = MessageCategory.knock
        knockMessage.serverTimestamp = Date(timeIntervalSince1970: 2000)
        let linkTextMessage = self.conversation.append(text: "in the still of the night")! as! ZMMessage
        linkTextMessage.cachedCategory = [MessageCategory.link, MessageCategory.text]
        linkTextMessage.serverTimestamp = Date(timeIntervalSince1970: 3000)
        let likedTextMessage = self.conversation.append(text: "in the still of the night")! as! ZMMessage
        likedTextMessage.cachedCategory = [MessageCategory.liked, MessageCategory.text]
        likedTextMessage.serverTimestamp = Date(timeIntervalSince1970: 5000)
        self.conversation.managedObjectContext?.saveOrRollback()
        
        // WHEN
        let fetchRequest = ZMMessage.fetchRequestMatching(categories: Set(arrayLiteral: [MessageCategory.text, MessageCategory.liked], MessageCategory.knock))
        let results = try? self.conversation.managedObjectContext!.fetch(fetchRequest)
        
        // THEN
        guard let messages = results as? [ZMMessage] else {
            XCTFail("Result is \(String(describing: results))")
            return
        }
        XCTAssertFalse(messages.contains(textMessage))
        XCTAssertTrue(messages.contains(knockMessage))
        XCTAssertFalse(messages.contains(linkTextMessage))
        XCTAssertTrue(messages.contains(likedTextMessage))
    }
    
    func testThatItCreatesAFetchRequestToFetchTextExcludingLinksAndLiked() {
        
        // GIVEN
        let textMessage = self.conversation.append(text: "in the still of the night")! as! ZMMessage
        textMessage.cachedCategory = MessageCategory.text
        textMessage.serverTimestamp = Date(timeIntervalSince1970: 100)
        let knockMessage = self.conversation.append(text: "in the still of the night")! as! ZMMessage
        knockMessage.cachedCategory = MessageCategory.knock
        knockMessage.serverTimestamp = Date(timeIntervalSince1970: 2000)
        let linkTextMessage = self.conversation.append(text: "in the still of the night")! as! ZMMessage
        linkTextMessage.cachedCategory = [MessageCategory.link, MessageCategory.text]
        linkTextMessage.serverTimestamp = Date(timeIntervalSince1970: 3000)
        let likedTextMessage = self.conversation.append(text: "in the still of the night")! as! ZMMessage
        likedTextMessage.cachedCategory = [MessageCategory.liked, MessageCategory.text]
        likedTextMessage.serverTimestamp = Date(timeIntervalSince1970: 5000)
        self.conversation.managedObjectContext?.saveOrRollback()
        
        // WHEN
        let fetchRequest = ZMMessage.fetchRequestMatching(categories: Set(arrayLiteral: MessageCategory.text), excluding: [MessageCategory.link, MessageCategory.liked])
        let results = try? self.conversation.managedObjectContext!.fetch(fetchRequest)
        
        // THEN
        guard let messages = results as? [ZMMessage] else {
            XCTFail("Result is \(String(describing: results))")
            return
        }
        XCTAssertTrue(messages.contains(textMessage))
        XCTAssertFalse(messages.contains(knockMessage))
        XCTAssertFalse(messages.contains(linkTextMessage))
        XCTAssertFalse(messages.contains(likedTextMessage))
    }
    
    func testThatItFetchesFromAllConversations() {
        
        // GIVEN
        let otherConversation = ZMConversation.insertNewObject(in: self.uiMOC)
        otherConversation.conversationType = .group
        otherConversation.remoteIdentifier = UUID.create()
        
        let textMessage1 = self.conversation.append(text: "hey Jean!")! as! ZMMessage
        textMessage1.cachedCategory = MessageCategory.text
        textMessage1.serverTimestamp = Date(timeIntervalSince1970: 100)
        
        let textMessage2 = otherConversation.append(text: "hey Jean!")! as! ZMMessage
        textMessage2.cachedCategory = MessageCategory.text
        textMessage2.serverTimestamp = Date(timeIntervalSince1970: 300)
        
        // WHEN
        let fetchRequest = ZMMessage.fetchRequestMatching(categories: Set(arrayLiteral: MessageCategory.text))
        let results = try? self.conversation.managedObjectContext!.fetch(fetchRequest)

        // THEN
        guard let messages = results as? [ZMMessage] else {
            XCTFail("Result is \(String(describing: results))")
            return
        }
        XCTAssertTrue(messages.contains(textMessage1))
        XCTAssertTrue(messages.contains(textMessage2))
    }
    
    func testThatItFetchesFromASpecificConversations() {
        
        // GIVEN
        let otherConversation = ZMConversation.insertNewObject(in: self.uiMOC)
        otherConversation.conversationType = .group
        otherConversation.remoteIdentifier = UUID.create()
        
        let textMessage1 = self.conversation.append(text: "hey Jean!")! as! ZMMessage
        textMessage1.cachedCategory = MessageCategory.text
        textMessage1.serverTimestamp = Date(timeIntervalSince1970: 100)
        
        let textMessage2 = otherConversation.append(text: "hey Jean!")! as! ZMMessage
        textMessage2.cachedCategory = MessageCategory.text
        textMessage2.serverTimestamp = Date(timeIntervalSince1970: 300)
        
        // WHEN
        let fetchRequest = ZMMessage.fetchRequestMatching(categories: Set(arrayLiteral: MessageCategory.text), conversation: otherConversation)
        let results = try? self.conversation.managedObjectContext!.fetch(fetchRequest)
        
        // THEN
        guard let messages = results as? [ZMMessage] else {
            XCTFail("Result is \(String(describing: results))")
            return
        }
        XCTAssertFalse(messages.contains(textMessage1))
        XCTAssertTrue(messages.contains(textMessage2))
    }
}




// MARK: Categorization on insert

extension ZMMessageCategorizationTests {

    func testThatItCategorizesAClientMessageOnInsert(){
        
        // when
        let message = self.conversation.append(text: "hey Jean!")! as! ZMMessage
        
        // then
        XCTAssertEqual(message.primitiveValue(forKey: ZMMessageCachedCategoryKey) as? NSNumber, NSNumber(value: MessageCategory.text.rawValue))
    }
    
    func testThatItCategorizesALocationMessageOnInsert(){
        
        // when
        let message = self.conversation.append(location: LocationData.locationData(withLatitude: 40.42, longitude: 50.2, name: "Fooland", zoomLevel: Int32(2))) as! ZMMessage
        
        // then
        XCTAssertEqual(message.primitiveValue(forKey: ZMMessageCachedCategoryKey) as? NSNumber, NSNumber(value: MessageCategory.location.rawValue))
    }
    
    func testThatItCategorizesAKnockMessageOnInsert(){
        
        // when
        let message = self.conversation.appendKnock() as! ZMMessage
        // then
        XCTAssertEqual(message.primitiveValue(forKey: ZMMessageCachedCategoryKey) as? NSNumber, NSNumber(value: MessageCategory.knock.rawValue))
    }

    func testThatItCategorizesAnImageMessageOnInsert(){
        
        // when
        let message = self.conversation.append(imageFromData: verySmallJPEGData()) as! ZMMessage
        
        // then
        XCTAssertEqual(message.primitiveValue(forKey: ZMMessageCachedCategoryKey) as? NSNumber, NSNumber(value: MessageCategory.image.rawValue))
    }
    
    func testThatItCategorizesAVideoMessageOnInsert(){
        
        // when
        let message = self.conversation.append(file: ZMVideoMetadata(fileURL: self.fileURL(forResource: "video", extension: "mp4"), thumbnail: self.verySmallJPEGData())) as! ZMMessage
        
        // then
        let category = MessageCategory.file.union(MessageCategory.video)
        XCTAssertEqual(message.primitiveValue(forKey: ZMMessageCachedCategoryKey) as? NSNumber, NSNumber(value: category.rawValue))
    }
    
    func testThatItCategorizesAnAudioFile() {
        
        // GIVEN
        let message = self.conversation.append(file: ZMAudioMetadata(fileURL: self.fileURL(forResource: "audio", extension: "m4a"), duration: 12.2)) as! ZMMessage

        
        // THEN
        let category = MessageCategory.file.union(MessageCategory.audio)
        XCTAssertEqual(message.primitiveValue(forKey: ZMMessageCachedCategoryKey) as? NSNumber, NSNumber(value: category.rawValue))
    }
    
    func testThatItCategorizesAFileOnInsert() {
        
        // GIVEN
        let message = self.conversation.append(file: ZMFileMetadata(fileURL: self.fileURL(forResource: "Lorem Ipsum", extension: "txt")!)) as! ZMMessage
        
        // THEN
        XCTAssertEqual(message.primitiveValue(forKey: ZMMessageCachedCategoryKey) as? NSNumber, NSNumber(value: MessageCategory.file.rawValue))
    }
    
}
