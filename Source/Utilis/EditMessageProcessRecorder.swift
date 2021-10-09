

import Foundation

@objcMembers
public class EditMessageProcessRecorder: NSObject {
    
    typealias User = String
    typealias MessageId = String
    
   
    static let shared = EditMessageProcessRecorder()
    
    let maxSize = 10000
    let defaults = AppGroupInfo.instance.sharedUserDefaults
    
    let EditMessageIdsProcessedInExtensionKey = "EditMessageIdsProcessedInExtensionKey"
    
    private var editMessageIdsMap: [User: [MessageId]] = [:]
    
    override init() {
        super.init()
        self.refreshIdsInMemory()
    }
    
    func applicationWillEnterForeground() {
        self.refreshIdsInMemory()
    }
    
    func applicationDidEnterBackground() {
        synchronization()
    }
    
    private func refreshIdsInMemory() {
        if let idsMap = defaults.dictionary(forKey: EditMessageIdsProcessedInExtensionKey) as? [User: [MessageId]] {
            editMessageIdsMap = idsMap
        } else {
            defaults.setValue([:], forKey: EditMessageIdsProcessedInExtensionKey)
            editMessageIdsMap = [:]
        }
    }
    
    func addMessageEdited(messageId: String, user: String) {
        defer {
            synchronization()
        }
        let editMessageIds = editMessageIdsMap[user]
        if var editIds = editMessageIds {
            if editIds.count > maxSize {
                editIds = editIds.secretSuffix(count: maxSize/2)
            }
            editIds.append(messageId)
            editMessageIdsMap[user] = editIds
        } else {
            editMessageIdsMap[user] = [messageId]
        }
    }
    
    func exist(messageId: String, user: String) -> Bool {
        let editMessageIds = editMessageIdsMap[user]
        guard let editIds = editMessageIds else {
            return false
        }
        let exist = editIds.contains(messageId)
        return exist
    }
    
    func remove(messageId: String, user: String) {
        defer {
            synchronization()
        }
        let editMessageIds = editMessageIdsMap[user]
        guard var editIds = editMessageIds else {
            return
        }
        if let index = editIds.firstIndex(of: messageId) {
            editIds.remove(at: index)
            editMessageIdsMap[user] = editIds
        }
    }
    
    func removeAll(user: String? = nil) {
        defer {
            synchronization()
        }
        guard let usr = user else {
            editMessageIdsMap = [:]
            return
        }
        editMessageIdsMap[usr] = []
    }
    
    func synchronization() {
        defaults.setValue(editMessageIdsMap, forKey: EditMessageIdsProcessedInExtensionKey)
    }
}

