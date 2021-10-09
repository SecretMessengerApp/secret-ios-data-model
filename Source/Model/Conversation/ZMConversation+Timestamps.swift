//
//

import Foundation

fileprivate extension ZMConversationMessage {
    
    var serverTimestampIncludingChildMessages: Date? {
        
        if let systemMessage = self as? ZMSystemMessage {
            return systemMessage.lastChildMessageDate
        }
        
        return serverTimestamp
    }
    
}

public extension ZMMessage {
    
    static func isVisible(_ message: ZMMessage) -> Bool {
        if (message as? ZMSystemMessage)?.systemMessageType == .serviceMessage {
            return true
        }
        if let systemMessage = message as? ZMSystemMessage, let parentMessage = systemMessage.parentMessage as? ZMMessage {
            return parentMessage.visibleInConversation != nil
        } else {
            return message.visibleInConversation != nil
        }
    }
    
}

extension ZMConversation {
    
    // MARK: - Timestamps
    
    func updatePendingLastRead(_ timestamp: Date) {
        if timestamp > pendingLastReadServerTimestamp {
            pendingLastReadServerTimestamp = timestamp
        }
    }
    
    @objc
    func updateLastRead(_ timestamp: Date, synchronize: Bool = false) {
        guard let managedObjectContext = managedObjectContext else { return }
        
        if timestamp > lastReadServerTimeStamp {
            lastReadServerTimeStamp = timestamp
            
            // modified keys are set "automatically" on the uiMOC
            if synchronize && !managedObjectContext.zm_isUserInterfaceContext {
                setLocallyModifiedKeys(Set([ZMConversationLastReadServerTimeStampKey]))
            }
            
            NotificationInContext(name: ZMConversation.lastReadDidChangeNotificationName, context: managedObjectContext.notificationContext, object: self, userInfo: nil).post()
        }
    }
    
    @objc
    public func updateLastModified(_ timestamp: Date) {
        if timestamp > lastModifiedDate {
            lastModifiedDate = timestamp
        }
    }
    
    @objc
    func updateServerModified(_ timestamp: Date) {
        if timestamp > lastServerTimeStamp {
            lastServerTimeStamp = timestamp
        }
    }
    
    @objc
    func updateCleared(_ timestamp: Date, synchronize: Bool = false) {
        guard let managedObjectContext = managedObjectContext else { return }
        
        if timestamp > clearedTimeStamp {
            clearedTimeStamp = timestamp
            
            if synchronize && !managedObjectContext.zm_isMsgContext {
                setLocallyModifiedKeys(Set([ZMConversationClearedTimeStampKey]))
            }
        }
    }
    
    @objc @discardableResult
    func updateArchived(_ timestamp: Date, synchronize: Bool = false) -> Bool {
        guard let managedObjectContext = managedObjectContext else { return false }
        
        if timestamp > archivedChangedTimestamp {
            archivedChangedTimestamp = timestamp
            
            if synchronize && !managedObjectContext.zm_isMsgContext {
                setLocallyModifiedKeys([ZMConversationArchivedChangedTimeStampKey])
            }
            
            return true
        } else if timestamp == archivedChangedTimestamp {
            if synchronize {
                setLocallyModifiedKeys([ZMConversationArchivedChangedTimeStampKey])
            }
            
            return true
        }
        
        return false
    }
    
    @objc(updateMutedStatusWithPayload:)
    func updateMuted(with payload: [String: Any]) {
        guard let referenceDateAsString = payload[ZMConversationInfoOTRMutedReferenceKey] as? String,
              let referenceDate = NSDate(transport: referenceDateAsString),
              updateMuted(referenceDate as Date, synchronize: false) else {
            return
        }
        
        let mutedStatus = payload[ZMConversationInfoOTRMutedStatusValueKey] as? Int32
        let mutedLegacyFlag = payload[ZMConversationInfoOTRMutedValueKey] as? Int
        
        if let legacyFlag = mutedLegacyFlag {
            // In case both flags are set we want to respect the legacy one and only read the second bit from the new status.
            if let status = mutedStatus {
                var statusFlags = MutedMessageTypes(rawValue: status)
                if legacyFlag != 0 {
                    statusFlags.formUnion(.regular)
                }
                else {
                    statusFlags = MutedMessageTypes.none
                }
                
                self.mutedStatus = statusFlags.rawValue
            }
            else {
                self.mutedStatus = (legacyFlag == 0) ? MutedMessageTypes.none.rawValue : MutedMessageTypes.regular.rawValue
            }
        }
        else if let status = mutedStatus {
            self.mutedStatus = status
        }
    }
    
