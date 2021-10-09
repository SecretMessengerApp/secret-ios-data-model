//
//

import Foundation

extension ZMConnection {
    
    @objc public static let invalidateTopConversationCacheNotificationName = Notification.Name("ZMInvalidateTopConversationCacheNotificationName")
    
    @objc public func invalidateTopConversationCache() {
        guard let moc = self.managedObjectContext else { return }
        NotificationInContext(name: type(of: self).invalidateTopConversationCacheNotificationName,
                              context: moc.notificationContext).post()
    }
    
}
