//
//

import Foundation

extension ZMMessage {
    
    /// Apply a message edit update
    ///
    /// - parameter messageEdit: Message edit update
    /// - parameter updateEvent: Update event which delivered the message edit update
    /// - Returns: true if edit was succesfully applied
    @objc
    func processMessageEdit(_ messageEdit: ZMMessageEdit, from updateEvent: ZMUpdateEvent) -> Bool {
        guard let nonce = updateEvent.messageNonce(),
              let senderUUID = updateEvent.senderUUID(),
              let originalText = genericMessage?.textData,
              let editedText = messageEdit.text,
              messageEdit.hasText(),
              senderUUID == sender?.remoteIdentifier,
              let manageContext = self.managedObjectContext
        else { return false }
        
        add(ZMGenericMessage.message(content: originalText.applyEdit(from: editedText), nonce: nonce).data())
        updateNormalizedText()
                
        if let existMessage = ZMMessage.fetch(withRemoteIdentifier: nonce, in: manageContext) {
            manageContext.delete(existMessage)
        }
        
        self.nonce = nonce
        self.updatedTimestamp = updateEvent.timeStamp()
        self.reactions.removeAll()
        self.linkAttachments = nil
        return true
    }
    
}
