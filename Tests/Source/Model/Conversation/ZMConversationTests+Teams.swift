//
//


import WireTesting
@testable import WireDataModel


class ConversationTests_Teams: ZMConversationTestsBase {

    var team: Team!
    var user: ZMUser!
    var member: Member!
    var otherUser: ZMUser!

    override func setUp() {
        super.setUp()

        user = .selfUser(in: uiMOC)
        team = .insertNewObject(in: uiMOC)
        member = .insertNewObject(in: uiMOC)
        otherUser = .insertNewObject(in: uiMOC)
        member.user = user
        member.team = team
        member.permissions = .member

        let otherUserMember = Member.insertNewObject(in: uiMOC)
        otherUserMember.team = team
        otherUserMember.user = otherUser

        XCTAssert(uiMOC.saveOrRollback())
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))
    }

    override func tearDown() {
        team = nil
        user = nil
        member = nil
        otherUser = nil
        super.tearDown()
    }

    func testThatItCreatesAOneToOneConversationInATeam() {
        // given
        otherUser.remoteIdentifier = .create()

        // when
        let conversation = ZMConversation.fetchOrCreateTeamConversation(in: uiMOC, withParticipant: otherUser, team: team)

        // then
        XCTAssertNotNil(conversation)
        XCTAssertEqual(conversation?.conversationType, .group)
        XCTAssertEqual(conversation?.lastServerSyncedActiveParticipants, [otherUser])
        XCTAssertEqual(conversation?.team, team)
    }

    func testThatItReturnsAnExistingOneOnOneConversationIfThereAlreadyIsOneInATeam() {
        // given
        let conversation = ZMConversation.fetchOrCreateTeamConversation(in: uiMOC, withParticipant: otherUser, team: team)
        // when
        let newConversation = ZMConversation.fetchOrCreateTeamConversation(in: uiMOC, withParticipant: otherUser, team: team)

        // then
        XCTAssertEqual(conversation, newConversation)
    }

    func testThatItDoesNotReturnAnExistingConversationFromTheSameTeamWithNoParticipants() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        conversation.team = team

        // when
        let newConversation = ZMConversation.fetchOrCreateTeamConversation(in: uiMOC, withParticipant: otherUser, team: team)

        // then
        XCTAssertNotEqual(conversation, newConversation)
    }

    func testThatItReturnsANewConversationIfAnExistingOneHasAUserDefinedName() {
        // given
        let conversation = ZMConversation.fetchOrCreateTeamConversation(in: uiMOC, withParticipant: otherUser, team: team)
        conversation?.userDefinedName = "Best Conversation"

        // when
        let newConversation = ZMConversation.fetchOrCreateTeamConversation(in: uiMOC, withParticipant: otherUser, team: team)

        // then
        XCTAssertNotEqual(conversation, newConversation)
    }

    func testThatItReturnsNotNilWhenAskedForOneOnOneConversationWithoutTeam() {
        // given
        let oneOnOne = ZMConversation.insertNewObject(in: uiMOC)
        oneOnOne.conversationType = .oneOnOne
        oneOnOne.connection = .insertNewObject(in: uiMOC)
        oneOnOne.connection?.status = .accepted
        let userOutsideTeam = ZMUser.insertNewObject(in: uiMOC)
        oneOnOne.connection?.to = userOutsideTeam

        // then
        XCTAssertEqual(userOutsideTeam.oneToOneConversation, oneOnOne)
    }

    func testThatItCreatesOneOnOneConversationInDifferentTeam() {
        // given
        let otherTeam = Team.insertNewObject(in: uiMOC)
        let otherMember = Member.insertNewObject(in: uiMOC)
        otherMember.permissions = .member
        otherMember.team = otherTeam
        otherMember.user = user
        let otherUserMember = Member.insertNewObject(in: uiMOC)
        otherUserMember.user = otherUser
        otherUserMember.team = otherTeam

        let conversation = ZMConversation.fetchOrCreateTeamConversation(in: uiMOC, withParticipant: otherUser, team: team)
        // when
        let newConversation = ZMConversation.fetchOrCreateTeamConversation(in: uiMOC, withParticipant: otherUser, team: otherTeam)

        // then
        XCTAssertNotEqual(conversation, newConversation)
    }

    func testThatItCanCreateAOneOnOneConversationWithAParticipantNotInTheTeam() {
        // given
        let userOutsideTeam = ZMUser.insertNewObject(in: uiMOC)

        // when
        let conversation = ZMConversation.fetchOrCreateTeamConversation(in: uiMOC, withParticipant: userOutsideTeam, team: team)

        // then
        XCTAssertNotNil(conversation)
        XCTAssertNil(userOutsideTeam.oneToOneConversation)
    }

    func testThatItReturnsTeamConversationForOneOnOneConversationWithTeamMember() {
        // given
        let oneOnOne = ZMConversation.insertNewObject(in: uiMOC)
        oneOnOne.conversationType = .oneOnOne
        oneOnOne.connection = .insertNewObject(in: uiMOC)
        oneOnOne.connection?.status = .accepted
        oneOnOne.connection?.to = otherUser

        // when
        let teamOneOnOne = ZMConversation.fetchOrCreateTeamConversation(in: uiMOC, withParticipant: otherUser, team: team)

        // then
        XCTAssertNotEqual(otherUser.oneToOneConversation, oneOnOne)
        XCTAssertEqual(otherUser.oneToOneConversation, teamOneOnOne)
    }

    func testThatItCreatesAConversationWithMultipleParticipantsInATeam() {
        // given
        let user1 = ZMUser.insertNewObject(in: uiMOC)
        let user2 = ZMUser.insertNewObject(in: uiMOC)

        // when
        let conversation = ZMConversation.insertGroupConversation(into: uiMOC, withParticipants: [user1, user2], in: team)

        // then
        XCTAssertNotNil(conversation)
        XCTAssertEqual(conversation?.conversationType, .group)
        XCTAssertEqual(conversation?.lastServerSyncedActiveParticipants, [user1, user2])
        XCTAssertEqual(conversation?.team, team)
    }

    func testThatItCreatesAConversationWithOnlyAGuest() {
        // given
        let (team, _) = createTeamAndMember(for: .selfUser(in: uiMOC), with: .member)
        let guest = ZMUser.insertNewObject(in: uiMOC)

        // when
        let conversation = ZMConversation.insertGroupConversation(into: uiMOC, withParticipants: [guest], in: team)
        XCTAssertNotNil(conversation)
    }


    func testThatItCreatesAConversationWithAnotherMember() {
        // given
        let (team, _) = createTeamAndMember(for: .selfUser(in: uiMOC), with: .member)
        let otherUser = ZMUser.insertNewObject(in: uiMOC)
        let otherMember = Member.insertNewObject(in: uiMOC)
        otherMember.team = team
        otherMember.user = otherUser

        // when
        let conversation = ZMConversation.insertGroupConversation(into: uiMOC, withParticipants: [otherUser], in: team)
        XCTAssertNotNil(conversation)
        XCTAssertEqual(conversation?.lastServerSyncedActiveParticipants, [otherUser])
        XCTAssertTrue(otherUser.isTeamMember)
        XCTAssertEqual(conversation?.team, team)
    }

}