    @objc @discardableResult
    func updateMuted(_ timestamp: Date, synchronize: Bool = false) -> Bool {
        guard let managedObjectContext = managedObjectContext else { return false }
        
        if timestamp > silencedChangedTimestamp {
            silencedChangedTimestamp = timestamp
            
            if synchronize && !managedObjectContext.zm_isMsgContext {
                setLocallyModifiedKeys([ZMConversationSilencedChangedTimeStampKey])
            }
            
            return true
        } else if timestamp == silencedChangedTimestamp {
            if synchronize {
                setLocallyModifiedKeys([ZMConversationSilencedChangedTimeStampKey])
            }
            
            return true
        }
        
        return false
    }
    
    fileprivate func updateLastUnreadKnock(_ timestamp: Date?) {
        guard let timestamp = timestamp else { return lastUnreadKnockDate = nil }
        
        if timestamp > lastUnreadKnockDate {
            lastUnreadKnockDate = timestamp
        }
    }
    
    fileprivate func updateLastUnreadMissedCall(_ timestamp: Date?) {
        guard let timestamp = timestamp else { return lastUnreadMissedCallDate = nil }
        
        if timestamp > lastUnreadMissedCallDate {
            lastUnreadMissedCallDate = timestamp
        }
    }
    
    // MARK: - Update timestamps on messages events
    
    /// Update timetamps after an message has been updated or created from an update event
    @objc
    func updateTimestampsAfterUpdatingMessage(_ message: ZMMessage) {        
        guard let timestamp = message.serverTimestamp else { return }
        
        updateServerModified(timestamp)
        
        if message.shouldUpdateLastModified() {
            updateLastModified(timestamp)
        }
        
        if let sender = message.sender, sender.isSelfUser {
            // if the message was sent by the self user we don't want to send a lastRead event, since we consider this message to be already read
            updateLastRead(timestamp, synchronize: false)
        } else {
            
            if message.isKnock {
                updateLastUnreadMissedCall(nil)
                updateLastUnreadKnock(message.serverTimestamp)
            } else if let textMessageData = message.textMessageData, textMessageData.isMentioningSelf {
                internalEstimatedUnreadSelfMentionCount += 1
            } else if let textMessageData = message.textMessageData, textMessageData.isQuotingSelf {
                internalEstimatedUnreadSelfReplyCount += 1
            } else if message.shouldGenerateUnreadCount() {
                internalEstimatedUnreadCount += 1
            }
        }
        
        if message.shouldGenerateLastVisibleMessage(),
            message.hiddenInConversation == nil && message.visibleInConversation == self {
            if self.lastVisibleMessage?.serverTimestamp < message.serverTimestamp {
                self.lastVisibleMessage = message
            }
        }
//        calculateLastUnreadMessages()
    }
    
    /// Update timetamps after an message has been inserted locally by the self user
    @objc
    func updateTimestampsAfterInsertingMessage(_ message: ZMMessage) {
        guard let timestamp = message.serverTimestamp else { return }
        
        if message.shouldUpdateLastModified() {
            updateLastModified(timestamp)
        }
        
        if message.isSystem, let systemMessage = message as? ZMSystemMessage, systemMessage.systemMessageType == .missedCall {
            updateLastUnreadKnock(nil)
            updateLastUnreadMissedCall(message.serverTimestamp)
        }
        
        if message.shouldGenerateLastVisibleMessage(),
            message.hiddenInConversation == nil && message.visibleInConversation == self {
            guard self.lastVisibleMessage?.serverTimestamp > message.serverTimestamp else {
                self.lastVisibleMessage = message
                return
            }
        }
        //calculateLastUnreadMessages()
    }
    
