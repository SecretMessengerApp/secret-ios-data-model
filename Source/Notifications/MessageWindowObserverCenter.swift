//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//


import Foundation

private var zmLog = ZMSLog(tag: "MessageWindowObserverCenter")

extension Notification.Name {
    static let MessageWindowDidChange = Notification.Name("MessageWindowDidChangeNotification")
}



extension NSManagedObjectContext {

    static let MessageWindowObserverCenterKey = "MessageWindowObserverCenterKey"
    
    @objc public var messageWindowObserverCenter : MessageWindowObserverCenter {
        assert(zm_isUserInterfaceContext, "MessageWindowObserverCenter does not exist in syncMOC")
        
        if let observer = userInfo[NSManagedObjectContext.MessageWindowObserverCenterKey] as? MessageWindowObserverCenter {
            return observer
        }
        
        let newObserver = MessageWindowObserverCenter()
        userInfo[NSManagedObjectContext.MessageWindowObserverCenterKey] = newObserver
        return newObserver
    }
}

@objc final public class MessageWindowObserverCenter : NSObject, ChangeInfoConsumer {
    
    var windowSnapshots : [MessageWindowSnapshot] = []
    
    private func snapshots(for window: ZMConversationMessageWindow) -> [MessageWindowSnapshot] {
        return windowSnapshots.filter { (snapshot: MessageWindowSnapshot) -> Bool in
            snapshot.conversationWindow == window
        }
    }
    
    @objc public func windowDidScroll(_ window: ZMConversationMessageWindow) {
        self.snapshots(for: window).forEach {
            $0.windowDidScroll()
        }
    }
    
    /// Creates a snapshot of the window and updates the window when changes occur
    /// It automatically tears down the old window snapshot, since there should only be one window open at any time
    /// Call this when initializing a new message window
    @objc public func windowWasCreated(_ window: ZMConversationMessageWindow) {
        zmLog.debug("WindowWasCreated - Creating snapshot for window \(window)")
        windowSnapshots.append(MessageWindowSnapshot(window: window))
    }
    
    /// Removes the windowSnapshot if there is one
    /// Call this when tearing down or deallocating the messageWindow
    @objc public func removeMessageWindow(_ window: ZMConversationMessageWindow) {
        windowSnapshots = windowSnapshots.filter {
            $0.conversationWindow != nil && $0.conversationWindow != window
        }
    }
    
    public func objectsDidChange(changes: [ClassIdentifier : [ObjectChangeInfo]]) {
        windowSnapshots.forEach { (snapshot: MessageWindowSnapshot) in
            changes.values.forEach{
                if let convChanges = $0 as? [ConversationChangeInfo] {
                    print("Conversations did change: \n \(convChanges.map{$0.customDebugDescription}.joined(separator: "\n"))")
                    convChanges.forEach{snapshot.conversationDidChange($0)}
                }
                if let userChanges = $0 as? [UserChangeInfo] {
                    zmLog.debug("Users did change: \n \(userChanges.map{$0.customDebugDescription}.joined(separator: "\n"))")
                    userChanges.forEach{snapshot.userDidChange(changeInfo: $0)}
                }
                if let messageChanges = $0 as? [MessageChangeInfo] {
                    zmLog.debug("Messages did change: \n \(messageChanges.map{$0.customDebugDescription}.joined(separator: "\n"))")
                    messageChanges.forEach{snapshot.messageDidChange($0)}
                }
            }
            
            snapshot.fireNotifications()
        }
    }
    
    public func applicationDidEnterBackground() {
        // do nothing
    }
    
    public func applicationWillEnterForeground() {
        windowSnapshots.forEach {
            $0.applicationWillEnterForeground()
        }
    }
}


class MessageWindowSnapshot : NSObject, ZMConversationObserver, ZMMessageObserver {

    fileprivate var state : SetSnapshot<ZMMessage>
    
