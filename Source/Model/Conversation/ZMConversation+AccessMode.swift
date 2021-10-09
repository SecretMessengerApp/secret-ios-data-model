//
//

import Foundation

/// Defines how users can join a conversation.
public struct ConversationAccessMode: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    /// Allowed user can be added by an existing conv member.
    public static let invite    = ConversationAccessMode(rawValue: 1 << 0)
    /// Allowed user can join the conversation using the code.
    public static let code      = ConversationAccessMode(rawValue: 1 << 1)
    /// Allowed user can join knowing only the conversation ID.
    public static let link      = ConversationAccessMode(rawValue: 1 << 2)
    /// Internal value that indicates the conversation that cannot be joined (1-1).
    public static let `private` = ConversationAccessMode(rawValue: 1 << 3)
    
    public static let legacy    = invite
    public static let teamOnly  = ConversationAccessMode()
    public static let allowGuests: ConversationAccessMode = [.invite, .code]
}

extension ConversationAccessMode: Hashable {
    public var hashValue: Int {
        return self.rawValue
    }
}

public extension ConversationAccessMode {
    internal static let stringValues: [ConversationAccessMode: String] = [.invite: "invite",
                                                                          .code: "code",
                                                                          .link: "link",
                                                                          .`private`: "private"]
    
    var stringValue: [String] {
        return ConversationAccessMode.stringValues.compactMap { self.contains($0) ? $1 : nil }
    }
    
    init(values: [String]) {
        var result = ConversationAccessMode()
        ConversationAccessMode.stringValues.forEach {
            if values.contains($1) {
                result.formUnion($0)
            }
        }
        self = result
    }
}

public extension ConversationAccessMode {
    static func value(forAllowGuests allowGuests: Bool) -> ConversationAccessMode {
        return allowGuests ? .allowGuests : .teamOnly
    }
}

/// Defines who can join the conversation.
public enum ConversationAccessRole: String {
    /// Only the team member can join.
    case team = "team"
    /// Only users who have verified their phone number / email can join.
    case activated = "activated"
    /// Any user can join.
    case nonActivated = "non_activated"
}

public extension ConversationAccessRole {
    static func value(forAllowGuests allowGuests: Bool) -> ConversationAccessRole {
        return allowGuests ? ConversationAccessRole.nonActivated : ConversationAccessRole.team
    }
}

public extension ZMConversation {
    @NSManaged @objc dynamic internal var accessModeStrings: [String]?
    @NSManaged @objc dynamic internal var accessRoleString: String?
    
    /// If set to false, only team member can join the conversation.
    /// True means that a regular guest OR wireless guests could join
    /// Controls the values of `accessMode` and `accessRole`.
    @objc var allowGuests: Bool {
        get {
            return accessMode != .teamOnly && accessRole != .team
        }
        set {
            accessMode = ConversationAccessMode.value(forAllowGuests: newValue)
            accessRole = ConversationAccessRole.value(forAllowGuests: newValue)
        }
    }
    
    // The conversation access mode is stored as an array of string in CoreData, cf. `acccessModeStrings`.
    
    /// Defines how users can join a conversation.
    var accessMode: ConversationAccessMode? {
        get {
            guard let strings = self.accessModeStrings else {
                return nil
            }

            return ConversationAccessMode(values: strings)
        }
        set {
            guard let value = newValue else {
                accessModeStrings = nil
                return
            }
            accessModeStrings = value.stringValue
        }
    }
    
    /// Defines who can join the conversation.
    var accessRole: ConversationAccessRole? {
        get {
            guard let strings = self.accessRoleString else {
                return nil
            }
            
            return ConversationAccessRole(rawValue: strings)
        }
        set {
            guard let value = newValue else {
                accessRoleString = nil
                return
            }
            accessRoleString = value.rawValue
        }
    }
}

