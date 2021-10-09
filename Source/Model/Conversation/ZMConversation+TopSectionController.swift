

import Foundation

public let topConversationsObjectIDKey = "WireTopConversationsObjectIDKey"
public let topConversationSize = 20

extension ZMConversation {
    
    @objc func addSelfToTopSectionDirectory() {
        guard let oid = self.remoteIdentifier?.transportString() else {return}
        guard var ids = self.managedObjectContext?.persistentStoreMetadata(forKey: topConversationsObjectIDKey) as? [String] else {
            self.managedObjectContext?.setPersistentStoreMetadata(array: [oid], key: topConversationsObjectIDKey)
            return
        }
        ids = ids.compactMap {
            return UUID(uuidString: $0) != nil ? $0 : nil
        }
        
        defer {
            if ids.count > 0 {
                self.managedObjectContext?.setPersistentStoreMetadata(array: ids, key: topConversationsObjectIDKey)
            }
        }
        if let index = ids.firstIndex(of: oid) {
            ids.remove(at: index)
            ids.insert(oid, at: 0)
            return
        }
        if ids.count == topConversationSize {
            ids.removeLast()
            ids.insert(oid, at: 0)
            return
        }
        ids.insert(oid, at: 0)
        
    }
    
}