    public weak var conversationWindow : ZMConversationMessageWindow?
    fileprivate var conversation : ZMConversation? {
        return conversationWindow?.conversation
    }
    
    fileprivate var shouldRecalculate : Bool = false
    fileprivate var updatedMessages : [ZMMessage] = []
    fileprivate var messageChangeInfos : [MessageChangeInfo] = []
    fileprivate var userChanges: [NSManagedObjectID : UserChangeInfo] = [:]
    fileprivate var userIDsInWindow : Set<NSManagedObjectID> {
        if tempUserIDsInWindow == nil {
            tempUserIDsInWindow = state.set.array.reduce(Set()){$0.union($1.allUserIDs)}
        }
        return tempUserIDsInWindow!
    }
    fileprivate var tempUserIDsInWindow : Set<NSManagedObjectID>? = nil
    
    
    var isTornDown : Bool = false
    
    fileprivate var currentlyFetchingMessages = false
    
    init(window: ZMConversationMessageWindow) {
        self.conversationWindow = window
        self.state = SetSnapshot(set: window.messages.toOrderedSetState(), moveType: .uiCollectionView)
        super.init()
    }
    
    func windowDidScroll() {
        computeChanges()
    }
    
    func fireNotifications() {
        if(shouldRecalculate || updatedMessages.count > 0) {
            computeChanges()
        }
        userChanges = [:]
    }
    
    // MARK: Forwarding Changes
    /// Processes conversationChangeInfo for conversations in window when messages changed
    func conversationDidChange(_ changeInfo: ConversationChangeInfo) {
        guard let conversation = conversation, changeInfo.conversation == conversation else { return }
        if(changeInfo.messagesChanged || changeInfo.clearedChanged || changeInfo.selfRemarkChanged || changeInfo.headerImgChanged || changeInfo.replyTypeChanged || changeInfo.lastServiceMessageChanged) {
            shouldRecalculate = true
            zmLog.debug("Recalculating window due to conversation change \(changeInfo.customDebugDescription)")
        }
    }
    
    /// Processes messageChangeInfos for messages in window when messages changed
    func messageDidChange(_ change: MessageChangeInfo) {
        guard let window = conversationWindow, window.messages.contains(change.message) else { return }
        
        updatedMessages.append(change.message)
        messageChangeInfos.append(change)
    }

    /// Processes messageChangeInfos for users who's messages are currently in the window
    func userDidChange(changeInfo: UserChangeInfo) {
        guard let user = changeInfo.user as? ZMUser,
             (changeInfo.nameChanged || changeInfo.accentColorValueChanged || changeInfo.imageMediumDataChanged || changeInfo.imageSmallProfileDataChanged)
        else { return }
        
        guard userIDsInWindow.contains(user.objectID) else { return }
        
        userChanges[user.objectID] = changeInfo
        shouldRecalculate = true
        zmLog.debug("Recalculating window due to user change \(changeInfo.customDebugDescription)")
    }
    
    
    // MARK: Change computing
    /// Compute the changes, update window and notify observers
    ///
    /// - Parameter needsReload: set to true when there might be changes that are not reflected in change info
    fileprivate func computeChanges(needsReload: Bool = false) {
        guard let window = conversationWindow else { return }
        defer {
            updatedMessages = []
            shouldRecalculate = false
        }
        
        // Recalculate message window
        window.recalculateMessages()
        
        // Calculate window changes
        let currentlyUpdatedMessages = updatedMessages
        let updatedSet = Set(currentlyUpdatedMessages.filter({$0.conversation === window.conversation}))
        
        var changeInfo : MessageWindowChangeInfo?
        if let newStateUpdate : SetStateUpdate<ZMMessage> = state.updatedState(updatedSet,
                                                                               observedObject: window,
                                                                               newSet: window.messages.toOrderedSetState())
        {
            state = newStateUpdate.newSnapshot
            changeInfo = MessageWindowChangeInfo(setChangeInfo: newStateUpdate.changeInfo)
            tempUserIDsInWindow = nil
        } else if needsReload {
            // We need to reload, just make empty change info
            let emptyChangeInfo = SetChangeInfo<ZMMessage>(observedObject: window)
            changeInfo = MessageWindowChangeInfo(setChangeInfo: emptyChangeInfo)
        }
        
        if needsReload {
            zmLog.debug("Needs reloading")
            changeInfo?.needsReload = true
        }
        
        // Notify observers
        postNotification(windowChangeInfo: changeInfo, for: window)
    }
    
