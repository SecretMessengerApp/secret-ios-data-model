

import Foundation

enum NSManagedObjectContextType: String {
    case ui
    case sync
    case msg
    case search
}

@objc extension NSManagedObjectContext {
    
    static var UUIDToObjectCaches: [NSManagedObjectContextType.RawValue: NSMapTable<NSString, ZMManagedObject>] = {
        var caches = [NSManagedObjectContextType.RawValue: NSMapTable<NSString, ZMManagedObject>]()
        caches[NSManagedObjectContextType.msg.rawValue] = NSMapTable.strongToWeakObjects()
        caches[NSManagedObjectContextType.ui.rawValue] = NSMapTable.strongToWeakObjects()
        caches[NSManagedObjectContextType.sync.rawValue] = NSMapTable.strongToWeakObjects()
        caches[NSManagedObjectContextType.search.rawValue] = NSMapTable.strongToWeakObjects()
        return caches
    }()
    
    typealias UUIDString = String
    
    var type: String? {
        guard let string = Thread.current.name else {return nil}
        guard
            string != NSManagedObjectContextType.ui.rawValue,
            string != NSManagedObjectContextType.sync.rawValue,
            string != NSManagedObjectContextType.msg.rawValue,
            string != NSManagedObjectContextType.search.rawValue else {
            return nil
        }
        return string
    }
    
    
    @objc(getCacheManagedObjectWithuuidString:clazz:)
    public func getCacheManagedObject(uuidString: String?, clazz: AnyClass) -> ZMManagedObject? {
        guard let u = uuidString else {return nil}
        guard let type = self.type else {return nil}
        if let threadLocal = NSManagedObjectContext.UUIDToObjectCaches[type],
            let object = threadLocal.object(forKey: u as NSString),
            object.isKind(of: clazz){
            return object
        }
        return nil
    }
    
    @objc(setCacheManagedObjectWithuuidString:object:)
    public func setCacheManagedObject(uuidString: String?, object: ZMManagedObject) {
        guard let u = uuidString else {return}
        guard let type = self.type else {return}
        if let threadLocal = NSManagedObjectContext.UUIDToObjectCaches[type]
            {
            threadLocal.setObject(object, forKey: u as NSString)
        }
    }
    
}
