//
//

import Foundation

extension ZMConversation {

    /// Appends a "message invalid" system message
    @objc @discardableResult
    public func appendInvalidSystemMessage(at date: Date, sender: ZMUser) -> ZMSystemMessage {
        return appendSystemMessage(type: .invalid,
                                 sender: sender,
                                 users: nil,
                                 clients: nil,
                                 timestamp: date)
    }
}