// MARK: - System messages
extension ConversationTests_Teams {
    func testThatItCreatesSystemMessageWithTeamMemberLeave() {
        // given
        let (team, _) = createTeamAndMember(for: .selfUser(in: uiMOC), with: .member)
        let otherUser = ZMUser.insertNewObject(in: uiMOC)
        let otherMember = Member.insertNewObject(in: uiMOC)
        otherMember.team = team
        otherMember.user = otherUser
        let conversation = ZMConversation.insertGroupConversation(into: uiMOC, withParticipants: [otherUser], in: team)!
        let previousLastModifiedDate = conversation.lastModifiedDate!
        let timestamp = Date(timeIntervalSinceNow: 100)
        
        // when
        conversation.appendTeamMemberRemovedSystemMessage(user: otherUser, at: timestamp)
        
        // then
        guard let message = conversation.lastMessage as? ZMSystemMessage else { XCTFail("Last message should be system message"); return }
        
        XCTAssertEqual(message.systemMessageType, .teamMemberLeave)
        XCTAssertEqual(message.sender, otherUser)
        XCTAssertEqual(message.users, [otherUser])
        XCTAssertEqual(message.serverTimestamp, timestamp)
        XCTAssertFalse(message.shouldGenerateUnreadCount())
        XCTAssertEqual(conversation.lastModifiedDate, previousLastModifiedDate, "Message should not change lastModifiedDate")
    }
}

