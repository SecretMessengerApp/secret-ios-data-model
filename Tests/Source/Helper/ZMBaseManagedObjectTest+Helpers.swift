//
//

import Foundation

extension ZMBaseManagedObjectTest {

    func createConversation(in moc: NSManagedObjectContext) -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: moc)
        conversation.remoteIdentifier = UUID()
        conversation.conversationType = .group
        return conversation
    }

    func createTeam(in moc: NSManagedObjectContext) -> Team {
        let team = Team.insertNewObject(in: moc)
        team.remoteIdentifier = UUID()
        return team
    }

    func createUser(in moc: NSManagedObjectContext) -> ZMUser {
        let user = ZMUser.insertNewObject(in: moc)
        user.remoteIdentifier = UUID()
        return user
    }

    @discardableResult func createMembership(in moc: NSManagedObjectContext, user: ZMUser, team: Team) -> Member {
        let member = Member.insertNewObject(in: moc)
        member.user = user
        member.team = team
        return member
    }

    @discardableResult func createTeamMember(in moc: NSManagedObjectContext, for team: Team) -> ZMUser {
        let user = createUser(in: moc)
        createMembership(in:moc, user: user, team: team)
        return user
    }

    func createService(in moc: NSManagedObjectContext, named: String) -> ServiceUser {
        let serviceUser = createUser(in: moc)
        serviceUser.serviceIdentifier = UUID.create().transportString()
        serviceUser.providerIdentifier = UUID.create().transportString()
        serviceUser.name = named
        return serviceUser
    }
}
