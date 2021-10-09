//
//

import Foundation

protocol ObserverType : NSObjectProtocol {
    associatedtype ChangeInfo : ObjectChangeInfo
    var notifications : [ChangeInfo] {get set}
}

extension ObserverType {
    func clearNotifications() {
        notifications = []
    }
}

class TestUserClientObserver : NSObject, UserClientObserver {
    
    var receivedChangeInfo : [UserClientChangeInfo] = []
    
    func userClientDidChange(_ changes: UserClientChangeInfo) {
        receivedChangeInfo.append(changes)
    }
}

class UserObserver : NSObject, ZMUserObserver {
    
    var notifications = [UserChangeInfo]()
    
    func clearNotifications(){
        notifications = []
    }
    
    func userDidChange(_ changeInfo: UserChangeInfo) {
        notifications.append(changeInfo)
    }
}

class MessageObserver : NSObject, ZMMessageObserver {
    
    var token : NSObjectProtocol?
    
    override init() {}
    
    init(message : ZMMessage) {
        super.init()
        token = MessageChangeInfo.add(
            observer: self,
            for: message,
            managedObjectContext: message.managedObjectContext!)
    }
    
    var notifications : [MessageChangeInfo] = []
    
    func messageDidChange(_ changeInfo: MessageChangeInfo) {
        notifications.append(changeInfo)
    }
}


class ConversationObserver: NSObject, ZMConversationObserver {
    
    var token : NSObjectProtocol?
    
    func clearNotifications(){
        notifications = []
    }
    
    override init() {}
    
    init(conversation : ZMConversation) {
        super.init()
        token = ConversationChangeInfo.add(observer: self, for: conversation)
    }
    
    var notifications = [ConversationChangeInfo]()
    
    func conversationDidChange(_ changeInfo: ConversationChangeInfo) {
        notifications.append(changeInfo)
    }
}

@objcMembers class ConversationListChangeObserver : NSObject, ZMConversationListObserver {
    
    public var notifications = [ConversationListChangeInfo]()
    public var observerCallback : ((ConversationListChangeInfo) -> Void)?
    unowned var conversationList: ZMConversationList
    var token : NSObjectProtocol?
    
    init(conversationList: ZMConversationList, managedObjectContext: NSManagedObjectContext) {
        self.conversationList = conversationList
        super.init()
        self.token = ConversationListChangeInfo.addListObserver(self, for: conversationList, managedObjectContext: managedObjectContext)
    }
    
    func conversationListDidChange(_ changeInfo: ConversationListChangeInfo) {
        notifications.append(changeInfo)
        if let callBack = observerCallback {
            callBack(changeInfo)
        }
    }
}

class TestTeamObserver : NSObject, TeamObserver {

    var notifications = [TeamChangeInfo]()
    
    func clearNotifications(){
        notifications = []
    }
    
    func teamDidChange(_ changeInfo: TeamChangeInfo) {
        notifications.append(changeInfo)
    }
}

class TestLabelObserver: NSObject, LabelObserver {
    
    var notifications = [LabelChangeInfo]()
    
    func clearNotifications() {
        notifications = []
    }
    
    func labelDidChange(_ changeInfo: LabelChangeInfo) {
        notifications.append(changeInfo)
    }
    
}
