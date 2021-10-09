//
//

import Foundation

public extension ZMSystemMessage {
    @NSManaged var numberOfGuestsAdded: Int16  // Only filled for .newConversation
    @NSManaged var allTeamUsersAdded: Bool     // Only filled for .newConversation
}
