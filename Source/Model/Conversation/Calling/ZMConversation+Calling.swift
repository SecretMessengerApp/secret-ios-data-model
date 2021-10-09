//
//


public extension ZMConversation {

    @discardableResult
    @objc func appendMissedCallMessage(fromUser user: ZMUser, at timestamp: Date, relevantForStatus: Bool = true) -> ZMSystemMessage {
        let associatedMessage = associatedSystemMessage(of: .missedCall, sender: user)
        
        let message = appendSystemMessage(
            type: .missedCall,
            sender: user,
            users: [user],
            clients: nil,
            timestamp: timestamp,
            relevantForStatus: relevantForStatus
        )
        
        if isArchived && mutedMessageTypes == .none {
            isArchived = false
        }
        
        associatedMessage?.addChild(message)

        managedObjectContext?.enqueueDelayedSave()
        return message
    }

    @discardableResult
    @objc func appendPerformedCallMessage(with duration: TimeInterval, caller: ZMUser) -> ZMSystemMessage {
        let associatedMessage = associatedSystemMessage(of: .performedCall, sender: caller)
        
        let message = appendSystemMessage(
            type: .performedCall,
            sender: caller,
            users: [caller],
            clients: nil,
            timestamp: Date(),
            duration: duration
        )

        if isArchived && mutedMessageTypes == .none {
            isArchived = false
        }
        
        associatedMessage?.addChild(message)

        managedObjectContext?.enqueueDelayedSave()
        return message
    }

    private func associatedSystemMessage(of type: ZMSystemMessageType, sender: ZMUser) -> ZMSystemMessage? {
        guard let lastMessage = lastMessage as? ZMSystemMessage,
              lastMessage.systemMessageType == type,
              lastMessage.sender == sender
        else { return nil }
        
        return lastMessage
    }

}


public extension ZMSystemMessage {

    func addChild(_ message: ZMSystemMessage) {
        mutableSetValue(forKey: #keyPath(ZMSystemMessage.childMessages)).add(message)
        message.visibleInConversation = nil
        message.hiddenInConversation = conversation
        
        managedObjectContext?.processPendingChanges()
    }

}
