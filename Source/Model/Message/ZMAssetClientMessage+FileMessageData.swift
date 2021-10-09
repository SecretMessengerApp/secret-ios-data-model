//
//


import Foundation

// MARK: - ZMFileMessageData
@objc public protocol ZMFileMessageData: NSObjectProtocol {
    
    /// MIME type of the file being transfered (implied from file extension)
    var mimeType: String? { get }
    
    /// Original file size
    var size: UInt64 { get }
    
    /// File transfer state
    var transferState: AssetTransferState { get }
    
    /// Download state (.downloaded, downloading, ...)
    var downloadState: AssetDownloadState { get }
    
    /// File name as was sent
    var filename: String? { get }
    
    /// Currend download / upload progress
    var progress: Float { get set }
    
    /// The file location on the filesystem
    var fileURL: URL? { get }
    
    /// The asset ID of the thumbnail, if any
    var thumbnailAssetID: String? { get set }
    
    /// Duration of the media in milliseconds
    var durationMilliseconds: UInt64 { get }
    
    /// Dimensions of the video
    var videoDimensions: CGSize { get }
    
    /// File thumbnail preview image
    var previewData: Data? { get }
    
    /// This can be used as a cache key for @c -previewData
    var imagePreviewDataIdentifier: String? { get }
    
    /// Normalized loudness of audio data
    var normalizedLoudness: [Float]? { get }
    
    /// Marks file to be downloaded
    func requestFileDownload()
    
    /// Marks file image preview to be downloaded
    func requestImagePreviewDownload()
    
    /// Video-message related properties
    /// if MIME type is indicating the video content
    var isVideo: Bool { get }

    /// if MIME type is indicating the PKPass content
    var isPass: Bool { get }

    /// Cancels the pending download or upload of the file.
    /// Deisgned to be used in case the file transfer on sender side is
    /// in `ZMFileMessageStateUploading` state, or in `ZMFileMessageStateDownloading`
    /// state on receiver side.
    func cancelTransfer()
    
    /// Audio-message related properties
    /// if MIME type is indicating the audio content
    var isAudio: Bool { get }
    
    /// Whether the file message represents a v3 image
    var v3_isImage: Bool { get }
    
    /// Fetch preview image data from disk
    func fetchImagePreviewData(queue: DispatchQueue, completionHandler: @escaping (_ imageData: Data?) -> Void)
    
}


private var AssociateRichAssetTypeKey: String = "AssociateRichAssetTypeKey"

extension ZMAssetClientMessage: ZMFileMessageData {
    
    /// Notification name for canceled file upload
    public static let didCancelFileDownloadNotificationName = Notification.Name(rawValue: "ZMAssetClientMessageDidCancelFileDownloadNotification")

    
    // MIME type of the file being transfered (implied from file extension)
    public var mimeType: String? {
        
        guard let asset = self.genericAssetMessage?.assetData else { return nil }
        if asset.original.hasMimeType() {
            return asset.original.mimeType
        }
        
        if asset.preview.hasMimeType() {
            return asset.preview.mimeType
        }
        
        if let assetData = self.previewGenericMessage?.imageAssetData,
            assetData.hasMimeType()
        {
            return assetData.mimeType
        }
        
        if let assetData = self.mediumGenericMessage?.imageAssetData,
            assetData.hasMimeType()
        {
            return assetData.mimeType
        }
        
        return nil
    }

