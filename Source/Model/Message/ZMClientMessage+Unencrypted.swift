

import Foundation
private var zmLog = ZMSLog(tag: "message unencryption")

public protocol UnencryptedMessagePayloadGenerator {

    func unencryptedMessagePayload() -> [String: Any]?

    var unencryptedMessageDebugInfo: String { get }
}

extension ZMClientMessage: UnencryptedMessagePayloadGenerator {

    public func unencryptedMessagePayload() -> [String : Any]? {
        guard
            let genericMessage = genericMessage,
            let conversation = conversation,
            let moc = conversation.managedObjectContext
            else { return nil }
        let user = ZMUser.selfUser(in: moc)
        
        guard
            let sender = user.selfClient()?.remoteIdentifier,
            let name = user.name
            else { return nil }
        var params: [String: Any] = [:]
        var asset: [String: Any] = [:]
        asset["name"] = name
        if let imgId = user.previewProfileAssetIdentifier {
            asset["avatar_key"] = imgId
        }
        
        params = [
            "text": genericMessage.data().base64EncodedString(),
            "sender": sender,
            "asset": asset
        ]
        
        let sendUserIds = [String]()
        if !sendUserIds.isEmpty {
            params["recipients"] = sendUserIds
        }
        
        if self.unblock {
            params["unblock"] = true
        }
        
        func recipientsForDeletedEphemeral() -> Set<ZMUser>? {
            guard genericMessage.hasDeleted() && [.group, .hugeGroup].contains(conversation.conversationType) else { return nil }
            let nonce = UUID(uuidString: genericMessage.deleted.messageId)
            guard let message = ZMMessage.fetch(withNonce:nonce, for:conversation, in:conversation.managedObjectContext!) else { return nil }
            guard message.destructionDate != nil else { return nil }
            guard let sender = message.sender else {
                zmLog.error("sender of deleted ephemeral message \(String(describing: genericMessage.deleted.messageId)) is already cleared \n ConvID: \(String(describing: conversation.remoteIdentifier)) ConvType: \(conversation.conversationType.rawValue)")
                return Set(arrayLiteral: user)
            }
            
            // if self deletes their own message, we want to send delete msg
            // for everyone, so return nil.
            guard !sender.isSelfUser else { return nil }
            
            // otherwise we delete only for self and the sender, all other
            // recipients are unaffected.
            return Set(arrayLiteral: sender, user)
        }
        
        if let deletedEphemeral = recipientsForDeletedEphemeral() {
            params["recipients"] = deletedEphemeral.map({
                $0.remoteIdentifier.transportString()
            })
        }
        return params
    }

    public var unencryptedMessageDebugInfo: String {
        var info = "\(String(describing: genericMessage))"
        if let genericMessage = genericMessage, genericMessage.hasExternal() {
            info = "External message: " + info
        }
        return info
    }
}

extension ZMAssetClientMessage: UnencryptedMessagePayloadGenerator {

    public func unencryptedMessagePayload() -> [String : Any]? {
        guard
            let genericMessage = genericAssetMessage,
            let conversation = conversation,
            let moc = conversation.managedObjectContext
            else { return nil }
        let user = ZMUser.selfUser(in: moc)
        guard
            let sender = user.selfClient()?.remoteIdentifier,
            let name = user.name
            else { return nil }
        var asset: [String: Any] = [:]
        asset["name"] = name
        if let imgId = user.previewProfileAssetIdentifier {
            asset["avatar_key"] = imgId
        }
        var params = [
            "text": genericMessage.data().base64EncodedString(),
            "sender": sender,
            "asset": asset
        ] as [String : Any]
        
        func recipientsForDeletedEphemeral() -> Set<ZMUser>? {
            guard genericMessage.hasDeleted() && [.group, .hugeGroup].contains(conversation.conversationType) else { return nil }
            let nonce = UUID(uuidString: genericMessage.deleted.messageId)
            guard let message = ZMMessage.fetch(withNonce:nonce, for:conversation, in:conversation.managedObjectContext!) else { return nil }
            guard message.destructionDate != nil else { return nil }
            guard let sender = message.sender else {
                zmLog.error("sender of deleted ephemeral message \(String(describing: genericMessage.deleted.messageId)) is already cleared \n ConvID: \(String(describing: conversation.remoteIdentifier)) ConvType: \(conversation.conversationType.rawValue)")
                return Set(arrayLiteral: user)
            }
            
            // if self deletes their own message, we want to send delete msg
            // for everyone, so return nil.
            guard !sender.isSelfUser else { return nil }
            
            // otherwise we delete only for self and the sender, all other
            // recipients are unaffected.
            return Set(arrayLiteral: sender, user)
        }
        
        if let deletedEphemeral = recipientsForDeletedEphemeral() {
            params["recipients"] = deletedEphemeral.map({
                $0.remoteIdentifier.transportString()
            })
        }
        return params
    }

    public var unencryptedMessageDebugInfo: String {
        return "\(String(describing: genericAssetMessage))"
    }
}
