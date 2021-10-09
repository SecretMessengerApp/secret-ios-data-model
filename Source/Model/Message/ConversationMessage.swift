//
// 


import Foundation
import WireLinkPreview

private var zmLog = ZMSLog(tag: "Message")

@objc
public enum ZMDeliveryState : UInt {
    case invalid = 0
    case pending = 1
    case sent = 2
    case delivered = 3
    case read = 4
    case failedToSend = 5
}

@objc
public protocol ReadReceipt {
    
    var user: ZMUser { get }
    var serverTimestamp: Date? { get }
    
}

@objc
public protocol ZMConversationMessage : NSObjectProtocol {
    
    /// Unique identifier for the message
    var nonce: UUID? { get }
        
    /// The user who sent the message
    var sender: ZMUser? { get }
    
    /// The timestamp as received by the server
    var serverTimestamp: Date? { get }
    
    /// The conversation this message belongs to
    var conversation: ZMConversation? { get }
    
    /// The current delivery state of this message. It makes sense only for
    /// messages sent from this device. In any other case, it will be
    /// ZMDeliveryStateDelivered
    var deliveryState: ZMDeliveryState { get }
    
    /// The textMessageData of the message. If the message has no jsonJext, it will be nil
    var jsonTextMessageData : ZMJsonTextMessageData? { get }
    
    /// True if the message has been successfully sent to the server
    var isSent: Bool { get }

    /// Whether the message expects read confirmations.
    var needsReadConfirmation: Bool { get }

    
    /// The textMessageData of the message which also contains potential link previews. If the message has no text, it will be nil
    var textMessageData : ZMTextMessageData? { get }
    
    /// The image data associated with the message. If the message has no image, it will be nil
    var imageMessageData: ZMImageMessageData? { get }
    
    /// The system message data associated with the message. If the message is not a system message data associated, it will be nil
    var systemMessageData: ZMSystemMessageData? { get }
    
    /// The knock message data associated with the message. If the message is not a knock, it will be nil
    var knockMessageData: ZMKnockMessageData? { get }
    
    /// The file transfer data associated with the message. If the message is not the file transfer, it will be nil
    var fileMessageData: ZMFileMessageData? { get }
    
    /// The location message data associated with the message. If the message is not a location message, it will be nil
    var locationMessageData: LocationMessageData? { get }
    
    var usersReaction : Dictionary<String, [ZMUser]> { get }
    
    /// In case this message failed to deliver, this will resend it
    func resend()
    
    /// tell whether or not the message can be deleted
    var canBeDeleted : Bool { get }
    
    /// tell whether or not the message can be edited
    var canBeEdited: Bool { get }
    /// True if the message has been deleted
    var hasBeenDeleted : Bool { get }
    
    var updatedAt : Date? { get }
    
    /// Starts the "self destruction" timer if all conditions are met
    /// It checks internally if the message is ephemeral, if sender is the other user and if there is already an existing timer
    /// Returns YES if a timer was started by the message call
    func startSelfDestructionIfNeeded() -> Bool
    
    /// Returns true if the message is ephemeral
    var isEphemeral : Bool { get }
    
    /// If the message is ephemeral, it returns a fixed timeout
    /// Otherwise it returns -1
    /// Override this method in subclasses if needed
    var deletionTimeout : TimeInterval { get }

    /// Returns true if the message is an ephemeral message that was sent by the selfUser and the obfuscation timer already fired
    /// At this point the genericMessage content is already cleared. You should receive a notification that the content was cleared
    var isObfuscated : Bool { get }

    /// Returns the date when a ephemeral message will be destructed or `nil` if th message is not ephemeral
    var destructionDate: Date? { get }
    
    /// Returns whether this is a message that caused the security level of the conversation to degrade in this session (since the 
    /// app was restarted)
    var causedSecurityLevelDegradation : Bool { get }
    
    /// Marks the message as the last unread message in the conversation, moving the unread mark exactly before this
    /// message.
    func markAsUnread()
    
    /// Checks if the message can be marked unread
    var canBeMarkedUnread: Bool { get }

    /// The replies quoting this message.
    var replies: Set<ZMMessage> { get }

    /// An in-memory identifier for tracking the message during its life cycle.
    var objectIdentifier: String { get }

    /// The links attached to the message.
    var linkAttachments: [LinkAttachment]? { get set }

    /// Used to trigger link attachments update for this message.
    var needsLinkAttachmentsUpdate: Bool { get set }
}

public extension Equatable where Self : ZMConversationMessage { }

public func ==(lhs: ZMConversationMessage, rhs: ZMConversationMessage) -> Bool {
    return lhs.isEqual(rhs)
}

public func ==(lhs: ZMConversationMessage?, rhs: ZMConversationMessage?) -> Bool {
    switch (lhs, rhs) {
    case (nil, nil):
        return true
    case (_, nil):
        return false
    case (nil, _):
        return false
    case (_, _):
        return lhs!.isEqual(rhs!)
    }
}

