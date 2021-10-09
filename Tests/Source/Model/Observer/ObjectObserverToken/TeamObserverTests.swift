//
//


import XCTest
@testable import WireDataModel

class TeamObserverTests: NotificationDispatcherTestBase {
    
    var teamObserver : TestTeamObserver!
    
    override func setUp() {
        super.setUp()
        teamObserver = TestTeamObserver()
    }
    
    override func tearDown() {
        teamObserver = nil
        super.tearDown()
    }
    
    var userInfoKeys : Set<String> {
        return [
            #keyPath(TeamChangeInfo.membersChanged),
            #keyPath(TeamChangeInfo.nameChanged),
            #keyPath(TeamChangeInfo.imageDataChanged)
        ]
    }
    
    func checkThatItNotifiesTheObserverOfAChange(_ team : Team, modifier: (Team) -> Void, expectedChangedFields: Set<String>, customAffectedKeys: AffectedKeys? = nil) {
        
        // given
        self.uiMOC.saveOrRollback()
        
        self.token = TeamChangeInfo.add(observer: teamObserver, for: team, managedObjectContext: self.uiMOC)
        
        // when
        modifier(team)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        self.uiMOC.saveOrRollback()
        
        // then
        let changeCount = teamObserver.notifications.count
        XCTAssertEqual(changeCount, 1)
        
        // and when
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(teamObserver.notifications.count, changeCount, "Should not have changed further once")
        
        guard let changes = teamObserver.notifications.first else { return }
        changes.checkForExpectedChangeFields(userInfoKeys: userInfoKeys,
                                             expectedChangedFields: expectedChangedFields)
    }
    
    func testThatItNotifiesTheObserverOfChangedName() {
        // given
        let team = Team.insertNewObject(in: self.uiMOC)
        team.name = "bar"
        self.uiMOC.saveOrRollback()
        
        // when
        self.checkThatItNotifiesTheObserverOfAChange(team,
                                                     modifier: { $0.name =  "foo"},
                                                     expectedChangedFields: [#keyPath(TeamChangeInfo.nameChanged)]
        )
        
    }
    
    func testThatItNotifiesTheObserverOfChangedImageData() {
        // given
        let team = Team.insertNewObject(in: self.uiMOC)
        self.uiMOC.saveOrRollback()
        
        // when
        self.checkThatItNotifiesTheObserverOfAChange(team,
                                                     modifier: { $0.imageData = "image".data(using: .utf8)! },
                                                     expectedChangedFields: [#keyPath(TeamChangeInfo.imageDataChanged)]
        )
    }

    func testThatItNotifiesTheObserverOfInsertedMembers() {
        // given
        let team = Team.insertNewObject(in: self.uiMOC)
        self.uiMOC.saveOrRollback()
        
        // when
        self.checkThatItNotifiesTheObserverOfAChange(team,
                                                     modifier: {
                                                        let member = Member.insertNewObject(in: uiMOC)
                                                        member.team = $0
        },
                                                     expectedChangedFields: [#keyPath(TeamChangeInfo.membersChanged)]
        )
    }
    
    func testThatItNotifiesTheObserverOfDeletedMembers() {
        // given
        let team = Team.insertNewObject(in: self.uiMOC)
        let member = Member.insertNewObject(in: uiMOC)
        member.team = team
        self.uiMOC.saveOrRollback()
        
        // when
        self.checkThatItNotifiesTheObserverOfAChange(team,
                                                     modifier: {
                                                        guard let member = $0.members.first else {
                                                            return XCTFail("No member? :(")
                                                        }
                                                        self.uiMOC.delete(member)
                                                        },
                                                     expectedChangedFields: [#keyPath(TeamChangeInfo.membersChanged)]
        )
    }
    
}

