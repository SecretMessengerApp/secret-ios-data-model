//
//

import Foundation

fileprivate extension NSRange {
    var range: Range<Int> {
        return lowerBound..<upperBound
    }
}

@objc
extension ZMClientMessage: ZMTextMessageData {
    
    public var isQuotingSelf: Bool{
        return quote?.sender?.isSelfUser ?? false
    }
    
    public var hasQuote: Bool {
        return genericMessage?.textData?.hasQuote() ?? false
    }
    
    public var messageText: String? {
        return genericMessage?.textData?.content.removingExtremeCombiningCharacters
    }
    
    @objc public var isMarkDown: Bool {
        return genericMessage?.textData?.markdown() ?? false
    }
    
    public var mentions: [Mention] {
        guard let protoBuffers = genericMessage?.textData?.mentions,
              let messageText = messageText,
              let managedObjectContext = managedObjectContext else { return [] }
        
        let mentions = Array(protoBuffers.compactMap({ Mention($0, context: managedObjectContext) }).prefix(500))
        var mentionRanges = IndexSet()
        let messageRange = NSRange(messageText.startIndex ..< messageText.endIndex, in: messageText)

        return mentions.filter({ mention  in
            let range = mention.range.range
            
            guard !mentionRanges.intersects(integersIn: range), range.upperBound <= messageRange.upperBound else { return false }
            
            mentionRanges.insert(integersIn: range)
            
            return true
        })
    }
        
    public func editText(_ text: String, mentions: [Mention], fetchLinkPreview: Bool) {
        guard let nonce = nonce, isEditableMessage else { return }
        
        // Quotes are ignored in edits but keep it to mark that the message has quote for us locally
        let editedText = ZMText.text(with: text, mentions: mentions, linkPreviews: [], replyingTo: self.quote as? ZMOTRMessage)
        let editNonce = UUID()
        add(ZMGenericMessage.message(content: ZMMessageEdit.edit(with: editedText, replacingMessageId: nonce), nonce: editNonce).data())
        updateNormalizedText()
        
        self.nonce = editNonce
        self.updatedTimestamp = Date()
        self.reactions.removeAll()
        self.linkPreviewState = fetchLinkPreview ? .waitingToBeProcessed : .done
        self.linkAttachments = nil
        self.delivered = false
    }
        
}

