//
//

import Foundation

extension ZMConversation {
    
    static func predicateSecureWithIgnored() -> NSPredicate {
        return NSPredicate(format: "%K == %d", #keyPath(ZMConversation.securityLevel), ZMConversationSecurityLevel.secureWithIgnored.rawValue)
    }
    
    /// After changes to conversation security degradation logic we need
    /// to migrate all conversations from .secureWithIgnored to .notSecure
    /// so that users wouldn't get degratation prompts to conversations that 
    /// at any point in the past had been secure
    static func migrateAllSecureWithIgnored(in moc: NSManagedObjectContext) {
        let predicate = ZMConversation.predicateSecureWithIgnored()
        guard let request = ZMConversation.sortedFetchRequest(with: predicate) else { return }
        let allConversations = moc.executeFetchRequestOrAssert(request) as! [ZMConversation]

        for conversation in allConversations {
            conversation.securityLevel = .notSecure
        }
    }
}
