//
// 


import Foundation

//////////////////////////
///
/// NewUnreadMessage
///
//////////////////////////

public final class NewUnreadMessagesChangeInfo : ObjectChangeInfo  {
    
    public convenience init(messages: [ZMConversationMessage]) {
        self.init(object: messages as NSObject)
    }
    
    public var messages : [ZMConversationMessage] {
        return object as? [ZMConversationMessage] ?? []
    }
    
}


@objc public protocol ZMNewUnreadMessagesObserver : NSObjectProtocol {
    func didReceiveNewUnreadMessages(_ changeInfo: NewUnreadMessagesChangeInfo)
}

extension NewUnreadMessagesChangeInfo {
    
    /// Adds a ZMNewUnreadMessagesObserver
    /// You must hold on to the token and use it to unregister
    @objc(addNewMessageObserver:forManagedObjectContext:)
    public static func add(observer: ZMNewUnreadMessagesObserver, managedObjectContext: NSManagedObjectContext) -> NSObjectProtocol {
        return ManagedObjectObserverToken(name: .NewUnreadMessage, managedObjectContext: managedObjectContext)
        { [weak observer] (note) in
            guard let `observer` = observer,
                let changeInfo = note.changeInfo as? NewUnreadMessagesChangeInfo
                else { return }
            observer.didReceiveNewUnreadMessages(changeInfo)
        }
    }
}



//////////////////////////
///
/// NewUnreadKnockMessage
///
//////////////////////////


@objc public final class NewUnreadKnockMessagesChangeInfo : ObjectChangeInfo {
    
    public convenience init(messages: [ZMConversationMessage]) {
        self.init(object: messages as NSObject)
    }
    
    public var messages : [ZMConversationMessage] {
        return object as? [ZMConversationMessage] ?? []
    }
}


@objc public protocol ZMNewUnreadKnocksObserver : NSObjectProtocol {
    func didReceiveNewUnreadKnockMessages(_ changeInfo: NewUnreadKnockMessagesChangeInfo)
}

extension NewUnreadKnockMessagesChangeInfo {

    /// Adds a ZMNewUnreadKnocksObserver
    /// You must hold on to the token and use it to unregister
    @objc(addNewKnockObserver:forManagedObjectContext:)
    public static func add(observer: ZMNewUnreadKnocksObserver, managedObjectContext: NSManagedObjectContext) -> NSObjectProtocol {
        return ManagedObjectObserverToken(name: .NewUnreadKnock, managedObjectContext: managedObjectContext)
        { [weak observer] (note) in
            guard let `observer` = observer,
                let changeInfo = note.changeInfo as? NewUnreadKnockMessagesChangeInfo
                else { return }
            observer.didReceiveNewUnreadKnockMessages(changeInfo)
        } 
    }

}



//////////////////////////
///
/// NewUnreadUndeliveredMessage
///
//////////////////////////


@objc public final class NewUnreadUnsentMessageChangeInfo : ObjectChangeInfo {
    
    public required convenience init(messages: [ZMConversationMessage]) {
        self.init(object: messages as NSObject)
    }
    
    public var messages : [ZMConversationMessage] {
        return  object as? [ZMConversationMessage] ?? []
    }
}



@objc public protocol ZMNewUnreadUnsentMessageObserver : NSObjectProtocol {
    func didReceiveNewUnreadUnsentMessages(_ changeInfo: NewUnreadUnsentMessageChangeInfo)
}

extension NewUnreadUnsentMessageChangeInfo {
    
    /// Adds a ZMNewUnreadUnsentMessageObserver
    /// You must hold on to the token and use it to unregister
    @objc(addNewUnreadUnsentMessageObserver:forManagedObjectContext:)
    public static func add(observer: ZMNewUnreadUnsentMessageObserver, managedObjectContext: NSManagedObjectContext) -> NSObjectProtocol {
        return ManagedObjectObserverToken(name: .NewUnreadUnsentMessage, managedObjectContext: managedObjectContext)
        { [weak observer] (note) in
            guard let `observer` = observer,
                let changeInfo = note.changeInfo as? NewUnreadUnsentMessageChangeInfo
                else { return }
            observer.didReceiveNewUnreadUnsentMessages(changeInfo)
        }
    }
}

