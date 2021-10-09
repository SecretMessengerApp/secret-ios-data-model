//
//


import WireTesting
@testable import WireDataModel


fileprivate class MockTextSearchQueryDelegate: TextSearchQueryDelegate {

    var fetchedResults = [TextQueryResult]()

    fileprivate func textSearchQueryDidReceive(result: TextQueryResult) {
        fetchedResults.append(result)
    }
}


class TextSearchQueryTests: BaseZMClientMessageTests {

    func testThatItOnlyReturnsResultFromTheCorrectConversationNotYetIndexed() {
        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()
        let otherConversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()

        let firstMessage = conversation.append(text: "This is the first message in the conversation") as! ZMMessage
        let otherMessage = otherConversation.append(text: "This is the first message in the other conversation") as! ZMMessage
        fillConversationWithMessages(conversation: conversation, messageCount: 40, normalized: false)
        fillConversationWithMessages(conversation: otherConversation, messageCount: 40, normalized: false)
        [firstMessage, otherMessage].forEach {
            $0.normalizedText = nil
        }

        XCTAssert(uiMOC.saveOrRollback())
        XCTAssertNil(firstMessage.normalizedText)
        XCTAssertNil(otherMessage.normalizedText)
        XCTAssertEqual(conversation.allMessages.count, 41)
        XCTAssertEqual(otherConversation.allMessages.count, 41)

        // When
        let results = search(for: "in the conversation", in: conversation)

        // Then
        guard results.count == 1 else { return XCTFail("Unexpected count \(results.count)") }

        let result = results.first!
        XCTAssertFalse(result.hasMore)
        XCTAssertEqual(result.matches.count, 1)

        let match = result.matches[0]
        XCTAssertEqual(match, firstMessage)
        verifyAllMessagesAreIndexed(in: conversation)
    }

    func testThatItOnlyReturnsResultFromTheCorrectConversationAlreadayIndexed() {
        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()
        let otherConversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()

        let firstMessage = conversation.append(text: "This is the first message in the conversation") as! ZMMessage
        let otherMessage = otherConversation.append(text: "This is the first message in the other conversation") as! ZMMessage
        fillConversationWithMessages(conversation: conversation, messageCount: 40, normalized: true)
        fillConversationWithMessages(conversation: otherConversation, messageCount: 40, normalized: true)

        XCTAssert(uiMOC.saveOrRollback())
        XCTAssertNotNil(firstMessage.normalizedText)
        XCTAssertNotNil(otherMessage.normalizedText)
        XCTAssertEqual(conversation.allMessages.count, 41)
        XCTAssertEqual(otherConversation.allMessages.count, 41)

        // When
        let results = search(for: "in the conversation", in: conversation)

        // Then
        guard results.count == 1 else { return XCTFail("Unexpected count \(results.count)") }

        let result = results.first!
        XCTAssertFalse(result.hasMore)
        XCTAssertEqual(result.matches.count, 1)

        let match = result.matches[0]
        XCTAssertEqual(match, firstMessage)
        verifyAllMessagesAreIndexed(in: conversation)
    }

    func testThatItPopulatesTheNormalizedTextFieldAndReturnsTheQueryResults() {
        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()

        let firstMessage = conversation.append(text: "This is the first message in the conversation") as! ZMMessage
        let secondMessage = conversation.append(text: "This is the second message in the conversation") as! ZMMessage
        fillConversationWithMessages(conversation: conversation, messageCount: 400, normalized: false)
        let lastMessage = conversation.append(text: "This is the last message in the conversation") as! ZMMessage
        [firstMessage, secondMessage, lastMessage].forEach {
            $0.normalizedText = nil
        }

        XCTAssert(uiMOC.saveOrRollback())
        XCTAssertNil(firstMessage.normalizedText)
        XCTAssertNil(secondMessage.normalizedText)
        XCTAssertNil(lastMessage.normalizedText)
        XCTAssertEqual(conversation.allMessages.count, 403)

        // When
        let results = search(for: "in the conversation", in: conversation)

        // Then
        guard results.count == 3 else { return XCTFail("Unexpected count \(results.count)") }
        for result in results.dropLast() {
            XCTAssertTrue(result.hasMore)
        }

        let finalResult = results.last!
        XCTAssertFalse(finalResult.hasMore)
        XCTAssertEqual(finalResult.matches.count, 3)

        let (first, second, third) = (finalResult.matches[0], finalResult.matches[1], finalResult.matches[2])
        XCTAssertEqual(first.textMessageData?.messageText, lastMessage.textMessageData?.messageText)
        XCTAssertEqual(second.textMessageData?.messageText, secondMessage.textMessageData?.messageText)
        XCTAssertEqual(third.textMessageData?.messageText, firstMessage.textMessageData?.messageText)

        verifyAllMessagesAreIndexed(in: conversation)
    }

