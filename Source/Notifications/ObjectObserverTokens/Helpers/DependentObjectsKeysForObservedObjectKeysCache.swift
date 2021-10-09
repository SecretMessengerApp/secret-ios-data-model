// 
// 


import Foundation

/// Used to map keys
struct DependentObjectsKeysForObservedObjectKeysCache {
    
    // keyPathsOnDependentObjectForKeyOnObservedObject : [displayName : [userDefinedName, user.name, connection.status]]
    // affectedKeysOnObservedObjectForChangedKeysOnDependentObject : [connection.status : [displayName, relatedConnectionStatus, etc.]]
    //
    let keyPathsOnDependentObjectForKeyOnObservedObject : [StringKeyPath : KeySet]
    let affectedKeysOnObservedObjectForChangedKeysOnDependentObject : [StringKeyPath : KeySet]
    
    static var cachedValues : [AnyClassTuple<KeySet> : DependentObjectsKeysForObservedObjectKeysCache] = [:]
    
    static func mappingForObject(_ observedObject : NSObject, keysToObserve : KeySet) -> DependentObjectsKeysForObservedObjectKeysCache {
     
        let tuple = AnyClassTuple(classOfObject: type(of: observedObject), secondElement: keysToObserve)
        
        if let cachedKeysToPathsToObserve = cachedValues[tuple]
        {
            return cachedKeysToPathsToObserve
        }
        
        var keysToPathsToObserve : [StringKeyPath : KeySet] = [:]
        var observedKeyPathToAffectedKey : [StringKeyPath: KeySet] = [:]
        
        for key in keysToObserve {
            var keyPaths = KeySet(type(of: observedObject).keyPathsForValuesAffectingValue(forKey: key.rawValue))
            keyPaths = keyPaths.filter { $0.isPath }
            
            var objectKeysWithPathsToObserve : [StringKeyPath : KeySet] = [:]
            
            for keyPath in keyPaths {
                
                if let (objectKey, pathToObserveInObject) = keyPath.decompose, let pathToObserve = pathToObserveInObject {
                    let previousPathToObserve = objectKeysWithPathsToObserve[objectKey] ?? KeySet()
                    objectKeysWithPathsToObserve[objectKey] = previousPathToObserve.union(KeySet(key: pathToObserve))
                }
                if let p = observedKeyPathToAffectedKey[keyPath] {
                    observedKeyPathToAffectedKey[keyPath] = p.union(KeySet(key: key))
                } else {
                    observedKeyPathToAffectedKey[keyPath] = KeySet(key: key)
                }
            }
            
            for (objectKey, pathsToObserveInObject) in objectKeysWithPathsToObserve {
                if let p = keysToPathsToObserve[objectKey] {
                    keysToPathsToObserve[objectKey] = p.union(pathsToObserveInObject)
                } else {
                    keysToPathsToObserve[objectKey] = pathsToObserveInObject
                }
            }
        }
        
        let result = DependentObjectsKeysForObservedObjectKeysCache(keyPathsOnDependentObjectForKeyOnObservedObject: keysToPathsToObserve, affectedKeysOnObservedObjectForChangedKeysOnDependentObject: observedKeyPathToAffectedKey)
        
        cachedValues[tuple] = result
        return result 
    }
    
}
