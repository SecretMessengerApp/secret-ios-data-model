//
//


import Foundation

public let lastUpdateEventIDKey = "LastUpdateEventID"
public let lastHugeUpdateEventIDKey = "LastHugeUpdateEventID"

@objc public protocol ZMLastNotificationIDStore {
    var zm_lastNotificationID : UUID? { get set }
    var zm_lastHugeNotificationID : UUID? { get set }
    var zm_hasLastNotificationID : Bool { get }
    var zm_hasLastHugeNotificationID : Bool { get }
}

extension NSManagedObjectContext : ZMLastNotificationIDStore {
    
    public var zm_lastNotificationID: UUID? {
        set {
            guard let remoteIdentifier = ZMUser.selfUser(in: self).remoteIdentifier else {return}
            let uid = remoteIdentifier.transportString()
            if let value = newValue, let previousValue = zm_lastNotificationID,
                value.isType1UUID && previousValue.isType1UUID &&
                    previousValue.compare(withType1: value) != .orderedAscending {
                return
            }
            let eventProcessing = ZMSLog(tag: "event-processing")
            eventProcessing.info("Setting zm_lastNotificationID = \( newValue?.transportString() ?? "nil" )")
//                        self.setPersistentStoreMetadata(newValue?.uuidString, key: lastUpdateEventIDKey)
            let userDefault = AppGroupInfo.instance.sharedUserDefaults
            userDefault.set(newValue?.transportString(), forKey: lastUpdateEventIDKey + uid)
        }
        
        get {
            guard let remoteIdentifier = ZMUser.selfUser(in: self).remoteIdentifier else {return nil}
            let uid = remoteIdentifier.transportString()
            let userDefault = AppGroupInfo.instance.sharedUserDefaults
            if let id = userDefault.value(forKey: lastUpdateEventIDKey + uid) as? String {
                return UUID(uuidString: id)
            }
            guard let uuidString = self.persistentStoreMetadata(forKey: lastUpdateEventIDKey) as? String,
                let uuid = UUID(uuidString: uuidString)
                else {
                    return nil
            }
            userDefault.set(uuidString, forKey: lastUpdateEventIDKey + uid)
            return uuid
        }
    }
    
    public var zm_lastHugeNotificationID: UUID? {
        set {
            let uid = ZMUser.selfUser(in: self).remoteIdentifier.transportString()
            if let value = newValue, let previousValue = zm_lastHugeNotificationID,
                value.isType1UUID && previousValue.isType1UUID &&
                    previousValue.compare(withType1: value) != .orderedAscending {
                return
            }
            let eventProcessing = ZMSLog(tag: "huge event-processing")
            eventProcessing.info("Setting zm_lastHugeNotificationID = \( newValue?.transportString() ?? "nil" )")
            //            self.setPersistentStoreMetadata(newValue?.uuidString, key: lastUpdateEventIDKey)
            let userDefault = AppGroupInfo.instance.sharedUserDefaults
            userDefault.set(newValue?.transportString(), forKey: lastHugeUpdateEventIDKey + uid)
        }
        
        get {
            let uid = ZMUser.selfUser(in: self).remoteIdentifier.transportString()
            let userDefault = AppGroupInfo.instance.sharedUserDefaults
            if let id = userDefault.value(forKey: lastHugeUpdateEventIDKey + uid) as? String {
                return UUID(uuidString: id)
            }
            guard let uuidString = self.persistentStoreMetadata(forKey: lastUpdateEventIDKey) as? String,
                let uuid = UUID(uuidString: uuidString)
                else { return nil }
            userDefault.set(uuidString, forKey: lastHugeUpdateEventIDKey + uid)
            return uuid
        }
    }
    
    public var zm_hasLastNotificationID: Bool {
        return zm_lastNotificationID != nil
    }
    
    public var zm_hasLastHugeNotificationID: Bool {
        return zm_lastHugeNotificationID != nil
    }
}

