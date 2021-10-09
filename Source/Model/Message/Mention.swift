//
//

import Foundation

@objc
public class Mention: NSObject {
    
    public let range: NSRange
    public let user: UserType
    
    init?(_ protobuf: ZMMention, context: NSManagedObjectContext) {
        guard protobuf.hasUserId(), let userId = UUID(uuidString: protobuf.userId),
              protobuf.length > 0, protobuf.start >= 0,
              let user = ZMUser(remoteID: userId, createIfNeeded: false, in: context) else { return nil }
        
        self.user = user
        self.range = NSRange(location: Int(protobuf.start), length: Int(protobuf.length))
    }
    
    public init(range: NSRange, user: UserType) {
        self.range = range
        self.user = user
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let otherMention = object as? Mention else { return false }
        
        return user.isEqual(otherMention.user) && NSEqualRanges(range, otherMention.range)
    }
        
}

// MARK: - Helper

@objc public extension Mention {
    var isForSelf: Bool {
        return user.isSelfUser
    }
}

public extension ZMTextMessageData {
    var isMentioningSelf: Bool {
        return mentions.any(\.isForSelf)
    }
}