    private var _richAssetType: RichAssetFileType? {
        get {
            return objc_getAssociatedObject(self, &AssociateRichAssetTypeKey) as? RichAssetFileType
        }
        set(newValue) {
            objc_setAssociatedObject(self, &AssociateRichAssetTypeKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// If the asset is a rich file type, this returns its type.
    public var richAssetType: RichAssetFileType? {
        if _richAssetType == nil {
            _richAssetType = mimeType.flatMap(RichAssetFileType.init)
        }
        return _richAssetType
    }
    
    public var fileURL: URL? {
        guard let assetURL = asset?.fileURL, let filename = filename, let temporaryDirectoryURL = temporaryDirectoryURL else { return nil }
        
        let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(filename)
        
        if FileManager.default.fileExists(atPath: temporaryFileURL.path) {
            return temporaryFileURL
        }
        
        do {
            try FileManager.default.createDirectory(at: temporaryFileURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
          
            if #available(iOS 14.0, *), ProcessInfo.processInfo.isiOSAppOnMac {
                try FileManager.default.copyItem(at: assetURL, to: temporaryFileURL)
            } else {
                try FileManager.default.linkItem(at: assetURL, to: temporaryFileURL)
            }
            
        } catch {
            return nil
        }
        
        return temporaryFileURL
    }
    
    public var temporaryDirectoryURL: URL? {
        guard let cacheKey = FileAssetCache.cacheKeyForAsset(self) else { return nil }
        var temporaryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        temporaryURL.appendPathComponent(cacheKey)
        return temporaryURL
    }
    
    public var previewData: Data? {
        return self.asset?.previewData
    }
    
    public func fetchImagePreviewData(queue: DispatchQueue, completionHandler: @escaping (Data?) -> Void) {
        guard nil != self.fileMessageData, !isImage else { return completionHandler(nil) }
        
        self.asset?.fetchImageData(with: queue, completionHandler: completionHandler)
    }
    
    /// File name as was sent or `nil` in case of an image asset
    public var filename: String? {
        return self.genericAssetMessage?.assetData?.original.name.removingExtremeCombiningCharacters
    }
    
    public var thumbnailAssetID: String? {
        
        get {
            guard self.fileMessageData != nil else { return nil }
            guard let assetData = self.genericMessage(dataType: .thumbnail)?.assetData,
                assetData.preview.remote.hasAssetId(),
                let assetId = assetData.preview.remote.assetId,
                !assetId.isEmpty
            else { return nil }
            return assetId
        }
        
        set {

            // This method has to inject this value in the currently existing thumbnail message.
            // Unfortunately it is immutable. So I need to create a copy, modify and then replace.
            guard self.fileMessageData != nil else { return }
            
            guard let thumbnailMessage = self.genericMessage(dataType: .thumbnail) else { return }
                
            
            let remoteBuilder = ZMAssetRemoteDataBuilder()
            let previewBuilder = ZMAssetPreviewBuilder()
            let assetBuilder = ZMAssetBuilder()
            let messageBuilder = ZMGenericMessageBuilder()

            if let assetData = thumbnailMessage.assetData {
                if assetData.hasPreview() {
                    if assetData.preview.hasRemote() {
                        remoteBuilder.merge(from:assetData.preview.remote)
                    }
                    previewBuilder.merge(from:assetData.preview)
                }
                assetBuilder.merge(from: assetData)
            }
            messageBuilder.merge(from: thumbnailMessage)
            remoteBuilder.setAssetId(newValue)

            previewBuilder.setRemote(remoteBuilder.build())
            assetBuilder.setPreview(previewBuilder.build())
            let asset = assetBuilder.build()!
            
            if self.isEphemeral {
                messageBuilder.setEphemeral(ZMEphemeral.ephemeral(content: asset, expiresAfter: deletionTimeout))
            } else {
                messageBuilder.setAsset(asset)
            }
            
            self.replaceGenericMessageForThumbnail(with: messageBuilder.build())
        }
    }
    
    private func replaceGenericMessageForThumbnail(with genericMessage: ZMGenericMessage) {
        self.cachedGenericAssetMessage = nil
        
        self.dataSet
            .map { $0 as! ZMGenericMessageData }
            .forEach { data in
                let dataMessage = data.genericMessage
                if let assetData = dataMessage?.assetData,
                    assetData.hasPreview() && !assetData.hasUploaded() {
                    data.data = genericMessage.data()
                }
        }
    }
    
    public var imagePreviewDataIdentifier: String? {
        return self.asset?.imagePreviewDataIdentifier
    }
    
    public var isPass: Bool {
        return richAssetType == .walletPass
    }
    
    public var isVideo: Bool {
        return richAssetType == .video
    }
    
    public var isAudio: Bool {
        return richAssetType == .audio
    }
    
    public var v3_isImage: Bool {
        return self.genericAssetMessage?.v3_isImage ?? false
    }
    
    public var videoDimensions: CGSize {
        guard let assetData = self.genericAssetMessage?.assetData else { return CGSize.zero }
        let w = assetData.original.video.width
        let h = assetData.original.video.height
        return CGSize(width: Int(w), height: Int(h))
    }

    public var durationMilliseconds: UInt64 {
        guard let assetData = self.genericAssetMessage?.assetData else { return 0 }
        if self.isVideo {
            return assetData.original.video.durationInMillis
        }
        if self.isAudio {
            return assetData.original.audio.durationInMillis
        }
        return 0
    }
    
    public var normalizedLoudness: [Float]? {
        guard self.isAudio,
            let assetData = self.genericAssetMessage?.assetData,
            assetData.original.audio.hasNormalizedLoudness() else
        {
            return nil
        }
        return assetData.original.normalizedLoudnessLevels
    }
    
    public func requestFileDownload() {
        asset?.requestFileDownload()
    }
    
    public func requestImagePreviewDownload() {
        asset?.requestPreviewDownload()
    }
}

extension ZMAssetClientMessage {
    
    public func cancelTransfer() {
        
        switch transferState {
        case .uploading:
            expire()
            updateTransferState(.uploadingCancelled, synchronize: false)
            progress = 0
        case .uploaded:
            self.progress = 0
            self.obtainPermanentObjectID()
            self.managedObjectContext?.saveOrRollback()
            NotificationInContext(
                name: ZMAssetClientMessage.didCancelFileDownloadNotificationName,
                context: self.managedObjectContext!.notificationContext,
                object: self.objectID,
                userInfo: [:]
                ).post()
        default:
            break
        }
    }

    /// Turn temporary object ID into permanet
    private func obtainPermanentObjectID() {
        if self.objectID.isTemporaryID {
            try! self.managedObjectContext!.obtainPermanentIDs(for: [self])
        }
    }
    
}
