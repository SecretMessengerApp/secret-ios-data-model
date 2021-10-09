//
//

import Foundation


extension ZMConversation {
    
    override open class func predicateForFilteringResults() -> NSPredicate {
        let selfType = ZMConversationType.init(rawValue: 1)!
        return NSPredicate(format: "\(ZMConversationConversationTypeKey) != \(ZMConversationType.invalid.rawValue) && \(ZMConversationConversationTypeKey) != \(selfType.rawValue)")
    }


    @objc
    public class func predicateInSharedConversations(forSearchQuery searchQuery: String) -> NSPredicate! {
        
        let userDefinedNamePredicate = NSPredicate(format: "userDefinedName MATCHES %@", ".*\(searchQuery).*")
        let formatDict = [ZMNormalizedUserDefinedNameKey: "%K MATCHES %@"]
        guard let namePredicate = NSPredicate(formatDictionary: formatDict, matchingSearch: searchQuery) else { return .none }
        
        let regExp = ".*\\b\(searchQuery).*"
        //let friendRemarkPredicate = NSPredicate(format: "(\(ZMConversationConversationTypeKey) == \(ZMConversationType.oneOnOne.rawValue)) AND (ANY %K.reMark MATCHES %@)", ZMConversationLastServerSyncedActiveParticipantsKey, regExp)
        let friendNamePredicate = NSPredicate(format: "(\(ZMConversationConversationTypeKey) == \(ZMConversationType.oneOnOne.rawValue)) AND (ANY %K.name MATCHES %@)", ZMConversationLastServerSyncedActiveParticipantsKey, regExp)
        
        let searchPredicate = NSCompoundPredicate(orPredicateWithSubpredicates:
            [userDefinedNamePredicate,
             namePredicate,
             //friendRemarkPredicate,
             friendNamePredicate])
        
        return searchPredicate
    }
    

    @objc
    public class func predicate(forSearchQuery searchQuery: String) -> NSPredicate! {
//        let formatDict = [ZMNormalizedUserDefinedNameKey: "%K MATCHES %@"]
//            ZMConversationLastServerSyncedActiveParticipantsKey: "(ANY %K.normalizedName MATCHES %@)"]
        
        let formatDict = [ZMNormalizedUserDefinedNameKey: "%K MATCHES %@"]
        guard let namePredicate = NSPredicate(formatDictionary: formatDict, matchingSearch: searchQuery) else { return .none }
        

        let regExp = ".*\\b\(searchQuery).*"
        let memberPredicate = NSPredicate(format: "(\(ZMConversationConversationTypeKey) == \(ZMConversationType.group.rawValue)) AND (ANY %K.normalizedName MATCHES %@)", ZMConversationLastServerSyncedActiveParticipantsKey, regExp)

        let searchPredicate = NSCompoundPredicate(orPredicateWithSubpredicates:
            [namePredicate,
            memberPredicate])
        
        let activeMemberPredicate = NSPredicate(format: "%K == NULL OR %K == YES", ZMConversationClearedTimeStampKey, ZMConversationIsSelfAnActiveMemberKey)
        let basePredicate = NSPredicate(format: "(\(ZMConversationConversationTypeKey) == \(ZMConversationType.group.rawValue)) OR (\(ZMConversationConversationTypeKey) == \(ZMConversationType.hugeGroup.rawValue))")

        /// do not include team 1 to 1 conversations

        let activeParticipantsPredicate = NSPredicate(format: "%K.@count == 1",                                                                      ZMConversationLastServerSyncedActiveParticipantsKey
        )

        let userDefinedNamePredicate = NSPredicate(format: "%K == NULL",                                                                      ZMConversationUserDefinedNameKey
        )

        let teamRemoteIdentifierPredicate = NSPredicate(format: "%K != NULL",                                                                      TeamRemoteIdentifierDataKey
        )

