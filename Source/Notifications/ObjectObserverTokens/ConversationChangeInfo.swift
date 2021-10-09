//
// 


import Foundation

extension ZMConversation : ObjectInSnapshot {
    
    @objc public static var observableKeys : Set<String> {
        return Set([#keyPath(ZMConversation.allMessages),
                    #keyPath(ZMConversation.lastModifiedDate),
                    #keyPath(ZMConversation.isArchived),
                    #keyPath(ZMConversation.conversationListIndicator),
                    #keyPath(ZMConversation.mutedStatus),
                    #keyPath(ZMConversation.securityLevel),
                    #keyPath(ZMConversation.displayName),
                    #keyPath(ZMConversation.estimatedUnreadCount),
                    #keyPath(ZMConversation.clearedTimeStamp),
                    #keyPath(ZMConversation.lastServerSyncedActiveParticipants),
                    #keyPath(ZMConversation.isSelfAnActiveMember),
                    #keyPath(ZMConversation.relatedConnectionState),
                    #keyPath(ZMConversation.team),
                    #keyPath(ZMConversation.accessModeStrings),
                    #keyPath(ZMConversation.accessRoleString),
                    #keyPath(ZMConversation.remoteIdentifier),
                    #keyPath(ZMConversation.localMessageDestructionTimeout),
                    #keyPath(ZMConversation.syncedMessageDestructionTimeout),
                    #keyPath(ZMConversation.language),
                    //new add
                    #keyPath(ZMConversation.showMemsum),
                    #keyPath(ZMConversation.enabledEditMsg),
                    #keyPath(ZMConversation.blockWarningMessageTimeStamp),
                    #keyPath(ZMConversation.blocked),
                    #keyPath(ZMConversation.groupImageSmallKey),
                    #keyPath(ZMConversation.groupImageMediumKey),
                    #keyPath(ZMConversation.autoReply),
                    #keyPath(ZMConversation.isOpenUrlJoin),
                    #keyPath(ZMConversation.isOnlyCreatorInvite),
                    #keyPath(ZMConversation.isAllowViewMembers),
                    #keyPath(ZMConversation.isOpenCreatorInviteVerify),
                    #keyPath(ZMConversation.isOpenMemberInviteVerify),
                    #keyPath(ZMConversation.creatorChangeTimestamp),
//                    #keyPath(ZMConversation.isEnabledEditPersonalMsg),
//                    #keyPath(ZMConversation.enabledEditPersonalMsgTimeStamp),
//                    #keyPath(ZMConversation.selfRemark),
                    #keyPath(ZMConversation.selfRemarkChangeTimestamp),
                    #keyPath(ZMConversation.communityID),
                    #keyPath(ZMConversation.isPlacedTop),
                    #keyPath(ZMConversation.isDisableSendMsg),
                    #keyPath(ZMConversation.disableSendLastModifiedDate),
                    #keyPath(ZMConversation.lastServiceMessageTimeStamp),
                    #keyPath(ZMConversation.orator),
                    #keyPath(ZMConversation.manager),
                    #keyPath(ZMConversation.isNotDisturb),
                    #keyPath(ZMConversation.conversationType),
                    #keyPath(ZMConversation.isMessageVisibleOnlyManagerAndCreator),
                    #keyPath(ZMConversation.announcement),
                    #keyPath(ZMConversation.hasReadReceiptsEnabled),
                    ZMConversation.externalParticipantsStateKey,
//                    #keyPath(ZMConversation.legalHoldStatus),
                    #keyPath(ZMConversation.labels),
                    #keyPath(ZMConversation.remoteIdentifier),
                    #keyPath(ZMConversation.isOpenScreenShot)
            ])
    }

    public var notificationName: Notification.Name {
        return .ConversationChange
    }

}


////////////////////
////
//// ConversationObserverToken
//// This can be used for observing only conversation properties
////
////////////////////


