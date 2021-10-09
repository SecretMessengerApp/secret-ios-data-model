

import Foundation

public class NotificationProcessedIdRecorder {
    
    public static let shared = NotificationProcessedIdRecorder()
    
    private let maxSize = 100
    
    private let defaults = AppGroupInfo.instance.sharedUserDefaults
    
    private let NotificationsIdsProcessedInExtensionKey = "NotificationsIdsProcessedInExtensionKey"
    
    private var ids: [String] = []
    
    init() {
        self.refreshIdsInMemory()
    }
    
    private func refreshIdsInMemory() {
        if let ids = defaults.array(forKey: NotificationsIdsProcessedInExtensionKey) as? [String] {
            self.ids = ids
        } else {
            defaults.setValue([], forKey: NotificationsIdsProcessedInExtensionKey)
            self.ids = []
        }
    }
    
    public func add(id: String) {
        if self.ids.count > maxSize {
            self.ids = self.ids.secretSuffix(count: maxSize/2)
        }
        self.ids.append(id)
        defaults.setValue(self.ids, forKey: NotificationsIdsProcessedInExtensionKey)
    }
    
    public func exist(id: String) -> Bool {
        let exist = self.ids.contains(id)
        return exist
    }
}


