//
//

import Foundation

private let log = ZMSLog(tag: "Conversations")

@objc 
extension ZMConversation {
    
    @discardableResult @objc(appendLocation:nonce:)
    public func append(location: LocationData, nonce: UUID = UUID()) -> ZMConversationMessage? {
        let locationContent = Location.with() {
            $0.latitude = location.latitude
            $0.longitude = location.longitude
            if let name = location.name {
                $0.name = name
            }
            $0.zoom = location.zoomLevel
        }

        return appendClientMessage(with: GenericMessage.message(content: locationContent, nonce: nonce, expiresAfter: messageDestructionTimeoutValue))
    }
    
    @discardableResult
    public func appendKnock(nonce: UUID = UUID()) -> ZMConversationMessage? {
        return appendClientMessage(with: ZMGenericMessage.message(content: ZMKnock.knock(), nonce: nonce, expiresAfter: messageDestructionTimeoutValue))
    }
    
    @discardableResult @objc(appendJsonText:unblock:nonce:)
    public func append(jsonText: String, unblock: Bool = false,
                       nonce: UUID = UUID()) -> ZMConversationMessage? {
        
//        guard !(text as NSString).zmHasOnlyWhitespaceCharacters() else { return nil }
        let textContent = ZMTextJson.text(with: jsonText)
        let clientMessage = ZMGenericMessage.message(content: textContent, nonce: nonce)
        let message = appendClientMessage(with: clientMessage)!
        message.unblock = unblock
        return message
    }
    
    @discardableResult @objc(appendText:mentions:fetchLinkPreview:nonce:)
    public func append(text: String,
                       mentions: [Mention] = [],
                       fetchLinkPreview: Bool = true,
                       nonce: UUID = UUID()) -> ZMConversationMessage? {
        
        return append(text: text, mentions: mentions, replyingTo: nil, fetchLinkPreview: fetchLinkPreview, nonce: nonce)
    }
    
    @discardableResult @objc(appendText:mentions:replyingToMessage:fetchLinkPreview:nonce:isMarkDown:)
    public func append(text: String,
                       mentions: [Mention] = [],
                       replyingTo quotedMessage: ZMConversationMessage? = nil,
                       fetchLinkPreview: Bool = true,
                       nonce: UUID = UUID(),
                       isMarkDown: Bool = false) -> ZMConversationMessage? {
        
        guard !(text as NSString).zmHasOnlyWhitespaceCharacters() else { return nil }
        
        let textContent = ZMText.text(with: text, mentions: mentions, linkPreviews: [], replyingTo: quotedMessage as? ZMOTRMessage, isMarkDown: isMarkDown)
        let genericMessage = ZMGenericMessage.message(content: textContent, nonce: nonce, expiresAfter: messageDestructionTimeoutValue)
        let clientMessage = ZMClientMessage(nonce: nonce, managedObjectContext: managedObjectContext!)
        clientMessage.add(genericMessage.data())
        if  quotedMessage != nil {
            clientMessage.linkPreviewState = .done
            clientMessage.needsLinkAttachmentsUpdate = false
        } else {
            clientMessage.linkPreviewState = fetchLinkPreview ? .waitingToBeProcessed : .done
            clientMessage.needsLinkAttachmentsUpdate = fetchLinkPreview
        }
        clientMessage.quote = quotedMessage as? ZMMessage
        
        appendMessage(clientMessage, expires: true, hidden: false)
        
        if let managedObjectContext = managedObjectContext {
            NotificationInContext(name: ZMConversation.clearTypingNotificationName,
                                  context: managedObjectContext.notificationContext,
                                  object: self).post()
        }
        
        return clientMessage
    }
    
    @discardableResult @objc(appendImageAtURL:nonce:)
    public func append(imageAtURL URL: URL, nonce: UUID = UUID()) -> ZMConversationMessage?  {
        guard URL.isFileURL,
              ZMImagePreprocessor.sizeOfPrerotatedImage(at: URL) != .zero,
              let imageData = try? Data.init(contentsOf: URL, options: []) else { return nil }
        
        return append(imageFromData: imageData)
    }
    
    @discardableResult @objc(appendImageFromData:isOriginal:nonce:)
    public func append(imageFromData imageData: Data, isOriginal: Bool = false, nonce: UUID = UUID()) -> ZMConversationMessage? {
        do {
            let imageDataWithoutMetadata = try imageData.wr_removingImageMetadata()
            return appendAssetClientMessage(withNonce: nonce, imageData: imageDataWithoutMetadata, isOriginal: isOriginal)
        } catch let error {
            log.error("Cannot remove image metadata: \(error)")
            return nil
        }
    }
    
    @discardableResult @objc(appendFile:nonce:)
    public func append(file fileMetadata: ZMFileMetadata, nonce: UUID = UUID()) -> ZMConversationMessage? {
        guard let data = try? Data.init(contentsOf: fileMetadata.fileURL, options: .mappedIfSafe),
              let managedObjectContext = managedObjectContext else { return nil }
        
        guard let message = ZMAssetClientMessage(with: fileMetadata,
                                                 nonce: nonce,
                                                 managedObjectContext: managedObjectContext,
                                                 expiresAfter: messageDestructionTimeoutValue) else { return  nil}
        
        message.sender = ZMUser.selfUser(in: managedObjectContext)
        
        appendMessage(message)
        unarchiveIfNeeded()
        
        managedObjectContext.zm_fileAssetCache.storeAssetData(message, encrypted: false, data: data)
        
        if let thumbnailData = fileMetadata.thumbnail {
            managedObjectContext.zm_fileAssetCache.storeAssetData(message, format: .original, encrypted: false, data: thumbnailData)
        }
        
        message.updateCategoryCache()
        
        return message
    }
    
    // MARK: - Objective-C compability methods
    
    @discardableResult @objc(appendMessageWithText:)
    public func _append(text: String) -> ZMConversationMessage? {
        return append(text: text)
    }
    
    @discardableResult @objc(appendMessageWithText:fetchLinkPreview:)
    public func _append(text: String, fetchLinkPreview: Bool) -> ZMConversationMessage? {
        return append(text: text, fetchLinkPreview: fetchLinkPreview)
    }
    
    @discardableResult @objc(appendKnock)
    public func _appendKnock() -> ZMConversationMessage? {
        return appendKnock()
    }
    
    @discardableResult @objc(appendMessageWithLocationData:)
    public func _append(location: LocationData) -> ZMConversationMessage? {
        return append(location: location)
    }
    
    @discardableResult @objc(appendMessageWithImageData:isOriginal:)
    public func _append(imageFromData imageData: Data, isOriginal: Bool) -> ZMConversationMessage? {
        return append(imageFromData: imageData, isOriginal: isOriginal)
    }
    
    @discardableResult @objc(appendMessageWithFileMetadata:)
    public func _append(file fileMetadata: ZMFileMetadata) -> ZMConversationMessage? {
        return append(file: fileMetadata)
    }
    
    // MARK: - Helper methods
    
    func append(message: MessageContentType, nonce: UUID = UUID(), hidden: Bool = false, expires: Bool = false) -> ZMClientMessage? {
        return appendClientMessage(with: ZMGenericMessage.message(content: message, nonce: nonce), expires: expires, hidden: hidden)
    }
    
}
