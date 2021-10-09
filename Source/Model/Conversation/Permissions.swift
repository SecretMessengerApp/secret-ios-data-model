//
//


/// An optionSet indicates a user's permissions
public struct Permissions: OptionSet {

    public let rawValue: Int64

    public init(rawValue: Int64) {
        self.rawValue = rawValue
    }

    // MARK: - Base Values
    public static let none                        = Permissions(rawValue: 0x0000)
    public static let createConversation          = Permissions(rawValue: 0x0001)
    public static let deleteConversation          = Permissions(rawValue: 0x0002)
    public static let addTeamMember               = Permissions(rawValue: 0x0004)
    public static let removeTeamMember            = Permissions(rawValue: 0x0008)
    public static let addRemoveConversationMember = Permissions(rawValue: 0x0010)
    public static let modifyConversationMetaData  = Permissions(rawValue: 0x0020)
    public static let getBilling                  = Permissions(rawValue: 0x0040)
    public static let setBilling                  = Permissions(rawValue: 0x0080)
    public static let setTeamData                 = Permissions(rawValue: 0x0100)
    public static let getMemberPermissions        = Permissions(rawValue: 0x0200)
    public static let getTeamConversations        = Permissions(rawValue: 0x0400)
    public static let deleteTeam                  = Permissions(rawValue: 0x0800)
    public static let setMemberPermissions        = Permissions(rawValue: 0x1000)

    // MARK: - Common Combined Values

    // It is currently guaranteed (verbally) that the BE will return the raw value
    // corresponding to one of these four bitmasks (roles). This is necessary
    // to establish a bijective mapping between these four bitmasks and the four
    // cases of the TeamRole enum.
    
    public static let partner: Permissions = [.createConversation, .getTeamConversations]
    public static let member:  Permissions = [.partner, .deleteConversation, .addRemoveConversationMember, .modifyConversationMetaData, .getMemberPermissions]
    public static let admin:   Permissions = [.member, .addTeamMember, .removeTeamMember, .setTeamData, .setMemberPermissions]
    public static let owner:   Permissions = [.admin, .getBilling, .setBilling, .deleteTeam]

}


// MARK: - Debugging


extension Permissions: CustomDebugStringConvertible {

    private static let descriptions: [Permissions: String] = [
        .createConversation: "CreateConversation",
        .deleteConversation: "DeleteConversation",
        .addTeamMember: "AddTeamMember",
        .removeTeamMember: "RemoveTeamMember",
        .addRemoveConversationMember: "AddRemoveConversationMember",
        .modifyConversationMetaData: "ModifyConversationMetaData",
        .getMemberPermissions: "GetMemberPermissions",
        .getTeamConversations: "GetTeamConversations",
        .getBilling : "GetBilling",
        .setBilling: "SetBilling",
        .setTeamData: "SetTeamData",
        .deleteTeam: "DeleteTeam",
        .setMemberPermissions: "SetMemberPermissions"
    ]

    public var debugDescription: String {
        return "[\(Permissions.descriptions.filter { contains($0.0) }.map { $0.1 }.joined(separator: ", "))]"
    }

}


extension Permissions: Hashable {

    public var hashValue : Int {
        return rawValue.hashValue
    }

}

// MARK: - Objective-C Interoperability

/// Represents a collection of individual `Permissions` options to allow
/// for Objective C compatibility. For most intents and purposes we are
/// only interested in the role of a user in determining various logic for
/// specific users.
///
@objc public enum TeamRole: Int {
    case none, partner, member, admin, owner
    
    public init(rawPermissions: Int64) {
        switch rawPermissions {
        case Permissions.partner.rawValue:
            self = .partner
        case Permissions.member.rawValue:
            self = .member
        case Permissions.admin.rawValue:
            self = .admin
        case Permissions.owner.rawValue:
            self = .owner
        default:
            self = .none
        }
    }
    
    /// The permissions granted to this role.
    public var permissions: Permissions {
        switch self {
        case .none:    return .none
        case .partner: return .partner
        case .member:  return .member
        case .admin:   return .admin
        case .owner:   return .owner
        }
    }
    
    /// Returns true if the role encompasses the given role.
    /// E.g An admin is a member, but a member is not an admin.
    public func isA(role: TeamRole) -> Bool {
        return hasPermissions(role.permissions)
    }
    
    
    /// Returns true if the role contains (all) the permissions.
    public func hasPermissions(_ permissions: Permissions) -> Bool {
        return self.permissions.isSuperset(of: permissions)
    }
}

extension Member {
    
    @objc public func setTeamRole(_ role: TeamRole) {
        permissions = role.permissions
    }
}
