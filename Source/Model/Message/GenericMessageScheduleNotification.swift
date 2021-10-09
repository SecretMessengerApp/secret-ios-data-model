//
//


public struct GenericMessageScheduleNotification {

    private enum UserInfoKey: String {
        case message
        case conversation
    }
    
    private static let name = Notification.Name("GenericMessageScheduleNotification")

    private init() {}
    
    public static func post(message: ZMGenericMessage, conversation: ZMConversation) {
        let userInfo = [
            UserInfoKey.message.rawValue: message,
            UserInfoKey.conversation.rawValue: conversation
        ]
        NotificationInContext(name: self.name,
                              context: conversation.managedObjectContext!.notificationContext,
                              userInfo: userInfo
        ).post()
    }
    
    public static func addObserver(managedObjectContext: NSManagedObjectContext,
                                using block: @escaping (ZMGenericMessage, ZMConversation)->()) -> Any
    {
        return NotificationInContext.addObserver(name: self.name,
                                                 context: managedObjectContext.notificationContext)
        { note in
            guard let message = note.userInfo[UserInfoKey.message.rawValue] as? ZMGenericMessage,
                let conversation = note.userInfo[UserInfoKey.conversation.rawValue] as? ZMConversation
                else { return }
            block(message, conversation)
        }
    }
}
