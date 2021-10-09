//
//


import Foundation
import WireUtilities

/// A notification that is tied to a specific context. It mimics
/// the behavior of a regular NSNotification but is always linked to
/// a conxtext.
/// This is needed to allow for sending a notification for `nil` object,
/// or to register an observer for any (`nil`) object, but still avoiding
/// receiving notifications that are from a different context. We could not
/// use the object as the implicit context because when registering for `nil`
/// we would get all notifications, even from other contexts.

@objcMembers public class NotificationInContext: NSObject {
    
    static let objectInNotificationKey = "objectInNotification"
    
    /// Name of the notification
    public var name: Notification.Name {
        return notification.name
    }
    
    /// The object of the notification
    public var object: AnyObject? {
        return self.userInfo[NotificationInContext.objectInNotificationKey] as AnyObject?
    }
    
    /// The context in which the notification is valid
    public var context: NotificationContext {
        return notification.object! as! NotificationContext
    }
    
    public var userInfo: [AnyHashable: Any] {
        return notification.userInfo ?? [:]
    }
    
    /// Internal notification
    private let notification: Notification
    
    @objc public init(name: Notification.Name,
                context: NotificationContext,
                object: AnyObject? = nil,
                userInfo: [String: Any]? = nil)
    {
        var userInfo = userInfo ?? [:]
        if let object = object {
            userInfo[NotificationInContext.objectInNotificationKey] = object
        }
        self.notification = Notification(name: name,
                                         object: context,
                                         userInfo: userInfo)
    }
    
    private init(notification: Notification) {
        self.notification = notification
    }
    
    /// Post notification in default notification center
    @objc public func post() {
        NotificationCenter.default.post(self.notification)
    }
    
    @objc public func post(on notificationQueue: NotificationQueue) {
        notificationQueue.enqueue(self.notification, postingStyle: .whenIdle, coalesceMask: [.onName, .onSender], forModes: nil)
    }
    
    /// Register for observer
    @objc public static func addObserver(
        name: Notification.Name,
        context: NotificationContext,
        object: AnyObject? = nil,
        queue: OperationQueue? = nil,
        using: @escaping (NotificationInContext) -> Void) -> Any
    {
        return addUnboundedObserver(name: name, context: context, object: object, queue: queue, using: using)
    }
    
    @objc public static func addUnboundedObserver(
        name: Notification.Name,
        context: NotificationContext?,
        object: AnyObject? = nil,
        queue: OperationQueue? = nil,
        using: @escaping (NotificationInContext) -> Void) -> Any
    {
        return SelfUnregisteringNotificationCenterToken(NotificationCenter.default.addObserver(forName: name,
                                                                                               object: context,
                                                                                               queue: queue)
        { note in
            let notificationInContext = NotificationInContext(notification: note)
            guard object == nil || object! === notificationInContext.object else { return }
            using(notificationInContext)
        })
    }
}

extension NotificationInContext {
    
    private enum UserInfoKeys: String {
        case changedKeys
        case changeInfo
    }
    
    convenience public init(name: Notification.Name,
                context: NotificationContext,
                object: AnyObject? = nil,
                changeInfo: ObjectChangeInfo,
                userInfo: [String: Any]? = nil)
    {
        var userInfo = userInfo ?? [:]
        userInfo[UserInfoKeys.changeInfo.rawValue] = changeInfo
        
        self.init(
            name: name,
            context: context,
            object: object,
            userInfo: userInfo)
    }
    
    convenience public init(name: Notification.Name,
                context: NotificationContext,
                object: AnyObject? = nil,
                changedKeys: [String],
                userInfo: [String: Any]? = nil)
    {
        var userInfo = userInfo ?? [:]
        userInfo[UserInfoKeys.changedKeys.rawValue] = changedKeys
        
        self.init(
            name: name,
            context: context,
            object: object,
            userInfo: userInfo)
    }
    
    public var changeInfo: ObjectChangeInfo? {
        return self.userInfo[UserInfoKeys.changeInfo.rawValue] as? ObjectChangeInfo
    }
    
    public var changedKeys: [String]? {
        return self.userInfo[UserInfoKeys.changedKeys.rawValue] as? [String]
    }
}