    /// Update timetamps after an message has been deleted
    @objc
    func updateTimestampsAfterDeletingMessage() {
        // If an unread message is deleted we must re-calculate the unread messages.
//        calculateLastUnreadMessages()
    }
    
    // MARK: - Mark as read
    
    @objc(markMessagesAsReadUntil:)
    public func markMessagesAsRead(until message: ZMConversationMessage) {
        if let currentTimestamp = lastReadServerTimeStamp,
           let messageTimestamp = message.serverTimestamp,
           currentTimestamp.compare(messageTimestamp) == .orderedDescending {
            // Current last read timestamp is newer than message we are marking as read
            return
        }
        // Any unsent unread message is cleared when entering a conversation
//        if hasUnreadUnsentMessage {
//            hasUnreadUnsentMessage = false
//        }
        

        guard let messageTimestamp = message.serverTimestamp else { return }
        enqueueUpdateLastRead(messageTimestamp)
    }
    
    /// Update the last read timestamp.
    ///
    /// NOTE: This method only has an effect when called from the UI context and it's throttled so it's fine to call it repeatedly.
    fileprivate func enqueueUpdateLastRead(_ timestamp: Date) {
        guard let managedObjectContext = managedObjectContext else { return }
        
        updatePendingLastRead(timestamp)
        self.savePendingLastRead()
//        lastReadTimestampUpdateCounter += 1
//        let currentCount: Int64 = lastReadTimestampUpdateCounter
//        let groups = managedObjectContext.enterAllGroups()
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + lastReadTimestampSaveDelay) { [weak self] in
//            guard currentCount == self?.lastReadTimestampUpdateCounter else { return managedObjectContext.leaveAllGroups(groups) }
//
//            self?.savePendingLastRead()
//            managedObjectContext.leaveAllGroups(groups)
//        }
   
        let conversationID = self.objectID
        guard let syncContext = managedObjectContext.zm_sync else { return }
        syncContext.performGroupedBlock {
            guard let syncObject = try? syncContext.existingObject(with: conversationID), let syncConversation = syncObject as? ZMConversation else {
                return
            }
            syncConversation.updateLastUnreadKnock(nil)
            syncConversation.updateLastUnreadMissedCall(nil)
            syncConversation.internalEstimatedUnreadSelfMentionCount = 0
            syncConversation.internalEstimatedUnreadSelfReplyCount = 0
            syncConversation.internalEstimatedUnreadCount = 0
        }
    }
    
    @objc
    public func savePendingLastRead() {
        guard let timestamp = pendingLastReadServerTimestamp else { return }
        updateLastRead(timestamp, synchronize: false)
        confirmUnreadMessagesAsRead(until: timestamp)
        pendingLastReadServerTimestamp = nil
        lastReadTimestampUpdateCounter = 0
        managedObjectContext?.enqueueDelayedSave()
    }
    
    /// Mark all messages in the conversation as read
    @objc
    public func markAsRead() {
        guard let timestamp = lastServerTimeStamp else { return }
        
        enqueueUpdateLastRead(timestamp)
    }
    