@objcMembers public final class ConversationChangeInfo : ObjectChangeInfo {

//    public var isEnabledEditPersonalMsgChanged: Bool {
//        return changedKeysContain(keys: #keyPath(ZMConversation.isEnabledEditPersonalMsg))
//    }
    

//    public var enabledEditPersonalMsgTimeStampChanged: Bool {
//        return changedKeysContain(keys: #keyPath(ZMConversation.enabledEditPersonalMsgTimeStamp))
//    }
    
    public var enabledEditMsgChanged: Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.enabledEditMsg))
    }

    public var showMemsumChanged: Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.showMemsum))
    }
   
    public var blockWarningMessageChanged: Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.blockWarningMessageTimeStamp))
    }
    
    public var blockedChanged: Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.blocked))
    }
 
    public var previewAvatarDataChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.groupImageSmallKey), #keyPath(ZMConversation.previewAvatarData))
    }
    

    public var completeAvatarDataChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.groupImageMediumKey), #keyPath(ZMConversation.completeAvatarData))
    }
    
  
    public var announcementChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.announcement))
    }
    

    public var isMessageVisibleOnlyManagerAndCreatorStatusChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.isMessageVisibleOnlyManagerAndCreator))
    }

    public var placeTopStatusChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.isPlacedTop))
    }
    
    
    public var notDisturbStatusChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.isNotDisturb))
    }
    
    public var communityIDChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.communityID))
    }
    

    public var replyTypeChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.autoReply))
    }
    

    public var canOpenUrlChanged: Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.isOnlyCreatorInvite)) ||
               changedKeysContain(keys: #keyPath(ZMConversation.isOpenCreatorInviteVerify))
    }

    public var onlyCreatorInviteChanged: Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.isOnlyCreatorInvite))
    }

    public var isOpenScreenShotChanged: Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.isOpenScreenShot))
    }
    

    public var disableSendMsgChanged: Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.isDisableSendMsg))
    }

    public var lastServiceMessageChanged: Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.lastServiceMessageTimeStamp))
    }
  
    public var disableSendMsgLastModifiedDateChanged: Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.disableSendLastModifiedDate))
    }
   
    public var isOpenInviteVerifyChanged: Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.isOpenCreatorInviteVerify))
    }

    public var oratorChanged: Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.orator))
    }

    public var managersChanged: Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.manager))
    }
    
   
    public var groupCreatorChanged: Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.creatorChangeTimestamp))
    }
    
   
    public var remoteIdentifierChanged: Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.remoteIdentifier))
    }
    
    public var groupTypeChanged: Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.conversationType))
    }
    
    public var openUrlChanged: Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.isOpenUrlJoin))
    }
    
    public var allowViewMembers: Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.isAllowViewMembers))
    }
    
    // new add
    public var selfRemarkChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.selfRemarkChangeTimestamp))
    }
    
    public var languageChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.language))
    }

    public var messagesChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.allMessages))
    }

    public var participantsChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.lastServerSyncedActiveParticipants), #keyPath(ZMConversation.isSelfAnActiveMember))
    }

    public var nameChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.displayName))
    }

    public var lastModifiedDateChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.lastModifiedDate))
    }

    public var unreadCountChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.estimatedUnreadCount))
    }

    public var connectionStateChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.relatedConnectionState))
    }

    public var isArchivedChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.isArchived))
    }

    public var mutedMessageTypesChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.mutedStatus))
    }

    public var conversationListIndicatorChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.conversationListIndicator))
    }

    public var clearedChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.clearedTimeStamp))
    }

    public var teamChanged: Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.team))
    }

    public var securityLevelChanged : Bool {
        return changedKeysContain(keys: SecurityLevelKey)
    }
        
    public var createdRemotelyChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.remoteIdentifier))
    }
    
    public var allowGuestsChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.accessModeStrings)) ||
               changedKeysContain(keys: #keyPath(ZMConversation.accessRoleString))
    }
    
    public var destructionTimeoutChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.localMessageDestructionTimeout)) ||
                changedKeysContain(keys: #keyPath(ZMConversation.syncedMessageDestructionTimeout))
    }
    
    public var hasReadReceiptsEnabledChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.hasReadReceiptsEnabled))
    }

    public var externalParticipantsStateChanged: Bool {
        return changedKeysContain(keys: ZMConversation.externalParticipantsStateKey)
    }

    public var legalHoldStatusChanged: Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.legalHoldStatus))
    }
    
    public var labelsChanged: Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.labels))
    }
    
    public var conversation : ZMConversation { return self.object as! ZMConversation }
    
    public override var description : String { return self.debugDescription }
    public override var debugDescription : String {
        return ["replyTypeChanged: \(replyTypeChanged)",
                "messagesChanged: \(messagesChanged)",
                "previewAvatarDataChanged: \(previewAvatarDataChanged)",
                "completeAvatarDataChanged: \(completeAvatarDataChanged)",
                "canOpenUrlChanged: \(canOpenUrlChanged)",
                "participantsChanged: \(participantsChanged)",
                "nameChanged: \(nameChanged)",
                "unreadCountChanged: \(unreadCountChanged)",
                "lastModifiedDateChanged: \(lastModifiedDateChanged)",
                "connectionStateChanged: \(connectionStateChanged)",
                "isArchivedChanged: \(isArchivedChanged)",
                "mutedMessageTypesChanged: \(mutedMessageTypesChanged)",
                "conversationListIndicatorChanged \(conversationListIndicatorChanged)",
                "clearedChanged \(clearedChanged)",
                "securityLevelChanged \(securityLevelChanged)",
                "teamChanged \(teamChanged)",
                "createdRemotelyChanged \(createdRemotelyChanged)",
                "destructionTimeoutChanged \(destructionTimeoutChanged)",
                "languageChanged \(languageChanged)",
                "hasReadReceiptsEnabledChanged \(hasReadReceiptsEnabledChanged)",
                "externalParticipantsStateChanged \(externalParticipantsStateChanged)",
                "legalHoldStatusChanged: \(legalHoldStatusChanged)",
                "labelsChanged: \(labelsChanged)"
            ].joined(separator: ", ")
    }
    
    public required init(object: NSObject) {
        super.init(object: object)
    }
    
    static func changeInfo(for conversation: ZMConversation, changes: Changes) -> ConversationChangeInfo? {
        guard changes.changedKeys.count > 0 || changes.originalChanges.count > 0 else { return nil }
        let changeInfo = ConversationChangeInfo(object: conversation)
        changeInfo.changeInfos = changes.originalChanges
        changeInfo.changedKeys = changes.changedKeys
        return changeInfo
    }
}

