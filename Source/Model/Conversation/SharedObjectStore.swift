//
//



fileprivate extension Notification {

    var contextDidSaveData: [AnyHashable : AnyObject] {
        guard let info = userInfo else { return [:] }
        var changes = [AnyHashable : AnyObject]()
        for (key, value) in info {
            guard let set = value as? NSSet else { continue }
            changes[key] = set.compactMap {
                return ($0 as? NSManagedObject)?.objectID.uriRepresentation()
                } as AnyObject
        }

        return changes
    }

}

/// This class is used to persist `NSManagedObjectContext` change
/// notifications in order to merge them into the main app contexts.
@objcMembers public class ContextDidSaveNotificationPersistence: NSObject {

    private let objectStore: SharedObjectStore<[AnyHashable: AnyObject]>

    public required init(accountContainer url: URL) {
        objectStore = SharedObjectStore(accountContainer: url, fileName: "ContextDidChangeNotifications")
    }

    @discardableResult public func add(_ note: Notification) -> Bool {
        return objectStore.store(note.contextDidSaveData)
    }

    public func clear() {
        objectStore.clear()
    }

    public var storedNotifications: [[AnyHashable: AnyObject]] {
        return objectStore.load()
    }

}

@objcMembers public class StorableTrackingEvent: NSObject {

    private static let eventNameKey = "eventName"
    private static let eventAttributesKey = "eventAttributes"

    public let name: String
    public let attributes: [String: Any]

    public init(name: String, attributes: [String: Any]) {
        self.name = name
        self.attributes = attributes
    }

    public convenience init?(dictionary dict: [String: Any]) {
        guard let name = dict[StorableTrackingEvent.eventNameKey] as? String,
            var attributes = dict[StorableTrackingEvent.eventAttributesKey] as? [String: Any] else { return nil }
        attributes["timestamp"] = Date().transportString()
        self.init(name: name, attributes: attributes)
    }

    public func dictionaryRepresentation() -> [String: Any] {
        return [
            StorableTrackingEvent.eventNameKey: name,
            StorableTrackingEvent.eventAttributesKey: attributes
        ]
    }

}

@objcMembers public class ShareExtensionAnalyticsPersistence: NSObject {
    private let objectStore: SharedObjectStore<[String: Any]>

    public required init(accountContainer url: URL) {
        objectStore = SharedObjectStore(accountContainer: url, fileName: "ShareExtensionAnalytics")
    }

    @discardableResult public func add(_ storableEvent: StorableTrackingEvent) -> Bool {
        return objectStore.store(storableEvent.dictionaryRepresentation())
    }

    public func clear() {
        objectStore.clear()
    }

    public var storedTrackingEvents: [StorableTrackingEvent] {
        return objectStore.load().compactMap(StorableTrackingEvent.init)
    }
}


private let zmLog = ZMSLog(tag: "shared object store")

// This class is needed to test unarchiving data saved before project rename
// It has to be added to WireDataModel module because it won't be resolved otherwise
class SharedObjectTestClass: NSObject, NSCoding {
    var flag: Bool
    override init() { flag = false }
    public func encode(with aCoder: NSCoder) { aCoder.encode(flag, forKey: "flag") }
    public required init?(coder aDecoder: NSCoder) { flag = aDecoder.decodeBool(forKey: "flag") }
}

/// This class is used to persist objects in a shared directory
public class SharedObjectStore<T>: NSObject {

    private let directory: URL
    private let url: URL
    private let fileManager = FileManager.default
    private let directoryName = "sharedObjectStore"

    public required init(accountContainer: URL, fileName: String) {
        self.directory = accountContainer.appendingPathComponent(directoryName)
        self.url = directory.appendingPathComponent(fileName)
        super.init()
        FileManager.default.createAndProtectDirectory(at:directory)
        FileManager.default.createAndProtectDirectory(at:url)
    }

    @discardableResult public func store(_ object: T) -> Bool {
        do {
//            var current = load()
//            current.append(object)
//            let archived = NSKeyedArchiver.archivedData(withRootObject: current)
//            try archived.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            let path = url.appendingPathComponent(UUID().transportString())
            let archived = NSKeyedArchiver.archivedData(withRootObject: object)
            try archived.write(to: path, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            zmLog.debug("Stored object in shared container at \(url), object: \(object)")
            return true
        } catch {
            zmLog.error("Failed to write to url: \(url), error: \(error), object: \(object)")
            return false
        }
    }

    public func load() -> [T] {
        if !fileManager.fileExists(atPath: url.path) {
            zmLog.debug("Skipping loading shared file as it does not exist")
            return []
        }

        do {
            let subPaths = try FileManager.default.subpathsOfDirectory(atPath: url.path)
            var stored = [T]()
            for path in subPaths {
                let subFullPath = url.appendingPathComponent(path).path
                let data = try Data(contentsOf: URL(fileURLWithPath: subFullPath))
                let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
                let obj = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? T
                if let t = obj {
                    stored.append(t)
                }
            }
//            let data = try Data(contentsOf: url)
//            let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
//            unarchiver.delegate = self // If we are loading data saved before project rename the class will not be found
//            let stored = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? [T]
            zmLog.debug("Loaded shared objects from \(url): \(String(describing: stored))")
            return stored
        } catch {
            zmLog.error("Failed to read from url: \(url), error: \(error)")
            return []
        }
    }
    
    public func clear() {
        do {
            let subPaths = try FileManager.default.subpathsOfDirectory(atPath: url.path)
            for path in subPaths {
                let subFullPath = url.appendingPathComponent(path).path
                guard fileManager.fileExists(atPath: subFullPath) else { return }
                try fileManager.removeItem(at: URL(fileURLWithPath: subFullPath))
            }
            zmLog.debug("Cleared shared objects from \(url)")
        } catch {
            zmLog.error("Failed to remove item at url: \(url), error: \(error)")
        }
    }
    
}
