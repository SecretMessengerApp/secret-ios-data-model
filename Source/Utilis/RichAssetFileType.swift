// 
// 

import Foundation
import MobileCoreServices
import AVFoundation

/**
 * The list of asset types that the app can show preview of, or play inline.
 */

@objc(ZMRichAssetFileType)
public enum RichAssetFileType: Int, Equatable {
    
    /// A wallet pass.
    case walletPass = 0

    /// A playable video.
    case video = 1

    /// An playable audio.
    case audio = 2

    // MARK: - Helpers

    init?(mimeType: String) {
        let audioVisualMimeTypes = AVURLAsset.audiovisualMIMETypes()

        if mimeType == "application/vnd.apple.pkpass" {
            self = .walletPass
            return
        }

        // If the file format is not playable, ignore it.
        guard audioVisualMimeTypes.contains(mimeType) else {
            return nil
        }

        guard let typeID = UTType(mimeType: mimeType) else {
            return nil
        }

        if typeID.conformsTo(kUTTypeAudio) {
            // Match playable audio files
            self = .audio
        } else if typeID.conformsTo(kUTTypeMovie) {
            // Match playable video files
            self = .video
        } else {
            // If we cannot match the mime type to a known asset type
            return nil
        }
    }

}
