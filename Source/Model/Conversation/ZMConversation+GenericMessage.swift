//
//

import Foundation
import WireProtos

extension ZMConversation {
    /// Appends a new message to the conversation.
    /// @param genericMessage the generic message that should be appended
    /// @param expires wether the message should expire or tried to be send infinitively
    /// @param hidden wether the message should be hidden in the conversation or not
    public func appendClientMessage(with genericMessage: GenericMessage, expires: Bool = true, hidden: Bool = false) -> ZMClientMessage? {
        guard let nonce = UUID(uuidString: genericMessage.messageID) else { return nil }
        guard let moc = self.managedObjectContext else { return nil }
        do {
            let data = try genericMessage.serializedData()
            let message = ZMClientMessage(nonce: nonce, managedObjectContext: moc)
            message.add(data)
            message.sender = ZMUser.selfUser(in: moc)
            if expires {
                message.setExpirationDate()
            }
            if hidden {
                message.hiddenInConversation = self
            } else {
                appendMessage(message)
                unarchiveIfNeeded()
                message.updateCategoryCache()
            }
            self.addSelfToTopSectionDirectory()
            return message
        } catch {
            return nil
        }
    }
}
