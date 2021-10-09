//
//

import Foundation

extension ZMOTRMessage {
    
    private static let deliveryConfirmationDayThreshold = 7
    
    @NSManaged @objc dynamic var expectsReadConfirmation: Bool
        
    override open var needsReadConfirmation: Bool {
        guard let conversation = conversation, let managedObjectContext = managedObjectContext else { return false }
        
        if conversation.conversationType == .oneOnOne {
            return genericMessage?.content?.expectsReadConfirmation() == true && ZMUser.selfUser(in: managedObjectContext).readReceiptsEnabled
        }

//        } else if conversation.conversationType == .group {
//            return expectsReadConfirmation
//        }
        
        return false
    }
    
    @objc
    var needsDeliveryConfirmation: Bool {
        return needsDeliveryConfirmationAtCurrentDate()
    }
    
    func needsDeliveryConfirmationAtCurrentDate(_ currentDate: Date = Date()) -> Bool {
        guard let conversation = conversation, conversation.conversationType == .oneOnOne,
              let sender = sender, !sender.isSelfUser,
              let serverTimestamp = serverTimestamp,
              let daysElapsed = Calendar.current.dateComponents([.day], from: serverTimestamp, to: currentDate).day,
              deliveryState != .delivered,
              deliveryState != .read
        else { return false }
        
        return daysElapsed <= ZMOTRMessage.deliveryConfirmationDayThreshold
    }
    
}
