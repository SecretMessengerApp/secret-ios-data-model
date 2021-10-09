//
//


public extension ZMConversation {

    @objc static private var emptyConversationEllipsis: String {
        return "…"
    }
    
    @objc static private var emptyGroupConversationName: String {
        return NSLocalizedString("conversation.displayname.emptygroup", comment: "")
    }

    /// This is equal to the meaningful display name, if it exists, otherwise a
    /// fallback placeholder name is used.
    ///
    @objc public var displayName: String {
        switch conversationType {
        case .oneOnOne, .connection: return meaningfulDisplayName ?? ZMConversation.emptyConversationEllipsis
        case .group, .hugeGroup: return meaningfulDisplayName ?? ZMConversation.emptyGroupConversationName
        default: return meaningfulDisplayName ?? ""
        }
    }
    
    /// A meaningful display name is one that can be constructed from the conversation
    /// data, rather than relying on a fallback placeholder name, such as "…" or "Empty conversation".
    ///
    @objc var meaningfulDisplayName: String? {
        switch conversationType {
        case .connection: return connectionDisplayName()
        case .group, .hugeGroup: return groupDisplayName()
        case .oneOnOne: return oneOnOneDisplayName()
        case .self: return managedObjectContext.map(ZMUser.selfUser)?.name
        default: return nil
        }
    }
    
    //NSE use this
    @objc var pureMeaningfulDisplayName: String? {
        switch pureConversationType {
        case .connection: return connectionDisplayName()
        case .group, .hugeGroup: return groupDisplayName()
        case .oneOnOne: return oneOnOneDisplayName()
        case .self: return managedObjectContext.map(ZMUser.selfUser)?.name
        default: return nil
        }
    }
    
    private func connectionDisplayName() -> String? {
        precondition(conversationType == .connection)

        let name: String?
        if let connectedName = connectedUser?.name, !connectedName.isEmpty {
            name = connectedName
        } else {
            name = userDefinedName
        }

        return name
    }

    private func groupDisplayName() -> String? {
        precondition([.group, .hugeGroup].contains(conversationType))

        if let userDefined = userDefinedName, !userDefined.isEmpty {
            return userDefined
        }
        
        return "Secret"
    }

    private func oneOnOneDisplayName() -> String? {
        precondition(conversationType == .oneOnOne)

        let other = connectedUser
        if let name = other?.newName(), !name.isEmpty {
            return name
        } else {
            return nil
        }
    }

}