@objc public protocol ZMConversationObserver : NSObjectProtocol {
    func conversationDidChange(_ changeInfo: ConversationChangeInfo)
}


extension ConversationChangeInfo {

    /// Adds a ZMConversationObserver to the specified conversation
    /// You must hold on to the token and use it to unregister
    @objc(addObserver:forConversation:)
    public static func add(observer: ZMConversationObserver, for conversation: ZMConversation) -> NSObjectProtocol {
        return ManagedObjectObserverToken(name: .ConversationChange,
                                          managedObjectContext: conversation.managedObjectContext!,
                                          object: conversation)
        { [weak observer] (note) in
            guard let `observer` = observer,
                let changeInfo = note.changeInfo as? ConversationChangeInfo
                else { return }
            
            observer.conversationDidChange(changeInfo)
        } 
    }
}


/// Conversation degraded
extension ConversationChangeInfo {

    @objc public var causedByConversationPrivacyChange: Bool {
        if securityLevelChanged {
            return conversation.securityLevel == .secureWithIgnored && !self.conversation.messagesThatCausedSecurityLevelDegradation.isEmpty
        } else if legalHoldStatusChanged {
            return conversation.legalHoldStatus == .pendingApproval && !self.conversation.messagesThatCausedSecurityLevelDegradation.isEmpty
        }

        return false
    }
    
    /// Users that caused the conversation to degrade
    @objc public var usersThatCausedConversationToDegrade : Set<ZMUser> {
        let untrustedParticipants = self.conversation.activeParticipants.filter { user -> Bool in
            return !user.trusted()
        }
        return Set(untrustedParticipants)
    }
}
