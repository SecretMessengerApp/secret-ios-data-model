//
//

import Foundation
import XCTest
@testable import WireDataModel

class ConversationCreationOptionsTests: ZMConversationTestsBase {

    func testThatItCreatesTheConversationWithOptions() {
        // given
        let user = self.createUser()!
        let name = "Test Conversation In Swift"
        let team = Team.insertNewObject(in: self.uiMOC)
        let options = ConversationCreationOptions(participants: [user], name: name, team: team, allowGuests: true)
        // when
        let conversation = self.insertGroup(with: options)
        // then
        XCTAssertEqual(conversation.displayName, name)
        XCTAssertEqual(conversation.activeParticipants, Set([user, selfUser]))
        XCTAssertEqual(conversation.team, team)
        XCTAssertEqual(conversation.allowGuests, true)
    }
}

extension ConversationCreationOptionsTests: ZMManagedObjectContextProvider {
    var managedObjectContext: NSManagedObjectContext! {
        return self.uiMOC
    }
    
    var syncManagedObjectContext: NSManagedObjectContext! {
        return self.syncMOC
    }
}
