//
//

import Foundation
import WireSystem
import WireImages

protocol Cache {
    
    /// Returns the asset data for a given key.
    ///
    /// This will probably cause I/O
    func assetData(_ key: String) -> Data?
    
    /// Returns the file URL (if any) for a given key.
    func assetURL(_ key: String) -> URL?
    
    /// Stores the asset data for a given key.
    ///
    /// - parameter data: Asset data which should be stored
    /// - parameter key: unique key used to store & retrieve the asset data
    /// - parameter createdAt: date when the asset data was created
    ///
    /// This will probably cause I/O
    func storeAssetData(_ data: Data, key: String, createdAt: Date)
    
    /// Stores the asset data for a source url that must be a local file.
    ///
    /// - parameter url: URL pointing to the data which should be stored
    /// - parameter key: unique key used to store & retrieve the asset data
    /// - parameter createdAt: date when the asset data was created
    ///
    /// This will probably cause I/O
    func storeAssetFromURL(_ url: URL, key: String, createdAt: Date)
    
    /// Deletes the data for a key.
    func deleteAssetData(_ key: String)
    
    /// Deletes assets created earlier than the given date.
    ///
    /// This will cause I/O
    func deleteAssetsOlderThan(_ date: Date) throws
    
    /// Checks if the data exists in the cache. Faster than checking the data itself
    func hasDataForKey(_ key: String) -> Bool
    
}
