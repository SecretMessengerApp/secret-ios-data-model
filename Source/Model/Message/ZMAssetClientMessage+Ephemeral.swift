//
//

import Foundation

extension ZMAssetClientMessage {
 
    @objc override public var isEphemeral: Bool {
        return self.destructionDate != nil || self.ephemeral != nil || self.isObfuscated
    }
    
    var ephemeral: ZMEphemeral? {
        let first = self.dataSet.array
            .compactMap { ($0 as? ZMGenericMessageData)?.genericMessage }
            .filter { $0.hasEphemeral() }
            .first
        return first?.ephemeral
    }
    
    @objc override public var deletionTimeout: TimeInterval {
        if let ephemeral = self.ephemeral {
            return TimeInterval(ephemeral.expireAfterMillis / 1000)
        }
        return -1
    }
    
    @objc override public func obfuscate() {
        super.obfuscate()
        
        var obfuscatedMessage: ZMGenericMessage? = nil
        if let medium = self.mediumGenericMessage {
            obfuscatedMessage = medium.obfuscatedMessage()
        } else if self.fileMessageData != nil {
            obfuscatedMessage = self.genericAssetMessage?.obfuscatedMessage()
        }
        
        self.deleteContent()
        
        if let obfuscatedMessage = obfuscatedMessage {
            _ = self.createNewGenericMessage(with: obfuscatedMessage.data())
        }
    }
    
    @discardableResult @objc public override func startDestructionIfNeeded() -> Bool {
        
        if self.imageMessageData != nil && !self.hasDownloadedFile {
            return false
        } else if self.fileMessageData != nil  && self.genericAssetMessage?.assetData?.hasUploaded() == false && self.genericAssetMessage?.assetData?.hasNotUploaded() == false {
            return false
        }
        
        return super.startDestructionIfNeeded()
    }
    
    /// Extends the destruction timer to the given date, which must be later
    /// than the current destruction date. If a timer is already running,
    /// then it will be stopped and restarted with the new date, otherwise
    /// a new timer will be created.
    public func extendDestructionTimer(to date: Date) {
        let timeout = date.timeIntervalSince(Date())
        
        guard let isSelfUser = self.sender?.isSelfUser,
            let destructionDate = self.destructionDate,
            date > destructionDate,
            timeout > 0
            else { return }
        
        let msg = self as ZMMessage
        if isSelfUser { msg.restartObfuscationTimer(timeout) }
        else { msg.restartDeletionTimer(timeout) }
    }
}
