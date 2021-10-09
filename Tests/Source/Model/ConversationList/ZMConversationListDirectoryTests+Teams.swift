//
//

import Foundation


final class ZMConversationListDirectoryTests_Teams: ZMBaseManagedObjectTest {

    var team: Team!
    var otherTeam: Team!
    var teamConversation1: ZMConversation!
    var teamConversation2: ZMConversation!
    var archivedTeamConversation: ZMConversation!
    var clearedTeamConversation: ZMConversation!
    var otherTeamConversation: ZMConversation!
    var otherTeamArchivedConversation: ZMConversation!
    var conversationWithoutTeam: ZMConversation!

    override func setUp() {
        super.setUp()

        team = Team.insertNewObject(in: uiMOC)
        team.remoteIdentifier = .create()
        otherTeam = Team.insertNewObject(in: uiMOC)
        otherTeam.remoteIdentifier = .create()
        teamConversation1 = createGroupConversation(in: team)
        teamConversation2 = createGroupConversation(in: team)
        otherTeamConversation = createGroupConversation(in: otherTeam)
        archivedTeamConversation = createGroupConversation(in: team, archived: true)
        otherTeamArchivedConversation = createGroupConversation(in: otherTeam, archived: true)
        clearedTeamConversation = createGroupConversation(in: team, archived: true)
        clearedTeamConversation.clearedTimeStamp = clearedTeamConversation.lastServerTimeStamp
        conversationWithoutTeam = createGroupConversation(in: nil)
    }

    override func tearDown() {
        team = nil
        otherTeam = nil
        teamConversation1 = nil
        teamConversation2 = nil
        archivedTeamConversation = nil
        clearedTeamConversation = nil
        otherTeamConversation = nil
        otherTeamArchivedConversation = nil
        conversationWithoutTeam = nil
        super.tearDown()
    }

    func testThatItReturnsConversationsInATeam() {
        // given
        let sut = uiMOC.conversationListDirectory()

        // when
        let conversations = sut.conversationsIncludingArchived

        // then
        XCTAssertEqual(conversations.setValue, [teamConversation1, teamConversation2, archivedTeamConversation, conversationWithoutTeam, otherTeamConversation, otherTeamArchivedConversation])
    }

    func testThatItReturnsArchivedConversationsInATeam() {
        // given
        let sut = uiMOC.conversationListDirectory()

        // when
        let conversations = sut.archivedConversations

        // then
        XCTAssertEqual(conversations.setValue, [archivedTeamConversation, otherTeamArchivedConversation])
    }

    func testThatItReturnsClearedConversationsInATeam() {
        // given
        let sut = uiMOC.conversationListDirectory()

        // when
        let conversations = sut.clearedConversations

        // then
        XCTAssertEqual(conversations.setValue, [clearedTeamConversation])
    }

    func testThatItDoesNotIncludeClearedConversationsInConversationsIncludingArchived() {
        // given
        let sut = uiMOC.conversationListDirectory()

        // when
        let conversations = sut.conversationsIncludingArchived

        // then
        XCTAssertFalse(conversations.setValue.contains(clearedTeamConversation))
    }

    // MARK: - Helper

    func createGroupConversation(in team: Team?, archived: Bool = false) -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.lastServerTimeStamp = Date()
        conversation.lastReadServerTimeStamp = conversation.lastServerTimeStamp
        conversation.remoteIdentifier = .create()
        conversation.team = team
        conversation.isArchived = archived
        conversation.conversationType = .group
        return conversation
    }

}


fileprivate extension ZMConversationList {

    var setValue: Set<ZMConversation> {
        return Set(self as! [ZMConversation])
    }

}