    /// Calculates the the last unread knock, missed call and total unread unread count. This should be re-calculated
    /// when the last read timetamp changes or a message is inserted / deleted.
    @objc
    func calculateLastUnreadMessages() {
        guard let managedObjectContext = managedObjectContext, !managedObjectContext.zm_isUserInterfaceContext else { return } // We only calculate unread message on the sync MOC
        
        let messages = unreadMessagesIncludingInvisible().filter(ZMMessage.isVisible)
        var lastKnockDate: Date? = nil
        var lastMissedCallDate: Date? = nil
        var unreadCount: Int64 = 0
        var unreadSelfMentionCount: Int64 = 0
        var unreadSelfReplyCount: Int64 = 0
        
        for message in messages {
            if message.isKnock {
                lastKnockDate = message.serverTimestamp
            }
            
            if message.isSystem, let systemMessage = message as? ZMSystemMessage, systemMessage.systemMessageType == .missedCall {
                lastMissedCallDate = message.serverTimestamp
            }
            
            if let textMessageData = message.textMessageData {
                if textMessageData.isMentioningSelf {
                    unreadSelfMentionCount += 1
                }
                if textMessageData.isQuotingSelf {
                    unreadSelfReplyCount += 1
                }
            }
            
            if message.shouldGenerateUnreadCount() {
                unreadCount += 1
            }
        }
        
        updateLastUnreadKnock(lastKnockDate)
        updateLastUnreadMissedCall(lastMissedCallDate)
        internalEstimatedUnreadCount = unreadCount
        internalEstimatedUnreadSelfMentionCount = unreadSelfMentionCount
        internalEstimatedUnreadSelfReplyCount = unreadSelfReplyCount
    }
    
    /// Returns the first unread message in a converation. If the first unread message is child message of system message the parent message will be returned.
//    @objc
//    public var firstUnreadMessage: ZMConversationMessage? {
//        let replaceChildWithParent: (ZMMessage) -> ZMMessage = { message in
//            if let systemMessage = message as? ZMSystemMessage, let parentMessage = systemMessage.parentMessage as? ZMMessage {
//                return parentMessage
//            } else {
//                return message
//            }
//        }
//
//        return unreadMessagesIncludingInvisible().lazy.map(replaceChildWithParent).filter({ $0.visibleInConversation != nil }).first(where: { $0.shouldGenerateUnreadCount() })
//    }
    
    // Returns first unread message mentioning the self user
    public var firstUnreadMessageMentioningSelf: ZMConversationMessage? {
        return unreadMessages.first(where: { $0.textMessageData?.isMentioningSelf ?? false })
    }
    
    /// Returns all unread messages. This may contain unread child messages of a system message which aren't directly visible in the conversation.
    @objc
    public var unreadMessages: [ZMConversationMessage] {
        return unreadMessagesIncludingInvisible().filter(ZMMessage.isVisible)
    }
    
    internal func unreadMessages(until timestamp: Date = .distantFuture) -> [ZMMessage] {
        return unreadMessagesIncludingInvisible(until: timestamp).filter(ZMMessage.isVisible)
    }
    
    internal func unreadMessagesIncludingInvisible(until timestamp: Date = Date.distantFuture) -> [ZMMessage] {
        guard let managedObjectContext = managedObjectContext else { return [] }
        
        let lastReadServerTimestamp = lastReadServerTimeStamp
        let selfUser = ZMUser.selfUser(in: managedObjectContext)
        let fetchRequest = NSFetchRequest<ZMMessage>(entityName: ZMMessage.entityName())
        fetchRequest.predicate = NSPredicate(format: "%K == %@",
                                             ZMMessageConversationKey, self)
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: ZMMessageServerTimestampKey, ascending: false)]
        
        fetchRequest.fetchLimit = 100
        
        func fetch(request: NSFetchRequest<ZMMessage>) -> [ZMMessage] {
            let messages = managedObjectContext.fetchOrAssert(request: request)
            guard let lastTimestamp = lastReadServerTimestamp else {return messages}
            if request.fetchLimit == 10000 {
                return messages
            }
            if lastTimestamp < messages.last?.serverTimestamp {
                request.fetchLimit = request.fetchLimit * 10
                return fetch(request: request)
            }
            return messages
        }
        
        let messages = fetch(request: fetchRequest)
        
        return messages.filter({$0.serverTimestamp > lastReadServerTimestamp}).filter({$0.sender != selfUser}).filter({ $0.shouldGenerateUnreadCount() })
    }
}

extension ZMMessage {
    func isInConversation(conversation: ZMConversation) -> Bool {
        guard let conv = self.conversation else {return false}
        return conv == conversation
    }
}
