//
//

import Foundation

extension ZMConversation {
    public var visibleMessagesPredicate: NSPredicate? {
        var allPredicates: [NSPredicate] = []
        
        if let clearedTimeStamp = self.clearedTimeStamp {
            // This must filter out:
            // 1. Messages that are older than clearedTimeStamp.
            // 2. But NOT the messages that are pending, i.e. still can be uploaded.
            let deliveryIsPendingPredicate = NSPredicate(format: "%K == NO AND %K == NO", #keyPath(ZMMessage.isExpired), #keyPath(ZMOTRMessage.delivered))
            let messageIsNotCleared = NSPredicate(format: "%K > %@", #keyPath(ZMMessage.serverTimestamp), clearedTimeStamp as CVarArg)
            allPredicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: [deliveryIsPendingPredicate, messageIsNotCleared]))
        }
        
        allPredicates.append(NSPredicate(format: "%K == %@", #keyPath(ZMMessage.visibleInConversation), self))
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: allPredicates)
    }
}

extension ZMConversation {

    /// Returns a list of the most recent messages in the conversation, ordered from most recent to oldest.
    @objc public func lastMessages(limit: Int = 256) -> [ZMMessage] {
        guard let managedObjectContext = managedObjectContext else { return [] }
        
        let fetchRequest = NSFetchRequest<ZMMessage>(entityName: ZMMessage.entityName())
        fetchRequest.fetchLimit = limit
        fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(ZMMessage.visibleInConversation), self)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(ZMMessage.serverTimestamp), ascending: false)]
        
        return managedObjectContext.fetchOrAssert(request: fetchRequest)
    }
    
    /// Returns the most recent message in the conversation.
    @objc public var lastMessage: ZMMessage? {
        return lastMessages(limit: 1).first
    }
    
    /// Returns the most recent message sent by a particular user in the conversation.
    public func lastMessageSent(by user: ZMUser) -> ZMMessage? {
        let fetchRequest = NSFetchRequest<ZMMessage>(entityName: ZMMessage.entityName())
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "%K == %@ AND %K == %@", #keyPath(ZMMessage.visibleInConversation), self, #keyPath(ZMMessage.sender), user)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(ZMMessage.serverTimestamp), ascending: false)]
        
        return self.managedObjectContext?.fetchOrAssert(request: fetchRequest).first
    }
    
}
