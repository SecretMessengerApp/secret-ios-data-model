//
//

import Foundation


public extension ZMConversationMessage {

    /// Returns YES, if the message has text to display.
    /// This also includes linkPreviews or links to soundcloud, youtube or vimeo
    var isText: Bool {
        return textMessageData != nil
    }
    
    var isJsonText: Bool {
        return jsonTextMessageData != nil
    }

    var isImage: Bool {
        return imageMessageData != nil || (fileMessageData != nil && fileMessageData!.v3_isImage)
    }

    var isKnock: Bool {
        return knockMessageData != nil
    }

    /// Returns YES, if the message is a file transfer message
    /// This also includes audio messages and video messages
    var isFile: Bool {
        return fileMessageData != nil && !fileMessageData!.v3_isImage
    }

    var isPass: Bool {
        return isFile && fileMessageData!.isPass
    }

    var isVideo: Bool {
        return isFile && fileMessageData!.isVideo
    }

    var isAudio: Bool {
        return isFile && fileMessageData!.isAudio
    }

    var isLocation: Bool {
        return locationMessageData != nil
    }

    var isSystem: Bool {
        return systemMessageData != nil
    }
    
    var isService: Bool {
        if let systemMessage = self as? ZMSystemMessage, systemMessage.serviceMessage != nil {
            return true
        }
        return false
    }
    
  
    var isNewSystem: Bool {
        guard let jsonMessageData = jsonTextMessageData?.jsonMessageText?.data(using: .utf8),
            let jsonObject = try? JSONSerialization.jsonObject(with: jsonMessageData, options: JSONSerialization.ReadingOptions.mutableContainers),
            let dict = jsonObject as? [String: Any] else {
            return false
        }
     
        if dict["msgType"] as? String == "11" {
            return true
        } else {
            return false
        }
    }

    var isNormal: Bool {
        return isText
            || isImage
            || isKnock
            || (isJsonText && !isNewSystem)
            || isFile
            || isVideo
            || isAudio
            || isLocation
    }

    var isConnectionRequest: Bool {
        guard isSystem else { return false }
        return systemMessageData!.systemMessageType == .connectionRequest
    }

    var isMissedCall: Bool {
        guard isSystem else { return false }
        return systemMessageData!.systemMessageType == .missedCall
    }

    var isPerformedCall: Bool {
        guard isSystem else { return false }
        return systemMessageData!.systemMessageType == .performedCall
    }

    var isDeletion: Bool {
        guard isSystem else { return false }
        return systemMessageData!.systemMessageType == .messageDeletedForEveryone
    }

}

/// The `ZMConversationMessage` protocol can not be extended in Objective-C,
/// thus this helper class provides access to commonly used properties.
public class Message: NSObject {

    /// Returns YES, if the message has text to display.
    /// This also includes linkPreviews or links to soundcloud, youtube or vimeo
    @objc(isTextMessage:)
    public class func isText(_ message: ZMConversationMessage) -> Bool {
        return message.isText
    }
    
    @objc(isJsonTextMessage:)
    public class func isJsonText(_ message: ZMConversationMessage) -> Bool {
        return message.isJsonText
    }

    @objc(isImageMessage:)
    public class func isImage(_ message: ZMConversationMessage) -> Bool {
        return message.isImage
    }

    @objc(isKnockMessage:)
    public class func isKnock(_ message: ZMConversationMessage) -> Bool {
        return message.isKnock
    }

    /// Returns YES, if the message is a file transfer message
    /// This also includes audio messages and video messages
    @objc(isFileTransferMessage:)
    public class func isFileTransfer(_ message: ZMConversationMessage) -> Bool {
        return message.isFile
    }

    @objc(isVideoMessage:)
    public class func isVideo(_ message: ZMConversationMessage) -> Bool {
        return message.isVideo
    }

    @objc(isAudioMessage:)
    public class func isAudio(_ message: ZMConversationMessage) -> Bool {
        return message.isAudio
    }

    @objc(isLocationMessage:)
    public class func isLocation(_ message: ZMConversationMessage) -> Bool {
        return message.isLocation
    }

    @objc(isSystemMessage:)
    public class func isSystem(_ message: ZMConversationMessage) -> Bool {
        return message.isSystem
    }

    @objc(isNormalMessage:)
    public class func isNormal(_ message: ZMConversationMessage) -> Bool {
        return message.isNormal
    }
    
    @objc(isNewSystemMessage:)
    public class func isNewSystem(_ message: ZMConversationMessage) -> Bool {
        return message.isNewSystem
    }

    @objc(isConnectionRequestMessage:)
    public class func isConnectionRequest(_ message: ZMConversationMessage) -> Bool {
        return message.isConnectionRequest
    }

    @objc(isMissedCallMessage:)
    public class func isMissedCall(_ message: ZMConversationMessage) -> Bool {
        return message.isMissedCall
    }

    @objc(isPerformedCallMessage:)
    public class func isPerformedCall(_ message: ZMConversationMessage) -> Bool {
        return message.isPerformedCall
    }

    @objc(isDeletedMessage:)
    public class func isDeleted(_ message: ZMConversationMessage) -> Bool {
        return message.isDeletion
    }

}