    func testThatItReturnsMatchesWhenAllMessagesAreIndexedInTheCorrectOrder() {
        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()

        let firstMessage = conversation.append(text: "This is the first message in the conversation") as! ZMMessage
        firstMessage.serverTimestamp = Date()
        let secondMessage = conversation.append(text: "This is the second message in the conversation") as! ZMMessage
        secondMessage.serverTimestamp = firstMessage.serverTimestamp?.addingTimeInterval(100)

        XCTAssert(uiMOC.saveOrRollback())
        XCTAssertNotNil(firstMessage.normalizedText)
        XCTAssertNotNil(secondMessage.normalizedText)
        XCTAssertEqual(conversation.allMessages.count, 2)

        // When
        let results = search(for: "in the conversation", in: conversation)

        // Then
        guard results.count == 1 else { return XCTFail("Unexpected count \(results.count)") }

        let result = results.first!
        XCTAssertFalse(result.hasMore)
        XCTAssertEqual(result.matches.count, 2)

        let (first, second) = (result.matches[0], result.matches[1])
        XCTAssertEqual(first.textMessageData?.messageText, secondMessage.textMessageData?.messageText)
        XCTAssertEqual(second.textMessageData?.messageText, firstMessage.textMessageData?.messageText)
    }

    func testThatItCallsTheDelegateWithEmptyResultsIfThereAreNoMessages() {
        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()

        // Then
        let results = search(for: "search query", in: conversation)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.matches.count, 0)
    }


    func testThatItReturnsMatchesWhenAllMessagesAreIndexed() {
        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()

        let firstMessage = conversation.append(text: "This is the first message in the conversation") as! ZMMessage
        Thread.sleep(forTimeInterval: 0.05)
        let secondMessage = conversation.append(text: "This is the second message in the conversation") as! ZMMessage
        Thread.sleep(forTimeInterval: 0.05)
        fillConversationWithMessages(conversation: conversation, messageCount: 400, normalized: true)
        let lastMessage = conversation.append(text: "This is the last message in the conversation") as! ZMMessage

        XCTAssert(uiMOC.saveOrRollback())
        XCTAssertNotNil(firstMessage.normalizedText)
        XCTAssertNotNil(secondMessage.normalizedText)
        XCTAssertNotNil(lastMessage.normalizedText)
        XCTAssertEqual(conversation.allMessages.count, 403)

        // When
        let results = search(for: "in the conversation", in: conversation)

        // Then
        guard results.count == 3 else { return XCTFail("Unexpected count \(results.count)") }

        for fetchedResult in results.dropLast() {
            XCTAssert(fetchedResult.hasMore)
        }

        let result = results.last!
        XCTAssertFalse(result.hasMore)
        XCTAssertEqual(result.matches.count, 3)

        let (first, second, third) = (result.matches[0], result.matches[1], result.matches[2])
        XCTAssertEqual(first.textMessageData?.messageText, lastMessage.textMessageData?.messageText)
        XCTAssertEqual(second.textMessageData?.messageText, secondMessage.textMessageData?.messageText)
        XCTAssertEqual(third.textMessageData?.messageText, firstMessage.textMessageData?.messageText)
    }

    func testThatItReturnsAllMatchesWhenMultipleIndexedBatchesNeedToBeFetched() {
        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()

        let firstMessage = conversation.append(text: "This is the first message in the conversation") as! ZMMessage
        let secondMessage = conversation.append(text: "This is the second message in the conversation") as! ZMMessage
        fillConversationWithMessages(conversation: conversation, messageCount: 2, normalized: true)
        let lastMessage = conversation.append(text: "This is the last message in the conversation") as! ZMMessage

        XCTAssert(uiMOC.saveOrRollback())
        XCTAssertNotNil(firstMessage.normalizedText)
        XCTAssertNotNil(secondMessage.normalizedText)
        XCTAssertNotNil(lastMessage.normalizedText)
        XCTAssertEqual(conversation.allMessages.count, 5)

        // When
        let delegate = MockTextSearchQueryDelegate()
        let configuration = TextSearchQueryFetchConfiguration(notIndexedBatchSize: 2, indexedBatchSize: 2)
        let sut = TextSearchQuery(conversation: conversation, query: "in the conversation", delegate: delegate, configuration: configuration)
        sut?.execute()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        guard delegate.fetchedResults.count == 3 else { return XCTFail("Unexpected count \(delegate.fetchedResults.count)") }

        let firstResult = delegate.fetchedResults.first!
        XCTAssertTrue(firstResult.hasMore)
        XCTAssertEqual(firstResult.matches.count, 2)

        let secondResult = delegate.fetchedResults.last!
        XCTAssertFalse(secondResult.hasMore)
        XCTAssertEqual(secondResult.matches.count, 3)

        let (first, second, third) = (firstResult.matches[0], firstResult.matches[1], secondResult.matches[2])
        XCTAssertEqual(first.textMessageData?.messageText, lastMessage.textMessageData?.messageText)
        XCTAssertEqual(second.textMessageData?.messageText, secondMessage.textMessageData?.messageText)
        XCTAssertEqual(third.textMessageData?.messageText, firstMessage.textMessageData?.messageText)
    }

    func testThatItReturnsAllMatchesIfMessagesAreNotYetAllIndexedAndIndexesNotIndexedMessages() {
        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()

        // We insert old messages that have not yet been indexed
        let firstMessage = conversation.append(text: "This is the first message in the conversation") as! ZMMessage
        fillConversationWithMessages(conversation: conversation, messageCount: 200, normalized: false)
        let secondMessage = conversation.append(text: "This is the second message in the conversation") as! ZMMessage
        fillConversationWithMessages(conversation: conversation, messageCount: 200, normalized: true)
        let lastMessage = conversation.append(text: "This is the last message in the conversation") as! ZMMessage
        [firstMessage, secondMessage].forEach {
            $0.normalizedText = nil
        }

        XCTAssert(uiMOC.saveOrRollback())
        XCTAssertNil(firstMessage.normalizedText)
        XCTAssertNil(secondMessage.normalizedText)
        XCTAssertNotNil(lastMessage.normalizedText)
        XCTAssertEqual(conversation.allMessages.count, 403)

        // When
        let results = search(for: "in the conversation", in: conversation)

        // Then
        guard results.count == 4 else { return XCTFail("Unexpected count \(results.count)") }
        for result in results.dropLast() {
            XCTAssertTrue(result.hasMore)
        }

        let finalResult = results.last!
        XCTAssertFalse(finalResult.hasMore)
        XCTAssertEqual(finalResult.matches.count, 3)

        let (first, second, third) = (finalResult.matches[0], finalResult.matches[1], finalResult.matches[2])
        XCTAssertEqual(first.textMessageData?.messageText, lastMessage.textMessageData?.messageText)
        XCTAssertEqual(second.textMessageData?.messageText, secondMessage.textMessageData?.messageText)
        XCTAssertEqual(third.textMessageData?.messageText, firstMessage.textMessageData?.messageText)

        verifyAllMessagesAreIndexed(in: conversation)
    }

    func testThatItFindsSpecialCharactersInNormalizedTextMessages() {
        verifyThatItFindsMessage(withText: "Hello Håkon", whenSearchingFor: "hakon")
        verifyThatItFindsMessage(withText: "Hello hakon", whenSearchingFor: "Håkon")
        verifyThatItFindsMessage(withText: "Hello björn", whenSearchingFor: "björn")
        verifyThatItFindsMessage(withText: "Hello björn", whenSearchingFor: "bjorn")
        verifyThatItFindsMessage(withText: "Let's meet in Saint-Étienne", whenSearchingFor: "etienne")
        verifyThatItFindsMessage(withText: "Let's meet in Saint-Etienne", whenSearchingFor: "ētienne")
        verifyThatItFindsMessage(withText: "Coração", whenSearchingFor: "Coracao")
        verifyThatItFindsMessage(withText: "Coracao", whenSearchingFor: "Coração")
        verifyThatItFindsMessage(withText: "❤️🍕", whenSearchingFor: "❤️🍕")
        verifyThatItFindsMessage(withText: "苹果", whenSearchingFor: "苹果")
        verifyThatItFindsMessage(withText: "सेवफलम्", whenSearchingFor: "सेवफलम्")
        verifyThatItFindsMessage(withText: "μήλο", whenSearchingFor: "μήλο")
        verifyThatItFindsMessage(withText: "Яблоко", whenSearchingFor: "Яблоко")
        verifyThatItFindsMessage(withText: "خطای سطح دسترسی", whenSearchingFor: "خطای سطح دسترسی")
        verifyThatItFindsMessage(withText: "תפוח", whenSearchingFor: "תפוח")
        verifyThatItFindsMessage(withText: "ᑭᒻᒥᓇᐅᔭᖅ", whenSearchingFor: "ᑭᒻᒥᓇᐅᔭᖅ")
        verifyThatItFindsMessage(withText: "aa aa aa", whenSearchingFor: "aa")
        verifyThatItFindsMessage(withText: "aa.aa", whenSearchingFor: "aa")
        verifyThatItFindsMessage(withText: "11:45", whenSearchingFor: "11:45")
        verifyThatItFindsMessage(withText: "aabb", whenSearchingFor: "aabb")
        verifyThatItFindsMessage(withText: "aabb", whenSearchingFor: "aa")
        verifyThatItFindsMessage(withText: "aabb", whenSearchingFor: "bb")
        verifyThatItFindsMessage(withText: "bb aa", whenSearchingFor: "aa")
        verifyThatItFindsMessage(withText: "aa bb", whenSearchingFor: "aa bb")
        verifyThatItFindsMessage(withText: "aabb", whenSearchingFor: "aa\nbb")
        verifyThatItFindsMessage(withText: "aa aa aa", whenSearchingFor: "aa")
        verifyThatItFindsMessage(withText: "aa bb aa", whenSearchingFor: "aa")
        verifyThatItFindsMessage(withText: "aa aa aa", whenSearchingFor: "aa aa")
        verifyThatItFindsMessage(withText: "aa.bb", whenSearchingFor: "bb")
        verifyThatItFindsMessage(withText: "aa...bb", whenSearchingFor: "bb")
        verifyThatItFindsMessage(withText: "aa.bb", whenSearchingFor: "aa")
        verifyThatItFindsMessage(withText: "aa...bb", whenSearchingFor: "aa")
        verifyThatItFindsMessage(withText: "aa-bb", whenSearchingFor: "aa-bb")
        verifyThatItFindsMessage(withText: "aa-bb", whenSearchingFor: "aa bb")
        verifyThatItFindsMessage(withText: "aa-bb", whenSearchingFor: "aa")
        verifyThatItFindsMessage(withText: "aa/bb", whenSearchingFor: "aa")
        verifyThatItFindsMessage(withText: "aa/bb", whenSearchingFor: "bb")
        verifyThatItFindsMessage(withText: "aa:bb", whenSearchingFor: "aa")
        verifyThatItFindsMessage(withText: "aa:bb", whenSearchingFor: "bb")
        verifyThatItFindsMessage(withText: "@peter", whenSearchingFor: "peter")
        verifyThatItFindsMessage(withText: "rené", whenSearchingFor: "Rene")
        verifyThatItFindsMessage(withText: "https://www.link.com/something-to-read?q=12&second#reader", whenSearchingFor: "something to read")
        verifyThatItFindsMessage(withText: "<8000 x a's>", whenSearchingFor: "<8000 x a's>")
        verifyThatItFindsMessage(withText: "bb бб bb", whenSearchingFor: "бб")
        verifyThatItFindsMessage(withText: "bb бб bb", whenSearchingFor: "bb")

    }

    func testThatItUsesANDConjunctionForSearchTerms() {
        verifyThatItFindsMessage(withText: "This is a test message", whenSearchingFor: "this message")
        verifyThatItFindsMessage(withText: "This is a test message", whenSearchingFor: "this conversation", shouldFind: false)
    }

    func testThatItDoesNotCreateASearchQueryWithQuerySmallerThanTwoCharacters() {
        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()

        // Then
        XCTAssertNil(TextSearchQuery(conversation: conversation, query: "", delegate: MockTextSearchQueryDelegate()))
        XCTAssertNil(TextSearchQuery(conversation: conversation, query: "a", delegate: MockTextSearchQueryDelegate()))
        XCTAssertNotNil(TextSearchQuery(conversation: conversation, query: "ab", delegate: MockTextSearchQueryDelegate()))
    }

    func testThatItDoesNotReturnsAnyResultsWithOnlyOneCharacterSearchTerms() {
        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()
        _ = conversation.append(text: "aa bb a b c dd") as! ZMMessage
        XCTAssert(uiMOC.saveOrRollback())

        let delegate = MockTextSearchQueryDelegate()
        guard let sut = TextSearchQuery(conversation: conversation, query: "a b c d", delegate: delegate) else {
            return XCTFail("Should have created a `TextSearchQuery`")
        }

        // When
        sut.execute()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        guard delegate.fetchedResults.count == 1 else { return XCTFail("Unexpected count \(delegate.fetchedResults.count)") }
        let result = delegate.fetchedResults.first!
        XCTAssertFalse(result.hasMore)

        XCTAssertTrue(result.matches.isEmpty, "Expected to not find a match")
    }

    func testThatItUpdatesTheNormalizedTextWhenEditingAMessage() {
        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()
        let message = conversation.append(text: "Håkon") as! ZMClientMessage
        message.markAsSent()
        XCTAssert(uiMOC.saveOrRollback())
        XCTAssertEqual(message.normalizedText, "hakon")

        // When
        message.textMessageData?.editText("Coração", mentions: [], fetchLinkPreview: false)
        XCTAssert(uiMOC.saveOrRollback())
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        XCTAssertEqual(message.normalizedText, "coracao")

        guard let originalMatches = search(for: "hakon", in: conversation).first?.matches,
              let editedMatches = search(for: "coracao", in: conversation).first?.matches else {
                return XCTFail("Unable to get matches")
        }

        XCTAssert(originalMatches.isEmpty)
        guard let editedMatch = editedMatches.first, editedMatches.count == 1 else {
            return XCTFail("Unexpected number of edited matches")
        }

        XCTAssertEqual(editedMatch, message)
    }

    func testThatItReturnsEphemeralMessagesAsSearchResults() {
        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()
        conversation.conversationType = .group
        conversation.mutableLastServerSyncedActiveParticipants.addObjects(from: [user1, user2])
        
        let message = conversation.append(text: "This is a regular message in the conversation") as! ZMMessage
        let otherMessage = conversation.append(text: "This is the another message in the conversation") as! ZMMessage
        conversation.messageDestructionTimeout = .local(MessageDestructionTimeoutValue(rawValue: 300))
        let ephemeralMessage = conversation.append(text: "This is a timed message in the conversation") as! ZMMessage

        XCTAssert(uiMOC.saveOrRollback())
        XCTAssertNotNil(message.normalizedText)
        XCTAssertNotNil(otherMessage.normalizedText)
        XCTAssertEqual(ephemeralMessage.normalizedText, "this is a timed message in the conversation")
        XCTAssertEqual(conversation.allMessages.count, 3)

        // When
        guard let ephemeralMatches = search(for: "timed", in: conversation).first?.matches,
            let firstMessageMatches = search(for: "regular message", in: conversation).first?.matches else {
                return XCTFail("Unable to get matches")
        }

        // Then
        XCTAssertFalse(ephemeralMatches.isEmpty)
        guard let messageMatch = firstMessageMatches.first, firstMessageMatches.count == 1 else {
            return XCTFail("Unexpected number of regular matches")
        }

        XCTAssertEqual(messageMatch, message)
    }

    func testThatItCanSearchForALargeMessage() {
        do {
            let longText = try String(contentsOf: fileURL(forResource: "ExternalMessageTextFixture", extension: "txt"), encoding: .utf8)
            let text = longText + "search query"
            verifyThatItFindsMessage(withText: text, whenSearchingFor: "search query")
        } catch {
            XCTFail("Unexpected error thrown: \(error)")
        }
    }

    func testThatItCanSearchForALikedMessage() {
        verifyThatItFindsMessage(withText: "search term query test", whenSearchingFor: "search query") { message in
            // When we like the message before searching
            message.markAsSent()
            _ = ZMMessage.appendReaction("❤️", toMessage: message)
        }
    }

    func testThatItCanSearchForAMessageThatHasALinkPreview() {
        verifyThatItFindsMessage(withText: "search term query test", whenSearchingFor: "search query") { message in
            // When we add a linkpreview to the message before searching
            guard let clientMessage = message as? ZMClientMessage else { return XCTFail("No client message") }
            let (title, summary, url, permanentURL) = ("title", "summary", "www.example.com/original", "www.example.com/permanent")
            let image = ZMAsset.asset(withUploadedOTRKey: Data.secureRandomData(ofLength: 16), sha256: Data.secureRandomData(ofLength: 16))
            let preview = ZMLinkPreview.linkPreview(
                withOriginalURL: url,
                permanentURL: permanentURL,
                offset: 42,
                title: title,
                summary: summary,
                imageAsset: image
            )
            
            let genericMessage = ZMGenericMessage.message(content: ZMText.text(with: message.textMessageData!.messageText!, linkPreviews: [preview]), nonce: message.nonce!)
            clientMessage.add(genericMessage.data())
            message.markAsSent()
        }
    }

    func testThatItCanSearchForAMessageThatContainsALinkWithoutPreview() {
        verifyThatItFindsMessage(withText: "Hey, check out this amazing link: www.wire.com", whenSearchingFor: "wire.com")
    }

    func testThatItDoesNotReturnAnyMessagesOtherThanTextInTheResults() {
        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()
        _ = conversation.append(location: .init(latitude: 52.520008, longitude: 13.404954, name: "Berlin, Germany", zoomLevel: 8))
        _ = conversation.append(imageFromData: mediumJPEGData())
        _ = conversation.appendKnock()
        _ = conversation.append(imageFromData: verySmallJPEGData())
        fillConversationWithMessages(conversation: conversation, messageCount: 10, normalized: true)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        verifyAllMessagesAreIndexed(in: conversation)

        // When & Then
        verifyThatItFindsMessage(
            withText: "Please check the following messages to get the whole picture!",
            whenSearchingFor: "get the picture",
            in: conversation
        )
    }

    // MARK: Helper

    func fillConversationWithMessages(conversation: ZMConversation, messageCount: Int, normalized: Bool) {
        for index in 0..<messageCount {
            let text = "This is the text message at index \(index)"
            let message = conversation.append(text: text) as! ZMMessage
            if normalized {
                message.updateNormalizedText()
            } else {
                message.normalizedText = nil
            }
        }

        uiMOC.saveOrRollback()
    }

    func verifyAllMessagesAreIndexed(in conversation: ZMConversation, file: StaticString = #file, line: UInt = #line) {
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            ZMClientMessage.predicateForNotIndexedMessages(),
            ZMClientMessage.predicateForMessages(inConversationWith: conversation.remoteIdentifier!)
        ])
        let request = ZMClientMessage.sortedFetchRequest(with: predicate)!
        let notIndexedMessageCount = (try? uiMOC.count(for: request)) ?? 0

        if notIndexedMessageCount > 0 {
            recordFailure(
                withDescription: "Found \(notIndexedMessageCount) messages in conversation",
                inFile: String(describing: file),
                atLine: Int(line),
                expected: true
            )
        }
    }

    func verifyThatItFindsMessage(
        withText text: String,
        whenSearchingFor query: String,
        shouldFind: Bool = true,
        in conversation: ZMConversation? = nil,
        file: StaticString = #file,
        line: UInt = #line,
        messageModifier: ((ZMMessage) -> Void)? = nil
        ) {

        // Given
        let conversation = conversation ?? ZMConversation.insertNewObject(in: uiMOC)
        if nil == conversation.remoteIdentifier {
            conversation.remoteIdentifier = .create()
        }
        let message = conversation.append(text: text) as! ZMMessage
        messageModifier?(message)
        XCTAssert(uiMOC.saveOrRollback(), file: file, line: line)

        // When
        let results = search(for: query, in: conversation, file: file, line: line)

        // Then
        guard results.count == 1 else { return XCTFail("Unexpected count \(results.count)", file: file, line: line) }
        let result = results.first!
        XCTAssertFalse(result.hasMore, file: file, line: line)

        if shouldFind {
            guard let match = result.matches.first else { return XCTFail("No match found", file: file, line: line) }
            XCTAssertEqual(match.textMessageData?.messageText, message.textMessageData?.messageText, file: file, line: line)
            verifyAllMessagesAreIndexed(in: conversation, file: file, line: line)
        } else {
            XCTAssertTrue(result.matches.isEmpty, "Expected to not find a match", file: file, line: line)
        }
    }

    fileprivate func search(for text: String, in conversation: ZMConversation, file: StaticString = #file, line: UInt = #line) -> [TextQueryResult] {
        let delegate = MockTextSearchQueryDelegate()
        guard let sut = TextSearchQuery(conversation: conversation, query: text, delegate: delegate) else {
            XCTFail("Unable to create a query object, ensure the query is >= 2 characters", file: file, line: line)
            return []
        }
        sut.execute()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5), file: file, line: line)
        return delegate.fetchedResults
    }

}
