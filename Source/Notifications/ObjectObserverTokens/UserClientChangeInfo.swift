//
// 


import Foundation


extension UserClient {
    public override var description: String {
        return "Client: \(String(describing: sessionIdentifier?.rawValue)), user name: \(String(describing: user?.name)) email: \(String(describing: user?.emailAddress)) platform: \(String(describing: deviceClass)), label: \(String(describing: label)), model: \(String(describing: model))"
    }

    
}

extension UserClient: ObjectInSnapshot {

    static public var observableKeys : Set<String> {
        return Set([#keyPath(UserClient.trustedByClients),
                    #keyPath(UserClient.ignoredByClients),
                    #keyPath(UserClient.needsToNotifyUser),
                    #keyPath(UserClient.fingerprint)])
    }
    
    public var notificationName : Notification.Name {
        return .UserClientChange
    }
}

public enum UserClientChangeInfoKey: String {
    case TrustedByClientsChanged = "trustedByClientsChanged"
    case IgnoredByClientsChanged = "ignoredByClientsChanged"
    case FingerprintChanged = "fingerprintChanged"
}

@objcMembers open class UserClientChangeInfo : ObjectChangeInfo {

    public required init(object: NSObject) {
        self.userClient = object as! UserClient
        super.init(object: object)
    }

    open var trustedByClientsChanged : Bool {
        return changedKeysContain(keys: #keyPath(UserClient.trustedByClients))
    }
    
    open var ignoredByClientsChanged : Bool {
        return changedKeysContain(keys: #keyPath(UserClient.ignoredByClients))
    }

    open var fingerprintChanged : Bool {
        return changedKeysContain(keys: #keyPath(UserClient.fingerprint))
    }

    open var needsToNotifyUserChanged : Bool {
        return changedKeysContain(keys: #keyPath(UserClient.needsToNotifyUser))
    }

    public let userClient: UserClient
    
    
    static func changeInfo(for client: UserClient, changes: Changes) -> UserClientChangeInfo? {
        guard changes.changedKeys.count > 0 || changes.originalChanges.count > 0 else { return nil }
        let changeInfo = UserClientChangeInfo(object: client)
        changeInfo.changeInfos = changes.originalChanges
        changeInfo.changedKeys = changes.changedKeys
        return changeInfo
    }
    
}



@objc public protocol UserClientObserver: NSObjectProtocol {
    func userClientDidChange(_ changeInfo: UserClientChangeInfo)
}

extension UserClientChangeInfo {
    
    /// Adds an observer for the specified userclient
    /// You must hold on to the token and use it to unregister
    @objc(addObserver:forClient:)
    public static func add(observer: UserClientObserver, for client: UserClient) -> NSObjectProtocol {
        return ManagedObjectObserverToken(name: .UserClientChange, managedObjectContext: client.managedObjectContext!, object: client)
        { [weak observer] (note) in
            guard let `observer` = observer,
                let changeInfo = note.changeInfo as? UserClientChangeInfo
                else { return }
            
            observer.userClientDidChange(changeInfo)
        } 
    }
}