        let notTeamMemberPredicate = NSCompoundPredicate(notPredicateWithSubpredicate: NSCompoundPredicate(andPredicateWithSubpredicates: [
            activeParticipantsPredicate,
            userDefinedNamePredicate ,
            teamRemoteIdentifierPredicate
            ]))

        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            searchPredicate,
            activeMemberPredicate,
            basePredicate,
            notTeamMemberPredicate
            ])
    }
    
    class func predicateForConversationsWhereSelfUserIsActive() -> NSPredicate {
        return .init(format: "%K == YES", ZMConversationIsSelfAnActiveMemberKey)
    }

    @objc(predicateForConversationsInTeam:)
    class func predicateForConversations(in team: Team?) -> NSPredicate {
        if let team = team {
            return .init(format: "%K == %@", #keyPath(ZMConversation.team), team)
        }

        return .init(format: "%K == NULL", #keyPath(ZMConversation.team))
    }
    
    @objc(predicateForHugeGroupConversations)
    class func predicateForHugeGroupConversations() -> NSPredicate {
        let basePredicate = predicateForFilteringResults()
        let hugeGroupConversationPredicate = NSPredicate(format: "\(ZMConversationConversationTypeKey) == \(ZMConversationType.hugeGroup.rawValue)")
        return NSCompoundPredicate(andPredicateWithSubpredicates: [basePredicate, hugeGroupConversationPredicate])
    }
    
    @objc(predicateForIncludeUnreadMessageTopGroupConversations)
    class func predicateForIncludeUnreadMessageTopGroupConversations() -> NSPredicate {
        let basePredicate = predicateForFilteringResults()
        let topConversationPredicate = NSPredicate(format: "\(ZMConversationIsPlacedTopKey) == YES")
        let hasUnreadSelfMentionPredicate = NSPredicate(format: "\(ZMConversationInternalEstimatedUnreadSelfMentionCountKey) != 0")
        let hasUnreadMessagePredicate = NSPredicate(format: "\(ZMConversationEstimatedUnreadCountKey) != 0")
        let hasUnreadSelfReplyPredicate = NSPredicate(format: "\(ZMConversationInternalEstimatedUnreadSelfReplyCountKey) != 0")
        let hasCall = NSPredicate(format: "\(ZMConversationLastUnreadMissedCallDateKey) != nil")
        let hasKnock = NSPredicate(format: "\(ZMConversationLastUnreadKnockDateKey) != nil")
        
        let unreadPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
                                                    hasUnreadSelfMentionPredicate,
                                                                                 hasUnreadMessagePredicate,
                                                                                 hasUnreadSelfReplyPredicate,
                                                                                 hasCall,
                                                                                 hasKnock])
        return NSCompoundPredicate(andPredicateWithSubpredicates: [basePredicate, topConversationPredicate, unreadPredicate, predicateForConversationsExcludingArchived()])
    }
    
    @objc(predicateForExcludeUnreadMessageTopGroupConversations)
    class func predicateForExcludeUnreadMessageTopGroupConversations() -> NSPredicate {
        let basePredicate = predicateForFilteringResults()
        let topConversationPredicate = NSPredicate(format: "\(ZMConversationIsPlacedTopKey) == YES")
        let readSelfMentionPredicate = NSPredicate(format: "\(ZMConversationInternalEstimatedUnreadSelfMentionCountKey) == 0")
        let readMessagePredicate = NSPredicate(format: "\(ZMConversationEstimatedUnreadCountKey) == 0")
        let readSelfReplyPredicate = NSPredicate(format: "\(ZMConversationInternalEstimatedUnreadSelfReplyCountKey) == 0")
        let readCall = NSPredicate(format: "\(ZMConversationLastUnreadMissedCallDateKey) == nil")
        let readKnock = NSPredicate(format: "\(ZMConversationLastUnreadKnockDateKey) == nil")
        
        let readPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                                                    readSelfMentionPredicate,
                                                    readMessagePredicate,
                                                    readSelfReplyPredicate,
                                                    readCall,
                                                    readKnock])
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: [basePredicate, topConversationPredicate, readPredicate,predicateForConversationsExcludingArchived()])
    }
    
    @objc(predicateForTopGroupConversations)
    class func predicateForTopGroupConversations() -> NSPredicate {
        let basePredicate = predicateForFilteringResults()
        let topConversationPredicate = NSPredicate(format: "\(ZMConversationIsPlacedTopKey) == YES")
        return NSCompoundPredicate(andPredicateWithSubpredicates: [basePredicate, topConversationPredicate,predicateForConversationsExcludingArchived()])
    }
    
    @objc(predicateForExcludeTopAndNotDisturbedGroupConversations)
    class func predicateForExcludeTopAndNotDisturbedGroupConversations() -> NSPredicate {
        let basePredicate = predicateForFilteringResults()
        let excludeTopConversationPredicate = NSPredicate(format: "\(ZMConversationIsPlacedTopKey) == NO")
        let excludeNotDisturbedConversationPredicate = NSPredicate(format: "\(ZMConversationIsNotDisturbKey) == NO")
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
                                    basePredicate,
                                    excludeTopConversationPredicate,
                                    excludeNotDisturbedConversationPredicate,
                                    predicateForConversationsExcludingArchived()])
    }
    
    @objc(predicateForDoNotDisturbedConversations)
    class func predicateForDoNotDisturbedConversations() -> NSPredicate {
        let basePredicate = predicateForFilteringResults()
        let predicate = NSPredicate(format: "\(ZMConversationIsNotDisturbKey) == YES")
        return NSCompoundPredicate(andPredicateWithSubpredicates: [basePredicate, predicate, predicateForConversationsExcludingArchived()])
    }
    
    @objc(predicateForUnreadMessageConversations)
    class func predicateForUnreadMessageConversations() -> NSPredicate {
        let basePredicate = predicateForFilteringResults()
        let predicate = NSPredicate(format: "\(ZMConversationInternalEstimatedUnreadCountKey) != 0 OR \(ZMConversationInternalEstimatedUnreadSelfMentionCountKey) != 0 OR \(ZMConversationInternalEstimatedUnreadSelfReplyCountKey) != 0 OR \(ZMConversationHasUnreadUnsentMessageKey) == YES OR \(ZMConversationLastUnreadMissedCallDateKey) != nil OR \(ZMConversationLastUnreadKnockDateKey) != nil")
        let noMutePredicate = NSPredicate(format: "\(ZMConversationMutedStatusKey) == 0")
        return NSCompoundPredicate(andPredicateWithSubpredicates: [basePredicate,
                                             noMutePredicate,     predicate,    predicateForConversationsExcludingArchived()])
    }

    @objc(predicateForPendingConversations)
    class func predicateForPendingConversations() -> NSPredicate {
        let basePredicate = predicateForFilteringResults()
        let pendingConversationPredicate = NSPredicate(format: "\(ZMConversationConversationTypeKey) == \(ZMConversationType.connection.rawValue) AND \(ZMConversationConnectionKey).status == \(ZMConnectionStatus.pending.rawValue)")
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: [basePredicate, pendingConversationPredicate])
    }
    
    @objc(predicateForClearedConversations)
    class func predicateForClearedConversations() -> NSPredicate {
        let cleared = NSPredicate(format: "\(ZMConversationClearedTimeStampKey) != NULL AND \(ZMConversationIsArchivedKey) == YES")
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: [cleared, predicateForValidConversations()])
    }

    @objc(predicateForConversationsIncludingArchived)
    class func predicateForConversationsIncludingArchived() -> NSPredicate {
        
        return predicateForValidConversations()
    }
    
    @objc(predicateForGroupConversations)
    class func predicateForGroupConversations() -> NSPredicate {
        let groupConversationPredicate = NSPredicate(format: "\(ZMConversationConversationTypeKey) == \(ZMConversationType.group.rawValue)")
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: [predicateForConversationsExcludingArchived(), groupConversationPredicate])
    }
    
    @objc(predicateForLabeledConversations:)
    class func predicateForLabeledConversations(_ label: Label) -> NSPredicate {
        let labelPredicate = NSPredicate(format: "%@ IN \(ZMConversationLabelsKey)", label)
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: [predicateForConversationsExcludingArchived(), labelPredicate])
    }
    
    class func predicateForConversationsInFolders() -> NSPredicate {
        return NSPredicate(format: "ANY %K.%K == \(Label.Kind.folder.rawValue)", ZMConversationLabelsKey, #keyPath(Label.type))
    }
    
    class func predicateForUnconnectedConversations() -> NSPredicate {
        return NSPredicate(format: "\(ZMConversationConversationTypeKey) == \(ZMConversationType.connection.rawValue)")
    }
    
    class func predicateForOneToOneConversation() -> NSPredicate {
        return NSPredicate(format: "\(ZMConversationConversationTypeKey) == \(ZMConversationType.oneOnOne.rawValue)")
    }
    
    class func predicateForTeamOneToOneConversation() -> NSPredicate {
        // We consider a conversation being an existing 1:1 team conversation in case the following point are true:
        //  1. It is a conversation inside a team
        //  2. The only participants are the current user and the selected user
        //  3. It does not have a custom display name
        
        let isTeamConversation = NSPredicate(format: "team != NULL")
        let isGroupConversation = NSPredicate(format: "\(ZMConversationConversationTypeKey) == \(ZMConversationType.group.rawValue)")
        let hasNoUserDefinedName = NSPredicate(format: "\(ZMConversationUserDefinedNameKey) == NULL")
        let hasOnlyOneParticipant = NSPredicate(format: "\(ZMConversationLastServerSyncedActiveParticipantsKey).@count == 1")
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: [isTeamConversation, isGroupConversation, hasNoUserDefinedName, hasOnlyOneParticipant])
    }
    
    @objc(predicateForOneToOneConversations)
    class func predicateForOneToOneConversations() -> NSPredicate {
        // We consider a conversation to be one-to-one if it's of type .oneToOne, is a team 1:1 or an outgoing connection request.
        let oneToOneConversationPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [predicateForOneToOneConversation(), predicateForTeamOneToOneConversation(), predicateForUnconnectedConversations()])
        let notInFolderPredicate = NSCompoundPredicate(notPredicateWithSubpredicate: predicateForConversationsInFolders())
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: [predicateForConversationsExcludingArchived(), oneToOneConversationPredicate, notInFolderPredicate])
    }
    
    @objc(predicateForArchivedConversations)
    class func predicateForArchivedConversations() -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [predicateForConversationsIncludingArchived(), NSPredicate(format: "\(ZMConversationIsArchivedKey) == YES")])
    }

    @objc(predicateForConversationsExcludingArchived)
    class func predicateForConversationsExcludingArchived() -> NSPredicate {
        return predicateForConversationsIncludingArchived()
    }

    @objc(predicateForSharableConversations)
    class func predicateForSharableConversations() -> NSPredicate {
        let basePredicate = predicateForConversationsIncludingArchived()
        let hasOtherActiveParticipants = NSPredicate(format: "\(ZMConversationLastServerSyncedActiveParticipantsKey).@count > 0")
        let oneOnOneOrGroupConversation = NSPredicate(format: "\(ZMConversationConversationTypeKey) == \(ZMConversationType.oneOnOne.rawValue) OR \(ZMConversationConversationTypeKey) == \(ZMConversationType.group.rawValue) OR \(ZMConversationConversationTypeKey) == \(ZMConversationType.hugeGroup.rawValue)")
        let selfIsActiveMember = NSPredicate(format: "isSelfAnActiveMember == YES")
        let synced = NSPredicate(format: "\(remoteIdentifierDataKey()!) != NULL")
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: [basePredicate, oneOnOneOrGroupConversation, hasOtherActiveParticipants, selfIsActiveMember, synced])
    }
    
    private class func predicateForValidConversations() -> NSPredicate {
        let basePredicate = predicateForFilteringResults()
        let notAConnection = NSPredicate(format: "\(ZMConversationConversationTypeKey) != \(ZMConversationType.connection.rawValue)")
        let activeConnection = NSPredicate(format: "NOT \(ZMConversationConnectionKey).status IN %@", [NSNumber(value: ZMConnectionStatus.pending.rawValue),
                                                                                                       NSNumber(value: ZMConnectionStatus.ignored.rawValue),
                                                                                                       NSNumber(value: ZMConnectionStatus.cancelled.rawValue)]) //pending connections should be in other list, ignored and cancelled are not displayed
        let predicate1 = NSCompoundPredicate(orPredicateWithSubpredicates: [notAConnection, activeConnection]) // one-to-one conversations and not pending and not ignored connections
        let noConnection = NSPredicate(format: "\(ZMConversationConnectionKey) == nil") // group conversations
        let notBlocked = NSPredicate(format: "\(ZMConversationConnectionKey).status != \(ZMConnectionStatus.blocked.rawValue)")
        let predicate2 = NSCompoundPredicate(orPredicateWithSubpredicates: [noConnection, notBlocked]) //group conversations and not blocked connections
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: [basePredicate, predicate1, predicate2])
    }
    
}
