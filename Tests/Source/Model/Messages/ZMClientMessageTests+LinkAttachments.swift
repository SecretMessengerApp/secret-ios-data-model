//
//

import WireTesting

class ZMClientMessageTests_LinkAttachments: BaseZMClientMessageTests {

    func testThatItMatchesMessageNeedingUpdate() throws {
        // GIVEN
        let sender = ZMUser.insertNewObject(in: uiMOC)
        sender.remoteIdentifier = .create()

        let message1 = conversation.append(text: "Hello world") as! ZMMessage
        message1.sender = sender

        let message2 = conversation.append(text: "Hello world", fetchLinkPreview: false) as! ZMMessage
        message2.sender = sender
        uiMOC.saveOrRollback()

        // WHEN
        let fetchRequest = NSFetchRequest<ZMMessage>(entityName: ZMMessage.entityName())
        fetchRequest.predicate = ZMMessage.predicateForMessagesThatNeedToUpdateLinkAttachments()
        let fetchedMessages = try uiMOC.fetch(fetchRequest)

        // THEN
        XCTAssertEqual(fetchedMessages, [message1])
    }

    func testThatItSavesLinkAttachmentsAfterAssigning() throws {
        // GIVEN
        let sender = ZMUser.insertNewObject(in: uiMOC)
        sender.remoteIdentifier = .create()

        let nonce = UUID()

        let thumbnail = URL(string: "https://i.ytimg.com/vi/hyTNGkBSjyo/hqdefault.jpg")!

        var attachment: LinkAttachment! = LinkAttachment(type: .youTubeVideo, title: "Pingu Season 1 Episode 1",
                                                         permalink: URL(string: "https://www.youtube.com/watch?v=hyTNGkBSjyo")!,
                                                         thumbnails: [thumbnail],
                                                         originalRange: NSRange(location: 20, length: 43))

        var message: ZMClientMessage? = conversation.append(text: "Hello world", nonce: nonce) as? ZMClientMessage
        message?.sender = sender
        message?.linkAttachments = [attachment]
        uiMOC.saveOrRollback()
        uiMOC.refresh(message!, mergeChanges: false)

        message = nil
        attachment = nil

        // WHEN
        let fetchedMessage = ZMMessage.fetch(withNonce: nonce, for: conversation, in: uiMOC)
        let fetchedAttachment = fetchedMessage?.linkAttachments?.first

        // THEN
        XCTAssertEqual(fetchedAttachment?.type, .youTubeVideo)
        XCTAssertEqual(fetchedAttachment?.title, "Pingu Season 1 Episode 1")
        XCTAssertEqual(fetchedAttachment?.permalink, URL(string: "https://www.youtube.com/watch?v=hyTNGkBSjyo")!)
        XCTAssertEqual(fetchedAttachment?.thumbnails, [thumbnail])
        XCTAssertEqual(fetchedAttachment?.originalRange, NSRange(location: 20, length: 43))
    }

}
