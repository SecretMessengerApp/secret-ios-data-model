//
//

import Foundation

public let ZMReactionUnicodeValueKey    = "unicodeValue"
public let ZMReactionMessageValueKey    = "message"
public let ZMReactionUsersValueKey      = "users"

@objc public enum TransportReaction : UInt32 {
    case none  = 0
    case heart = 1
    case audioPlayed = 2
}


@objcMembers open class Reaction : ZMManagedObject {
    
    @NSManaged var unicodeValue : String?
    @NSManaged var message      : ZMMessage?
    @NSManaged var users        : Set<ZMUser>
    
    
    public static func insertReaction(_ unicodeValue: String, users: [ZMUser], inMessage message: ZMMessage) -> Reaction {
        let reaction = insertNewObject(in: message.managedObjectContext!)
        reaction.message = message
        reaction.unicodeValue = unicodeValue
        reaction.mutableSetValue(forKey: ZMReactionUsersValueKey).addObjects(from: users)
        return reaction
    }
    
    
    open override func keysTrackedForLocalModifications() -> Set<String> {
        return [ZMReactionUsersValueKey]
    }
    
    open override class func entityName() -> String {
        return "Reaction"
    }
    
    open override class func sortKey() -> String? {
        return ZMReactionUnicodeValueKey
    }
    
    @objc public static func transportReaction(from unicode: String) -> TransportReaction {
        switch unicode {
        case MessageReaction.like.unicodeValue:         return .heart
        case MessageReaction.audioPlayed.unicodeValue:  return .audioPlayed
        default: return .none
        }
    }
    
}
