//
//

import Foundation

extension ZMConversation {
    public class func existingConversation(in moc: NSManagedObjectContext, service: ServiceUser, team: Team?) -> ZMConversation? {
        guard let team = team else { return nil }
        guard let serviceID = service.serviceIdentifier else { return nil }
        let sameTeam = predicateForConversations(in: team)
        let groupConversation = NSPredicate(format: "%K == %d OR %K == %d", ZMConversationConversationTypeKey, ZMConversationType.group.rawValue, ZMConversationConversationTypeKey, ZMConversationType.hugeGroup.rawValue)
        let selfIsActiveMember = NSPredicate(format: "%K == YES", #keyPath(ZMConversation.isSelfAnActiveMember))
        let onlyOneOtherParticipant = NSPredicate(format: "%K.@count == 1", ZMConversationLastServerSyncedActiveParticipantsKey)
        let hasParticipantWithServiceIdentifier = NSPredicate(format: "ANY %K.%K == %@", ZMConversationLastServerSyncedActiveParticipantsKey, #keyPath(ZMUser.serviceIdentifier), serviceID)
        let noUserDefinedName = NSPredicate(format: "%K == nil", #keyPath(ZMConversation.userDefinedName))
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [sameTeam, groupConversation, selfIsActiveMember, onlyOneOtherParticipant, hasParticipantWithServiceIdentifier, noUserDefinedName])

        guard let fetchRequest = sortedFetchRequest(with: predicate) else { return nil }
        fetchRequest.fetchLimit = 1
        let result = moc.executeFetchRequestOrAssert(fetchRequest)
        return result.first as? ZMConversation
    }
}