    /// We receive UserChangeInfos separately and need to merge them with the messageChangeInfo in order to include userChanges
    /// This is necessary because there is no coreData relationship set between user -> messages (only the reverse) and it would be very expensive to notify for changes of messages due to a user change otherwise
    func updateMessageChangeInfos(window: ZMConversationMessageWindow) {
        messageChangeInfos.forEach{
            guard let user = $0.message.sender, let userChange = userChanges.removeValue(forKey:user.objectID) else { return }
            $0.changeInfos[MessageChangeInfo.UserChangeInfoKey] = userChange
        }
        
        guard userChanges.count > 0, let messages = window.messages.array as? [ZMMessage] else { return }
        
        let messagesToUserIDs = messages.mapToDictionary{$0.allUserIDs}
        userChanges.forEach{ (objectID, change) in
            messagesToUserIDs.forEach{ (message, userIDs) in
                guard userIDs.contains(objectID) else { return }
                
                let changeInfo = MessageChangeInfo(object: message)
                changeInfo.changeInfos[MessageChangeInfo.UserChangeInfoKey] = change
                messageChangeInfos.append(changeInfo)
            }
        }
    }
    
    /// Updates the messageChangeInfos and posts both the passed in WindowChangeInfo as well as the messageChangeInfos
    func postNotification(windowChangeInfo: MessageWindowChangeInfo?, for window: ZMConversationMessageWindow){
        defer {
            userChanges = [:]
            messageChangeInfos = []
        }

        updateMessageChangeInfos(window: window)
        
        var userInfo = [String : Any]()
        if messageChangeInfos.count > 0 {
            userInfo[MessageWindowChangeInfo.MessageChangeUserInfoKey] = messageChangeInfos
        }
        if let changeInfo = windowChangeInfo {
            userInfo[MessageWindowChangeInfo.MessageWindowChangeUserInfoKey] = changeInfo
        }
        guard !userInfo.isEmpty else {
            zmLog.debug("No changes to post for window \(window)")
            return
        }
        
        NotificationInContext(name: .MessageWindowDidChange,
                              context: window.conversation.managedObjectContext!.notificationContext,
                              object: window,
                              userInfo: userInfo)
            .post()        
        zmLog.debug(logMessage(for: messageChangeInfos, windowChangeInfo: windowChangeInfo))
    }
    
    
    public func applicationWillEnterForeground() {
        shouldRecalculate = true
        computeChanges(needsReload: true)
    }
    
    func logMessage(for messageChangeInfos: [MessageChangeInfo], windowChangeInfo: MessageWindowChangeInfo?) -> String {
        var message = "Posting notification for window \(String(describing: self.conversationWindow)) with messageChangeInfos: \n"
        message.append(messageChangeInfos.map{$0.customDebugDescription}.joined(separator: "\n"))
        
        guard let changeInfo = windowChangeInfo else { return message }
        message.append("\n MessageWindowChangeInfo: \(changeInfo.description)")
        return message
    }
}

extension ZMSystemMessage {

    override var allUserIDs : Set<NSManagedObjectID> {
        let allIDs = super.allUserIDs
        return allIDs.union((users.union(addedUsers).union(removedUsers)).map{$0.objectID})
    }
}

extension ZMMessage {
    
    @objc var allUserIDs : Set<NSManagedObjectID> {
        guard let sender = sender else { return Set()}
        return Set([sender.objectID])
    }
}

