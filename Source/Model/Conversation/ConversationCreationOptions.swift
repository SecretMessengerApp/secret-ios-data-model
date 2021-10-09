//
//

import Foundation

public struct ConversationCreationOptions {
    var participants: [ZMUser] = []
    var name: String? = nil
    var team: Team? = nil
    var allowGuests: Bool = true
    
    public init(participants: [ZMUser] = [], name: String? = nil, team: Team? = nil, allowGuests: Bool = true) {
        self.participants = participants
        self.name = name
        self.team = team
        self.allowGuests = allowGuests
    }
}

public extension ZMManagedObjectContextProvider {
    func insertGroup(with options: ConversationCreationOptions) -> ZMConversation {
        return ZMConversation.insertGroupConversation(intoUserSession: self,
                                                      withParticipants: options.participants,
                                                      name: options.name,
                                                      in: options.team,
                                                      allowGuests: options.allowGuests)
    }
}
