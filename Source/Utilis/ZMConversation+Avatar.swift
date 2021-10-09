

import Foundation

public extension Notification.Name {
    static let conversationDidRequestPreviewAvatar = Notification.Name("ConversationDidRequestPreviewAvatar")
    static let conversationDidRequestCompleteAvatar = Notification.Name("ConversationDidRequestCompleteAvatar")
}

extension ZMConversation {
    
    @objc static let groupAvatarPreviewKey = #keyPath(ZMConversation.groupImageSmallKey)
    @objc static let groupAvatarCompleteKey = #keyPath(ZMConversation.groupImageMediumKey)
    
    public func updateAndSyncProfileAssetIdentifiers(previewIdentifier: String, completeIdentifier: String) {
        groupImageSmallKey = previewIdentifier
        groupImageMediumKey = completeIdentifier
        setLocallyModifiedKeys([ZMConversation.groupAvatarPreviewKey, ZMConversation.groupAvatarCompleteKey])
    }

    @objc(setImageData:size:)
    public func setImage(data: Data?, size: ProfileImageSize) {
        guard let imageData = data else {
            managedObjectContext?.zm_conversationAvatarCache?.removeAllConversationAvatars(self)
            return
        }
        managedObjectContext?.zm_conversationAvatarCache?.setConversationAvatar(self, data: imageData, size: size)

        if let uiContext = managedObjectContext?.zm_userInterface {
            let changedKey = size == .preview ? #keyPath(ZMConversation.previewAvatarData) : #keyPath(ZMConversation.completeAvatarData)
            NotificationDispatcher.notifyNonCoreDataChanges(objectID: objectID, changedKeys: [changedKey], uiContext: uiContext)
        }
    }
    
    @objc public func requestPreviewAvatarImage() {
        guard let moc = self.managedObjectContext, moc.zm_isUserInterfaceContext, !moc.zm_conversationAvatarCache.hasConversationAvatar(self, size: .preview) else { return }

        NotificationInContext(name: .conversationDidRequestPreviewAvatar,
                              context: moc.notificationContext,
                              object: self.objectID).post()
    }
    
    @objc public func requestCompleteAvatarImage() {
        guard let moc = self.managedObjectContext, moc.zm_isUserInterfaceContext, !moc.zm_conversationAvatarCache.hasConversationAvatar(self, size: .complete) else { return }
        
        NotificationInContext(name: .conversationDidRequestCompleteAvatar,
                              context: moc.notificationContext,
                              object: self.objectID).post()
    }
    
    public static var previewAvatarDownloadFilter: NSPredicate {
        let assetIdExists = NSPredicate(format: "(%K != nil)", ZMConversation.groupAvatarPreviewKey)

        return NSCompoundPredicate(andPredicateWithSubpredicates: [assetIdExists]);
    }
    
    public static var completeAvatarDownloadFilter: NSPredicate {
        let assetIdExists = NSPredicate(format: "(%K != nil)", ZMConversation.groupAvatarCompleteKey)

        return NSCompoundPredicate(andPredicateWithSubpredicates: [assetIdExists]);
    }

    @objc public func avatarData(size: ProfileImageSize) -> Data? {
        guard let moc = self.managedObjectContext, moc.zm_isUserInterfaceContext else { return nil }
        return moc.zm_conversationAvatarCache.conversationAvatar(self, size: size)
    }
    
}