// MARK:- Conversation managed properties
extension ZMMessage {
    
    @NSManaged public var visibleInConversation : ZMConversation?
    @NSManaged public var hiddenInConversation : ZMConversation?
    
    public var conversation : ZMConversation? {
        return self.visibleInConversation ?? self.hiddenInConversation
    }
}


// MARK:- Conversation Message protocol implementation

extension ZMMessage : ZMConversationMessage {
    @NSManaged public var linkAttachments: [LinkAttachment]?
    @NSManaged public var needsLinkAttachmentsUpdate: Bool
    @NSManaged public var replies: Set<ZMMessage>

    public var objectIdentifier: String {
        return nonpersistedObjectIdentifer!
    }
    
    public var causedSecurityLevelDegradation : Bool {
        return false
    }
    
    public var canBeMarkedUnread: Bool {
        guard self.isNormal,
                let _ = self.serverTimestamp,
                let _ = self.conversation,
                let sender = self.sender,
                !sender.isSelfUser else {
                return false
        }
        
        return true
    }
    
    public func markAsUnread() {
//        guard canBeMarkedUnread,
//              let serverTimestamp = self.serverTimestamp,
//              let conversation = self.conversation,
//              let managedObjectContext = self.managedObjectContext,
//              let syncContext = managedObjectContext.zm_sync else {
//
//                zmLog.error("Cannot mark as unread message outside of the conversation.")
//                return
//        }
//        let conversationID = conversation.objectID
//
//        conversation.lastReadServerTimeStamp = Date(timeInterval: -0.01, since: serverTimestamp)
//        managedObjectContext.saveOrRollback()
//
//        syncContext.performGroupedBlock {
//            guard let syncObject = try? syncContext.existingObject(with: conversationID), let syncConversation = syncObject as? ZMConversation else {
//                zmLog.error("Cannot mark as unread message outside of the conversation: sync conversation cannot be fetched.")
//                return
//            }
//
//            syncConversation.calculateLastUnreadMessages()
//            syncContext.saveOrRollback()
//        }
        
    }
}

extension ZMMessage {
    
    @NSManaged public var sender : ZMUser?
    @NSManaged public var serverTimestamp : Date?
    
    @objc public var jsonTextMessageData: ZMJsonTextMessageData? {
        return nil
    }
    @objc public var textMessageData : ZMTextMessageData? {
        return nil
    }
    
    @objc public var imageMessageData : ZMImageMessageData? {
        return nil
    }
    
    @objc public var knockMessageData : ZMKnockMessageData? {
        return nil
    }
    
    @objc public var systemMessageData : ZMSystemMessageData? {
        return nil
    }
    
    @objc public var fileMessageData : ZMFileMessageData? {
        return nil
    }
    
    @objc public var locationMessageData: LocationMessageData? {
        return nil
    }
    
    @objc public var isSent: Bool {
        return true
    }
    
    @objc public var deliveryState : ZMDeliveryState {
        return .delivered
    }
    
    @objc public var usersReaction : Dictionary<String, [ZMUser]> {
        var result = Dictionary<String, [ZMUser]>()
        for reaction in self.reactions {
            if reaction.users.count > 0 {
                result[reaction.unicodeValue!] = Array<ZMUser>(reaction.users)
            }
        }
        return result
    }
    
    @objc public var canBeEdited: Bool {
        guard let conversation = self.conversation,
              let sender = self.sender else {
            return false
        }
        guard conversation.conversationType == .oneOnOne || conversation.creator.isSelfUser
                || conversation.enabledEditMsg else {
            return false
        }
        let canEdit = !isEphemeral &&
               isText &&
               conversation.isSelfAnActiveMember &&
               sender.isSelfUser &&
               deliveryState.isOne(of: .delivered, .sent, .read)
//        if conversation.conversationType == .oneOnOne && (self as? ZMClientMessage) != nil {
//            return canEdit && self.isEnabledEditMsg
//        }
        return canEdit
    }
    
    @objc public var canBeDeleted : Bool {
        guard let conversation = self.conversation else {
            return false
        }
        guard conversation.conversationType == .oneOnOne || conversation.creator.isSelfUser || conversation.enabledEditMsg else {
            return false
        }
//        if conversation.conversationType == .oneOnOne && (self as? ZMClientMessage) != nil {
//            return deliveryState != .pending && self.isEnabledEditMsg
//        }
        return deliveryState != .pending
    }
    
    @objc public var hasBeenDeleted: Bool {
        return isZombieObject || (visibleInConversation == nil && hiddenInConversation != nil)
    }
    
    @objc public var updatedAt : Date? {
        return nil
    }
 
    @objc public func startSelfDestructionIfNeeded() -> Bool {
        if !isZombieObject && isEphemeral, let sender = sender, !sender.isSelfUser {
            return startDestructionIfNeeded()
        }
        return false
    }
    
    @objc public var isEphemeral : Bool {
        return false
    }
    
    @objc public var deletionTimeout : TimeInterval {
        return -1
    }
}

