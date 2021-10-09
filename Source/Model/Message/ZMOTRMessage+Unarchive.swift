//
//

import Foundation

extension ZMConversation {
    fileprivate func unarchive(with message: ZMOTRMessage) {
        self.internalIsArchived = false
        
        if let _ = self.lastServerTimeStamp, let serverTimestamp = message.serverTimestamp {
            self.updateArchived(serverTimestamp, synchronize: false)
        }
    }
}

extension ZMOTRMessage {
    
    @objc(unarchiveIfNeeded:)
    func unarchiveIfNeeded(_ conversation: ZMConversation) {
        if let clearedTimestamp = conversation.clearedTimeStamp,
            let serverTimestamp = self.serverTimestamp,
            serverTimestamp.compare(clearedTimestamp) == ComparisonResult.orderedAscending {
                return
        }
        
        unarchiveIfCurrentUserIsMentionedOrQuoted(conversation)
        
        unarchiveIfNotSilenced(conversation)
    }
    
    private func unarchiveIfCurrentUserIsMentionedOrQuoted(_ conversation: ZMConversation) {
        
        if conversation.isArchived,
            let sender = self.sender,
            !sender.isSelfUser,
            let textMessageData = self.textMessageData,
            !conversation.mutedMessageTypes.contains(.mentionsAndReplies),
            textMessageData.isMentioningSelf || textMessageData.isQuotingSelf {
            conversation.unarchive(with: self)
        }
    }
    
    private func unarchiveIfNotSilenced(_ conversation: ZMConversation) {
        if conversation.isArchived, conversation.mutedMessageTypes == .none {
            conversation.unarchive(with: self)
        }
    }
}
