//
//


import Foundation

extension ZMConversation {

    /// Appends a "message was delete" system message
    @objc public func appendDeletedForEveryoneSystemMessage(at date: Date, sender: ZMUser) {
        self.appendSystemMessage(type: .messageDeletedForEveryone,
                                 sender: sender,
                                 users: nil,
                                 clients: nil,
                                 timestamp: date)
        
    }
}
