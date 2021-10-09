// 
// 


import Foundation
import PINCache

extension PINCache
{
    // configures
    public func configureLimits(_ bytes: UInt) {
        self.diskCache.byteLimit = bytes;
        self.memoryCache.ageLimit  = 60 * 60; // if we didn't use it in 1 hour, it can go from memory
    }
    
    // disable backup of URL
    public func makeURLSecure() {
        self.diskCache.makeURLSecure()
    }
}

extension PINDiskCache
{
    // disable backup of URL
    public func makeURLSecure() {
        
        let secureBlock : (PINDiskCache) -> Void = { cache in
            // exclude from backup
            do {
                var url = cache.cacheURL
                var values = URLResourceValues()
                values.isExcludedFromBackup = true
                try url.setResourceValues(values)
            } catch {
                fatal("Could not exclude \(cache.cacheURL) from backup")
            }
        }
        
        // every time the directory is recreated, make sure we set the property
        self.didRemoveAllObjectsBlock = secureBlock
        
        // just do it once initially
        self.synchronouslyLockFileAccessWhileExecuting(secureBlock)
    }
}

