//
//


import Foundation

extension ZMOTRMessage {
    
    /// Whether the message caused security level degradation (from verified to unverified)
    /// in this user session (i.e. since the app was started. This will be kept in memory
    /// and not persisted). This flag can be set only from the sync context. It can be read
    /// from any context.
    override public var causedSecurityLevelDegradation : Bool {
        get {
            guard let conversation = self.conversation, let moc = self.managedObjectContext else { return false }
            let messagesByConversation = moc.messagesThatCausedSecurityLevelDegradationByConversation
            guard let messages = messagesByConversation[conversation.objectID] else { return false }
            return messages.contains(self.objectID)
        }
        set {
            guard let conversation = self.conversation, let moc = self.managedObjectContext else { return }
            guard !moc.zm_isUserInterfaceContext else { fatal("Cannot mark message as degraded security on non-sync moc") }
            
            // make sure it's persisted
            if self.objectID.isTemporaryID {
                try! moc.obtainPermanentIDs(for: [self])
            }
            if conversation.objectID.isTemporaryID {
                try! moc.obtainPermanentIDs(for: [conversation])
            }
            
            // set
            var dictionary = moc.messagesThatCausedSecurityLevelDegradationByConversation
            var messagesForConversation = dictionary[conversation.objectID] ?? Set()
            if newValue {
                messagesForConversation.insert(self.objectID)
            } else {
                messagesForConversation.remove(self.objectID)
            }
            if messagesForConversation.isEmpty {
                dictionary.removeValue(forKey: conversation.objectID)
            } else {
                dictionary[conversation.objectID] = messagesForConversation
            }
            moc.messagesThatCausedSecurityLevelDegradationByConversation = dictionary
            moc.zm_hasUserInfoChanges = true
        }
    }
}

extension ZMConversation {
    
    /// List of messages that were not sent because of security level degradation in the conversation
    /// in this user session (i.e. since the app was started. This will be kept in memory
    /// and not persisted).
    public var messagesThatCausedSecurityLevelDegradation : [ZMOTRMessage] {
        guard let moc = self.managedObjectContext else { return [] }
        guard let messageIds = moc.messagesThatCausedSecurityLevelDegradationByConversation[self.objectID] else { return [] }
        return messageIds.compactMap {
            (try? moc.existingObject(with: $0)) as? ZMOTRMessage
        }
    }
    
    public func clearMessagesThatCausedSecurityLevelDegradation() {
        guard let moc = self.managedObjectContext else { return }
        var currentMessages = moc.messagesThatCausedSecurityLevelDegradationByConversation
        if let _ = currentMessages.removeValue(forKey: self.objectID) {
            moc.messagesThatCausedSecurityLevelDegradationByConversation = currentMessages
        }
    }
}

private let messagesThatCausedSecurityLevelDegradationKey = "ZM_messagesThatCausedSecurityLevelDegradation"

typealias SecurityDegradingMessagesByConversation = [NSManagedObjectID : Set<NSManagedObjectID>]

extension NSManagedObjectContext {
    
    /// Non-persisted list of messages that caused security level degradation, indexed by conversation
    fileprivate(set) var messagesThatCausedSecurityLevelDegradationByConversation : SecurityDegradingMessagesByConversation {
        get {
            return self.userInfo[messagesThatCausedSecurityLevelDegradationKey] as? SecurityDegradingMessagesByConversation ?? SecurityDegradingMessagesByConversation()
        }
        set {
            self.userInfo[messagesThatCausedSecurityLevelDegradationKey] = newValue
            self.zm_hasUserInfoChanges = true
        }
    }
    
    /// Merge list of messages that caused security level degradation from one context to another
    func mergeSecurityLevelDegradationInfo(fromUserInfo userInfo: [String: Any]) {
        guard self.zm_isUserInterfaceContext else { return } // we don't merge anything to sync, sync is autoritative
        let valuesToMerge = userInfo[messagesThatCausedSecurityLevelDegradationKey] as? SecurityDegradingMessagesByConversation
        self.messagesThatCausedSecurityLevelDegradationByConversation = valuesToMerge ?? SecurityDegradingMessagesByConversation()
    }
}
