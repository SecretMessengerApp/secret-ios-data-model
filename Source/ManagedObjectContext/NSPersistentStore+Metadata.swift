//
//

import Foundation

// MARK: - Public accessors

@objc(ZMPersistableMetadata) public protocol PersistableInMetadata : NSObjectProtocol {}

extension NSString : PersistableInMetadata {}
extension NSNumber : PersistableInMetadata {}
extension NSDate : PersistableInMetadata {}
extension NSData : PersistableInMetadata {}

public protocol SwiftPersistableInMetadata {}
extension String : SwiftPersistableInMetadata {}
extension Date : SwiftPersistableInMetadata {}
extension Data : SwiftPersistableInMetadata {}
extension Array : SwiftPersistableInMetadata {}
extension Int : SwiftPersistableInMetadata {}

// TODO: Swift 4
// extension Array where Element == SwiftPersistableInMetadata: SwiftPersistableInMetadata {}

extension NSManagedObjectContext {
    
    @objc(setPersistentStoreMetadata:forKey:) public func setPersistentStoreMetadata(_ persistable: PersistableInMetadata?, key: String) {
        self.setPersistentStoreMetadata(data: persistable, key: key)
    }
    
    public func setPersistentStoreMetadata(_ data: SwiftPersistableInMetadata?, key: String) {
        self.setPersistentStoreMetadata(data: data, key: key)
    }
    
    public func setPersistentStoreMetadata<T: SwiftPersistableInMetadata>(array: [T], key: String) {
        self.setPersistentStoreMetadata(data: array as NSArray, key: key)
    }
}

// MARK: - Internal setters/getters

private let metadataKey = "ZMMetadataKey"
private let metadataKeysToRemove = "ZMMetadataKeysToRemove"

public extension NSManagedObjectContext {
    
    /// Non-persisted store metadata
    @objc internal var nonCommittedMetadata : NSMutableDictionary {
        get {
            return self.userInfo[metadataKey] as? NSMutableDictionary ?? NSMutableDictionary()
        }
    }
    
    /// Non-persisted deleted metadata (need to keep around to know what to remove
    /// from the store when persisting)
    @objc internal var nonCommittedDeletedMetadataKeys : Set<String> {
        get {
            return self.userInfo[metadataKeysToRemove] as? Set<String> ?? Set<String>()
        }
    }
    
    /// Discard non commited store metadata
    fileprivate func discardNonCommitedMetadata() {
        self.userInfo[metadataKeysToRemove] = [String]()
        self.userInfo[metadataKey] = [String: Any]()
    }
    
    /// Persist in-memory metadata to persistent store
    @discardableResult
    @objc func makeMetadataPersistent() -> Bool {
        
        guard nonCommittedMetadata.count > 0 || nonCommittedDeletedMetadataKeys.count > 0 else  { return false }
        
        let store = self.persistentStoreCoordinator!.persistentStores.first!
        var storedMetadata = self.persistentStoreCoordinator!.metadata(for: store)
        
        // remove keys
        self.nonCommittedDeletedMetadataKeys.forEach { storedMetadata.removeValue(forKey: $0) }
        
        // set keys
        for (key, value) in self.nonCommittedMetadata {
            guard let stringKey = key as? String else {
                fatal("Wrong key in nonCommittedMetadata: \(key), value is \(value)")
            }
            storedMetadata[stringKey] = value
        }
        
        print("lastUpdateEventIDKey    \(String(describing: storedMetadata[lastUpdateEventIDKey]))")
        
        self.persistentStoreCoordinator?.setMetadata(storedMetadata, for: store)
        self.discardNonCommitedMetadata()
        
        return true
    }
    
    /// Remove key from list of keys that will be deleted next time
    /// the metadata is persisted to disk
    fileprivate func removeFromNonCommittedDeteledMetadataKeys(key: String) {
        var deletedKeys = self.nonCommittedDeletedMetadataKeys
        deletedKeys.remove(key)
        self.userInfo[metadataKeysToRemove] = deletedKeys
    }
    
    /// Adds a key to the list of keys to be deleted next time the metadata is persisted to disk
    fileprivate func addNonCommittedDeletedMetadataKey(key: String) {
        var deletedKeys = self.nonCommittedDeletedMetadataKeys
        deletedKeys.insert(key)
        self.userInfo[metadataKeysToRemove] = deletedKeys
    }
    
    /// Set a value in the metadata for the store. The value won't be persisted until the metadata is persisted
    fileprivate func setPersistentStoreMetadata(data: Any?, key: String) {
        let metadata = self.nonCommittedMetadata
        if let data = data {
            self.removeFromNonCommittedDeteledMetadataKeys(key: key)
            metadata.setObject(data, forKey: key as NSCopying)
        } else {
            self.addNonCommittedDeletedMetadataKey(key: key)
            metadata.removeObject(forKey: key)
        }
        self.userInfo[metadataKey] = metadata
    }
}
