//
//

import Foundation
@testable import WireDataModel

class ZMConversationTests_Services : BaseZMMessageTests {

    var team: Team!
    var service: ServiceUser!
    var user: ZMUser!

    override func setUp() {
        super.setUp()
        team = createTeam(in: uiMOC)
        service = createService(in: uiMOC, named: "Botty")
        user = createUser(in: uiMOC)
    }

    override func tearDown() {
        super.tearDown()
        team = nil
        service = nil
        user = nil
    }

    func createConversation(with service: ServiceUser) -> ZMConversation {
        let conversation = createConversation(in: uiMOC)
        conversation.team = team
        conversation.conversationType = .group
        conversation.isSelfAnActiveMember = true
        conversation.internalAddParticipants([service as! ZMUser])
        return conversation
    }

    func testThatConversationIsNotFoundWhenThereIsNoTeam() {
        // when
        let conversation = ZMConversation.existingConversation(in: uiMOC, service: service, team: nil)

        // then
        XCTAssertNil(conversation)
    }

    func testThatConversationIsNotFoundWhenUserIsNotAService() {
        // when
        let conversation = ZMConversation.existingConversation(in: uiMOC, service: user, team: team)

        // then
        XCTAssertNil(conversation)
    }

    func testThatItFindsConversationWithService() {
        // given
        let existingConversation = createConversation(with: service)

        // when
        let conversation = ZMConversation.existingConversation(in: uiMOC, service: service, team: team)

        // then
        XCTAssertNotNil(conversation)
        XCTAssertEqual(existingConversation, conversation)
    }

    func testThatItDoesNotFindConversationWithMoreMembers() {
        // given
        let existingConversation = createConversation(with: service)
        existingConversation.internalAddParticipants([createUser(in: uiMOC)])

        // when
        let conversation = ZMConversation.existingConversation(in: uiMOC, service: service, team: team)

        // then
        XCTAssertNil(conversation)
    }

    func testThatItChecksOnlyConversationsWhereIAmPresent() {
        // given
        let existingConversation = createConversation(with: service)

        // when
        existingConversation.isSelfAnActiveMember = false
        let conversation = ZMConversation.existingConversation(in: uiMOC, service: service, team: team)

        // then
        XCTAssertNil(conversation)
    }

    func testThatItChecksOnlyConversationsWithNoUserDefinedName() {
        // given
        let existingConversation = createConversation(with: service)

        // when
        existingConversation.userDefinedName = "First"
        let conversation = ZMConversation.existingConversation(in: uiMOC, service: service, team: team)

        // then
        XCTAssertNil(conversation)
    }


    func testThatItFindsConversationWithCorrectService() {
        // given
        let existingConversation = createConversation(with: service)
        _ = createConversation(with: createService(in: uiMOC, named: "BAD"))

        // when
        let conversation = ZMConversation.existingConversation(in: uiMOC, service: service, team: team)

        // then
        XCTAssertNotNil(conversation)
        XCTAssertEqual(existingConversation, conversation)
    }

}
