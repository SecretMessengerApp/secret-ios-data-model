// 
// 


import Foundation
import MobileCoreServices
import WireSystem
import WireUtilities

private let zmLog = ZMSLog(tag: "ZMFileMetadata")


@objcMembers open class ZMFileMetadata : NSObject {
    
    public let fileURL : URL
    public let thumbnail : Data?
    public let filename : String
    
    required public init(fileURL: URL, thumbnail: Data? = nil, name: String? = nil) {
        self.fileURL = fileURL
        self.thumbnail = thumbnail?.count > 0 ? thumbnail : nil
        let endName = name ?? (fileURL.lastPathComponent.isEmpty ? "unnamed" :  fileURL.lastPathComponent)
        
        self.filename = endName.removingExtremeCombiningCharacters
        super.init()
    }
    
    convenience public init(fileURL: URL, thumbnail: Data? = nil) {
        self.init(fileURL: fileURL, thumbnail: thumbnail, name: nil)
    }
    
    var asset : ZMAsset {
        get {
            return ZMAsset.asset(withOriginal: .original(withSize: size,
                mimeType: mimeType,
                name: filename)
            )
        }
    }
}


open class ZMAudioMetadata : ZMFileMetadata {
    
    public let duration : TimeInterval
    public let normalizedLoudness : [Float]
    
    required public init(fileURL: URL, duration: TimeInterval, normalizedLoudness: [Float] = [], thumbnail: Data? = nil) {
        self.duration = duration
        self.normalizedLoudness = normalizedLoudness
        
        super.init(fileURL: fileURL, thumbnail: thumbnail, name: nil)
    }
    
    required public init(fileURL: URL, thumbnail: Data?, name: String? = nil) {
        self.duration = 0
        self.normalizedLoudness = []
        super.init(fileURL: fileURL, thumbnail: thumbnail, name: name)
    }
    
    override var asset : ZMAsset {
        get {
            return ZMAsset.asset(withOriginal: .original(withSize: size,
                mimeType: mimeType,
                name: filename,
                audioDurationInMillis: UInt(duration * 1000),
                normalizedLoudness: normalizedLoudness)
            )
        }
    }
    
}

open class ZMVideoMetadata : ZMFileMetadata {
    
    public let duration : TimeInterval
    public let dimensions : CGSize
    
    required public init(fileURL: URL, duration: TimeInterval, dimensions: CGSize, thumbnail: Data? = nil) {
        self.duration = duration
        self.dimensions = dimensions
        
        super.init(fileURL: fileURL, thumbnail: thumbnail, name: nil)
    }
    
    required public init(fileURL: URL, thumbnail: Data?, name: String? = nil) {
        self.duration = 0
        self.dimensions = CGSize.zero
        
        super.init(fileURL: fileURL, thumbnail: thumbnail, name: name)
    }
    
    override var asset : ZMAsset {
        get {
            return ZMAsset.asset(withOriginal: .original(withSize: size,
                mimeType: mimeType,
                name: filename,
                videoDurationInMillis: UInt(duration * 1000),
                videoDimensions: dimensions)
            )
        }
    }
    
}

extension ZMFileMetadata {

    var fileType: UTType? {
        return UTType(fileExtension: fileURL.pathExtension)
    }
    
    var mimeType: String {
        return fileType?.mimeType ?? "application/octet-stream"
    }
    
    var size: UInt64 {
        do {
            let attributes = try fileURL.resourceValues(forKeys: [.fileSizeKey])
            let size = attributes.fileSize ?? 0
            return UInt64(size)
        } catch {
            zmLog.error("Couldn't read file size of \(fileURL)")
            return 0
        }
    }
    
}
