//
//


import Foundation


extension Team {

    // When moving from the initial teams implementation (multiple teams tied to one account) to
    // a multi account setup, we need to delete all local teams. Members will be deleted due to the cascade
    // deletion rule (Team → Member). Conversations will be preserved but their teams realtion will be nullified.
    static func deleteLocalTeamsAndMembers(in context: NSManagedObjectContext) {
        guard let fetchRequest = Team.sortedFetchRequest(),
              let teams = context.executeFetchRequestOrAssert(fetchRequest) as? [NSManagedObject] else { return }
        teams.forEach(context.delete)
    }

}
