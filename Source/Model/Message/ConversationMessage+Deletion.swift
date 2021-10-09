//
//


import Foundation
import WireCryptobox

extension ZMConversation {
    static func appendHideMessageToSelfConversation(_ message: ZMMessage) {
        guard let messageId = message.nonce,
              let conversation = message.conversation,
              let conversationId = conversation.remoteIdentifier
        else { return }
        
        let genericMessage = ZMGenericMessage.message(content: ZMMessageHide.hide(conversationId: conversationId, messageId: messageId))
        ZMConversation.appendSelfConversation(with: genericMessage, managedObjectContext: message.managedObjectContext!)
    }
}

extension ZMMessage {
    
    // NOTE: This is a free function meant to be called from Obj-C because you can't call protocol extension from it
    @objc public static func hideMessage(_ message: ZMConversationMessage) {
        // when deleting ephemeral, we must delete for everyone (only self & sender will receive delete message)
        // b/c deleting locally will void the destruction timer completion.
        guard !message.isEphemeral else { deleteForEveryone(message); return }
        guard let castedMessage = message as? ZMMessage else { return }
        castedMessage.hideForSelfUser()
    }
    
    @objc public func hideForSelfUser() {
        guard !isZombieObject else { return }
        ZMConversation.appendHideMessageToSelfConversation(self)

        // To avoid reinserting when receiving an edit we delete the message locally
        removeClearingSender(true)

        if let conversation = self.conversation,
            conversation.lastVisibleMessage == self {
             conversation.lastVisibleMessage = conversation.lastMessages(limit: 1).first
        }
        managedObjectContext?.delete(self)
    }
    
    @discardableResult @objc public static func deleteForEveryone(_ message: ZMConversationMessage) -> ZMClientMessage? {
        guard let castedMessage = message as? ZMMessage else { return nil }
        return castedMessage.deleteForEveryone()
    }
    
    @discardableResult @objc func deleteForEveryone() -> ZMClientMessage? {
        guard !isZombieObject, let sender = sender , (sender.isSelfUser || isEphemeral) else { return nil }
        guard let conversation = conversation, let messageNonce = nonce else { return nil}
        
        let message =  conversation.append(message: ZMMessageDelete.delete(messageId: messageNonce), hidden: true)
        message?.unblock = true
        
        removeClearingSender(false)
        updateCategoryCache()

        if conversation.lastVisibleMessage == self {
            conversation.lastVisibleMessage = conversation.lastMessages(limit: 1).first
        }
        return message
    }
    
    @objc var isEditableMessage : Bool {
        return false
    }
}

extension ZMClientMessage {
    override var isEditableMessage : Bool {
        guard let genericMessage = genericMessage,
              let sender = sender, sender.isSelfUser
        else {
            return false
        }
        
        return genericMessage.hasEdited() || genericMessage.hasText() && !isEphemeral && isSent
    }
}



