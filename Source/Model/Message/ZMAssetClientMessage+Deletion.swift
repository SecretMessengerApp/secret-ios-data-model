//
//

import Foundation

public extension Notification.Name {
    /// Notification to be fired when a (v3) asset should be deleted,
    /// which is only possible to be done by the original uploader of the asset.
    /// When firing this notification the asset id has to be included as object in the notification.
    static let deleteAssetNotification = Notification.Name("deleteAssetNotification")
}

extension ZMAssetClientMessage {

    public override func deleteContent() {
        self.managedObjectContext?.zm_fileAssetCache.deleteAssetData(self)
        
        if let url = temporaryDirectoryURL,
            FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
        
        self.dataSet.map { $0 as! ZMGenericMessageData }.forEach {
            $0.managedObjectContext?.delete($0)
        }
        self.dataSet = NSOrderedSet()
        self.cachedGenericAssetMessage = nil
        self.assetId = nil
        self.associatedTaskIdentifier = nil
        self.preprocessedSize = CGSize.zero
    }
    
    override public func removeClearingSender(_ clearingSender: Bool) {
        if !clearingSender {
            markRemoteAssetToBeDeleted()
        }
        deleteContent()
        super.removeClearingSender(clearingSender)
    }
    
    private func markRemoteAssetToBeDeleted() {
        guard sender == ZMUser.selfUser(in: managedObjectContext!) else { return }
        
        // Request the asset to be deleted
        if let identifier = genericAssetMessage?.v3_uploadedAssetId {
            NotificationCenter.default.post(name: .deleteAssetNotification, object: identifier)
        }
        
        // Request the preview asset to be deleted
        if let previewIdentifier = genericAssetMessage?.previewAssetId {
            NotificationCenter.default.post(name: .deleteAssetNotification, object: previewIdentifier)
        }
    }
}
