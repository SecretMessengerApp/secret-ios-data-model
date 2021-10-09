//
//

import Foundation

extension ZMConversation {
    @objc public static let lastReadDidChangeNotificationName = Notification.Name(rawValue: "ZMConversationLastReadDidChangeNotificationName")
    @objc public static let clearTypingNotificationName = Notification.Name(rawValue: "ZMConversationClearTypingNotificationName")
    @objc public static let isVerifiedNotificationName = Notification.Name(rawValue: "ZMConversationIsVerifiedNotificationName")
    
    /// Sends a notification with the given name on the UI context
    func notifyOnUI(name: Notification.Name) {
        guard let userInterfaceContext = self.managedObjectContext?.zm_userInterface else {
            return
        }
        
        userInterfaceContext.performGroupedBlock {
            NotificationInContext(name: name, context: userInterfaceContext.notificationContext, object: self).post()
        }
    }
}
