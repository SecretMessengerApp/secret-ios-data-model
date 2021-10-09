

import Foundation

extension ZMMessage {
    
    @discardableResult
    @objc public static func addOperation(
        _ type: MessageOperationType,
        status: MessageOperationStatus,
        onMessage message: ZMConversationMessage) -> ZMClientMessage? {
        
        guard
            let message = message as? ZMMessage,
            let context = message.managedObjectContext,
            let messageID = message.nonce,
            message.isSent
            else { return nil }
        let operatorUser: ZMUser = .selfUser(in: context)
        let operaorName = operatorUser.newName()
        let genericMessage = ZMGenericMessage.message(content: ZMForbid(type: type.uniqueValue, messageID: messageID, operatorName: operaorName))
        let clientMessage = message.conversation?.appendClientMessage(with: genericMessage, expires: false, hidden: true)
        switch status {
        case .on: message.isillegal = true
        case .off: message.isillegal = false
        }
        message.illegalUserName = operatorUser.newName()
        return clientMessage
    }
}
