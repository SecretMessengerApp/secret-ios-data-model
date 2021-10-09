//
//


import XCTest
@testable import WireDataModel

class ZMClientMessageTests_Mentions: BaseZMClientMessageTests {
    
    func createMessage(text: String, mentions: [ Mention]) -> ZMClientMessage {
        let text = ZMText.text(with: text, mentions: mentions, linkPreviews: [])
        let message = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        
        message.add(ZMGenericMessage.message(content: text).data())
        
        return message
    }
    
    func testMentionsAreReturned() {
        // given
        let text = "@john hello"
        let mention = Mention(range: NSRange(location: 0, length: 5), user: user1)
        let message = createMessage(text: text, mentions: [mention])
        
        // when
        let mentions = message.mentions
        
        // then
        XCTAssertEqual(mentions, [mention])
    }
    
    func testMentionsWithMultiplePartCharactersAreReturned() {
        // given
        let text = "@🙅‍♂️"
        let mention = Mention(range: NSRange(location: 0, length: 6), user: user1)
        
        let message = createMessage(text: text, mentions: [mention])
        
        // when
        let mentions = message.mentions
        
        // then
        XCTAssertEqual(mentions, [mention])
    }
    
    func testMentionsWithOverlappingRangesAreDiscarded() {
        // given
        let text = "@john hello"
        let mention = Mention(range: NSRange(location: 0, length: 5), user: user1)
        let mentionOverlapping = Mention(range: NSRange(location: 4, length: 5), user: user2)
        
        let message = createMessage(text: text, mentions: [mention, mentionOverlapping])
        
        // when
        let mentions = message.mentions
        
        // then
        XCTAssertEqual(mentions, [mention])
    }
    
    func testMentionsWithRangesOutsideTextAreDiscarded() {
        // given
        let text = "@john hello"
        let mention = Mention(range: NSRange(location: 0, length: 5), user: user1)
        let mentionOutsideText = Mention(range: NSRange(location: 6, length: 10), user: user2)
        
        let message = createMessage(text: text, mentions: [mention, mentionOutsideText])
        
        // when
        let mentions = message.mentions
        
        // then
        XCTAssertEqual(mentions, [mention])
    }
    
    func testMentionsIsCapppedAt500() {
        // given
        let text = String(repeating: "@", count: 501)
        let tooManyMentions = (0...500).map({ index in
            return Mention(range: NSRange(location: index, length: 1), user: user1)
        })
        let message = createMessage(text: text, mentions: tooManyMentions)
        
        // when
        let mentions = message.mentions
        
        // then
        XCTAssertEqual(mentions.count, 500)
        XCTAssertEqual(mentions, mentions)
        XCTAssertEqual(mentions, Array(tooManyMentions.prefix(500)))
    }
    
}
