//
// 


import Foundation

extension ZMAssetClientMessage {

    /// Name of notification fired when requesting a download of an image
    public static let imageDownloadNotificationName = NSNotification.Name(rawValue: "ZMAssetClientMessageImageDownloadNotification")
    
    /// Name of notification fired when requesting a download of an asset
    public static let assetDownloadNotificationName = NSNotification.Name(rawValue: "ZMAssetClientMessageAssetDownloadNotification")
}
