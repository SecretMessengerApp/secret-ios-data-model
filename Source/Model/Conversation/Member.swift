//
//


@objcMembers public class Member: ZMManagedObject {

    @NSManaged public var team: Team?
    @NSManaged public var user: ZMUser?
    @NSManaged public var createdBy: ZMUser?
    @NSManaged public var createdAt: Date?
    @NSManaged public var remoteIdentifier_data : Data?
    @NSManaged private var permissionsRawValue: Int64

    public var permissions: Permissions {
        get {
            return Permissions(rawValue: permissionsRawValue)            
        }
        set {
            permissionsRawValue = newValue.rawValue            
        }
    }

    public override static func entityName() -> String {
        return "Member"
    }

    public override static func isTrackingLocalModifications() -> Bool {
        return false
    }

    public override static func defaultSortDescriptors() -> [NSSortDescriptor] {
        return []
    }
    
    public var remoteIdentifier: UUID? {
        get {
            guard let data = remoteIdentifier_data else { return nil }
            return UUID(data: data)
        }
        set {
            remoteIdentifier_data = newValue?.uuidData
        }
    }

    @objc(getOrCreateMemberForUser:inTeam:context:)
    public static func getOrCreateMember(for user: ZMUser, in team: Team, context: NSManagedObjectContext) -> Member {
//        precondition(context.zm_isSyncContext)
        
        if let existing = user.membership {
            return existing
        }
        else if let userId = user.remoteIdentifier, let existing = Member.fetch(withRemoteIdentifier: userId, in: context) {
            return existing
        }

        let member = insertNewObject(in: context)
        member.team = team
        member.user = user
        member.remoteIdentifier = user.remoteIdentifier
        return member
    }

}


// MARK: - Transport


fileprivate enum ResponseKey: String {
    case user, permissions, createdBy = "created_by", createdAt = "created_at"

    enum Permissions: String {
        case `self`, copy
    }
}


extension Member {

    @discardableResult
    public static func createOrUpdate(with payload: [String: Any], in team: Team, context: NSManagedObjectContext) -> Member? {
        guard let id = (payload[ResponseKey.user.rawValue] as? String).flatMap(UUID.init),
            let user = ZMUser.fetchAndMerge(with: id, createIfNeeded: true, in: context) else { return nil }

        
        let createdAt = (payload[ResponseKey.createdAt.rawValue] as? String).flatMap(NSDate.init(transport:)) as Date?
        let createdBy = (payload[ResponseKey.createdBy.rawValue] as? String).flatMap(UUID.init)
        let member = getOrCreateMember(for: user, in: team, context: context)
        
        member.updatePermissions(with: payload)
        member.createdAt = createdAt
        member.createdBy = createdBy.flatMap({ ZMUser.fetchAndMerge(with: $0, createIfNeeded: true, in: context) })
        
        return member
    }

    public func updatePermissions(with payload: [String: Any]) {
        guard let userID = (payload[ResponseKey.user.rawValue] as? String).flatMap(UUID.init) else { return }
        precondition(remoteIdentifier == userID, "Trying to update member with non-matching payload: \(payload), \(self)")
        guard let permissionsPayload = payload[ResponseKey.permissions.rawValue] as? [String: Any] else { return }
        guard let selfPermissions = permissionsPayload[ResponseKey.Permissions.`self`.rawValue] as? NSNumber else { return }
        permissions = Permissions(rawValue: selfPermissions.int64Value)
    }

}
