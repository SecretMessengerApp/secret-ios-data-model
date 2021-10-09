//
//

import Foundation
import CoreData


@objc public enum MessageConfirmationType : Int16 {
    case delivered, read
    
    static func convert(_ zmConfirmationType: ZMConfirmationType) -> MessageConfirmationType {
        //TODO: change ZMConfirmationType to NS_CLOSED_ENUM
        switch zmConfirmationType {
        case .DELIVERED:
            return .delivered
        case .READ:
            return .read
        @unknown default:
            fatalError()
        }
    }
}

@objc(ZMMessageConfirmation) @objcMembers
open class ZMMessageConfirmation : NSObject {
    
    /// Creates a ZMMessageConfirmation objects that holds a reference to a message that was confirmed and the user who confirmed it.
    /// It can have 2 types: Delivered and Read depending on the confirmation type
    @objc
    public static func createMessageConfirmations(_ confirmation: ZMConfirmation, conversation: ZMConversation, updateEvent: ZMUpdateEvent) {
        
        let type = MessageConfirmationType.convert(confirmation.type)
        
        guard let managedObjectContext = conversation.managedObjectContext,
              let firstMessageId = confirmation.firstMessageId else { return }
        
        let moreMessageIds = confirmation.moreMessageIds as? [String] ?? []
        let confirmedMesssageIds = ([firstMessageId] + moreMessageIds).compactMap({ UUID(uuidString: $0) })
        
        for confirmedMessageId in confirmedMesssageIds {
            guard let message = ZMMessage.fetch(withNonce: confirmedMessageId, for: conversation, in: managedObjectContext) else { return }
            message.isSendDelivered = type == .delivered
            message.isSendRead = type == .read
        }
        
    }
    
}
