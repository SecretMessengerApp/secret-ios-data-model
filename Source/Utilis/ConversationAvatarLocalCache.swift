

import Foundation
import PINCache
import WireTransport

private let MEGABYTE = UInt(1 * 1000 * 1000)

// MARK: ZMConversation
extension ZMConversation {
    private func cacheIdentifier(suffix: String?) -> String? {
        guard let convRemoteId = remoteIdentifier?.transportString(), let suffix = suffix else { return nil }
        return (convRemoteId + "-" + suffix)
    }
    
    @objc public func AvatarCacheKey(for size: ProfileImageSize) -> String? {
        switch size {
        case .preview:
            return cacheIdentifier(suffix: groupImageSmallKey)
        case .complete:
            return cacheIdentifier(suffix: groupImageMediumKey)
        }
    }
    
}

// MARK: NSManagedObjectContext

let NSManagedObjectContextConversationAvatarCacheKey = "zm_conversationAvatarCacheKey"
extension NSManagedObjectContext
{
    @objc public var zm_conversationAvatarCache : ConversationAvatarLocalCache! {
        get {
            return self.userInfo[NSManagedObjectContextConversationAvatarCacheKey] as? ConversationAvatarLocalCache
        }
        
        set {
            self.userInfo[NSManagedObjectContextConversationAvatarCacheKey] = newValue
        }
    }
}

// MARK: Cache
@objcMembers open class ConversationAvatarLocalCache : NSObject {
    
    fileprivate let log = ZMSLog(tag: "ConversationAvatarCache")
    
    /// Cache for large conversation Avatar
    fileprivate let largeConversationAvatarCache : PINCache
    
    /// Cache for small conversation Avatar
    fileprivate let smallConversationAvatarCache : PINCache
    
    
    /// Create ConversationAvatarLocalCache
    /// - parameter location: where cache is persisted on disk. Defaults to caches directory if nil.
    public init(location: URL? = nil) {
        
        let largeConversationAvatarCacheName = "largeConversationAvatars"
        let smallConversationAvatarCacheName = "smallConversationAvatars"
        
        if let rootPath = location?.path {
            largeConversationAvatarCache = PINCache(name: largeConversationAvatarCacheName, rootPath: rootPath)
            smallConversationAvatarCache = PINCache(name: smallConversationAvatarCacheName, rootPath: rootPath)
        } else {
            largeConversationAvatarCache = PINCache(name: largeConversationAvatarCacheName)
            smallConversationAvatarCache = PINCache(name: smallConversationAvatarCacheName)
        }
        
        largeConversationAvatarCache.configureLimits(50 * MEGABYTE)
        smallConversationAvatarCache.configureLimits(25 * MEGABYTE)
        
        largeConversationAvatarCache.makeURLSecure()
        smallConversationAvatarCache.makeURLSecure()
        super.init()
    }
    
    /// Stores Avatar in cache and returns true if the data was stored
    private func setAvatar(inCache cache: PINCache, cacheKey: String?, data: Data) -> Bool {
        if let resolvedCacheKey = cacheKey {
            cache.setObject(data as NSCoding, forKey: resolvedCacheKey)
            return true
        }
        return false
    }
    
    /// Removes all Avatars for conversation
    open func removeAllConversationAvatars(_ conversation: ZMConversation) {
        conversation.AvatarCacheKey(for: .complete).apply(largeConversationAvatarCache.removeObject)
        conversation.AvatarCacheKey(for: .preview).apply(smallConversationAvatarCache.removeObject)
    }
    
    open func setConversationAvatar(_ conversation: ZMConversation, data: Data, size: ProfileImageSize) {
        let key = conversation.AvatarCacheKey(for: size)
        switch size {
        case .preview:
            let stored = setAvatar(inCache: smallConversationAvatarCache, cacheKey: key, data: data)
            if stored {
                log.info("Setting [\(conversation.displayName)] preview Avatar [\(data)] cache key: \(String(describing: key))")
            }
        case .complete:
            let stored = setAvatar(inCache: largeConversationAvatarCache, cacheKey: key, data: data)
            if stored {
                log.info("Setting [\(conversation.displayName)] complete Avatar [\(data)] cache key: \(String(describing: key))")
            }
        }
    }
    
    open func conversationAvatar(_ conversation: ZMConversation, size: ProfileImageSize, queue: DispatchQueue, completion: @escaping (_ AvatarData: Data?) -> Void) {
        guard let cacheKey = conversation.AvatarCacheKey(for: size) else { return completion(nil) }
        
        queue.async {
            switch size {
            case .preview:
                completion(self.smallConversationAvatarCache.object(forKey: cacheKey) as? Data)
            case .complete:
                completion(self.largeConversationAvatarCache.object(forKey: cacheKey) as? Data)
            }
        }
    }
    

    open func conversationAvatar(_ conversation: ZMConversation, size: ProfileImageSize) -> Data? {
        guard let cacheKey = conversation.AvatarCacheKey(for: size) else { return nil }
        let data: Data?
        switch size {
        case .preview:
            data = smallConversationAvatarCache.object(forKey: cacheKey) as? Data
        case .complete:
            data = largeConversationAvatarCache.object(forKey: cacheKey) as? Data
        }
        if let data = data {
            log.info("Getting [\(conversation.displayName)] \(size == .preview ? "preview" : "complete") Avatar [\(data)] cache key: [\(cacheKey)]")
        }
        
        return data
    }
    
    open func hasConversationAvatar(_ conversation: ZMConversation, size: ProfileImageSize) -> Bool {
        guard let cacheKey = conversation.AvatarCacheKey(for: size) else { return false }
        
        switch size {
        case .preview:
            return smallConversationAvatarCache.containsObject(forKey: cacheKey)
        case .complete:
            return largeConversationAvatarCache.containsObject(forKey: cacheKey)
        }
    }
    
}

public extension ConversationAvatarLocalCache {
    func wipeCache() {
        smallConversationAvatarCache.removeAllObjects()
        largeConversationAvatarCache.removeAllObjects()
    }
}
