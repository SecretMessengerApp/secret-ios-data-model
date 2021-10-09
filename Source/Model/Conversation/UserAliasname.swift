

import UIKit

@objc
@objcMembers public class UserAliasname: ZMManagedObject {

    public enum Fields : String {
        case aliasName = "aliasName"
        case remoteIdentifier = "remoteIdentifier"
        case inConverstion = "inConverstion"
    }
    
    @NSManaged public var aliasName : String?
    @NSManaged public var remoteIdentifier : String?
    @NSManaged public var inConverstion : ZMConversation?
    
    public override func keysTrackedForLocalModifications() -> Set<String> {
        return []
    }
    
    public override static func entityName() -> String {
        return "UserAliasname"
    }
    
    public override static func sortKey() -> String? {
        return Fields.remoteIdentifier.rawValue
    }
    
    public override static func isTrackingLocalModifications() -> Bool {
        return false
    }
    
}

extension UserAliasname {
    
    static let ConversationAliasNamesKey = "ConversationAliasNamesKey"
    
    static let shared = UserDefaults.shared()
    
    static var alias: [String: String]?
    
    @objc static func getAliasName() {
        guard alias == nil else {
            return
        }
        guard let shared = shared else {return}
        if let als = shared.value(forKey: ConversationAliasNamesKey) as? [String: String] {
            alias = als
        } else {
            alias = [String: String]()
        }
    }
    
    static func sync() {
        guard let shared = shared else {return}
        shared.setValue(alias, forKey: ConversationAliasNamesKey)
        shared.synchronize()
    }
    
    @available(iOSApplicationExtension 9.0, *)
    @objc(updateFromAliasName:remoteIdentifier:managedObjectContext:inConversation:)
    static public func update(from aliasName: String?,remoteIdentifier: String?, managedObjectContext: NSManagedObjectContext, inConversation: ZMConversation? = nil) -> Void {
        
        guard let remoteid = remoteIdentifier else {return}
        
        guard let conv = inConversation, let cid = conv.remoteIdentifier?.transportString() else {
            return
        }
        
        let key = remoteid + "_" + cid
        
        alias?[key] = aliasName
        
        inConversation?.selfRemarkChangeTimestamp = Date()
        
    }
    
    @objc(createFromTransportData:managedObjectContext:inConversation:)
    static public func create(from transportData: Dictionary<String,Any>?, managedObjectContext: NSManagedObjectContext, inConversation:ZMConversation?) -> Void {
        guard let transportdata = transportData else {return}
        guard let members = transportdata["members"] as? Dictionary<String,Any> else {return}
        guard let others = members["others"] as? Array<Dictionary<String,Any>> else {return}
        guard let self_ = members["self"] as? Dictionary<String,Any> else {return}
        guard let cid = inConversation?.remoteIdentifier?.transportString() else {
            return
        }
        for other in others {
            guard let id = other["id"] as? String else {continue}
            guard let aliasname = other["aliasname"] as? String else {continue}
            let key = id + "_" + cid
            alias?[key] = aliasname
        }
        
        guard let self_id = self_["id"] as? String else {return}
        guard let self_aliasname = self_["alias_name_ref"] as? String else {return}
        let key = self_id + "_" + cid
        alias?[key] = self_aliasname
    }
    
    @objc(getUserInConversationAliasNameFrom:userId:)
    static public func getUserInConversationAliasName(from conversation: ZMConversation?, userId:String?) -> String? {
        
        guard let conv = conversation else {return nil}
        guard let userid = userId else {return nil}
        guard let cid = conv.remoteIdentifier?.transportString() else {return nil}
        let key = userid + "_" + cid
        if let name = alias?[key] {
            return name
        }
       
        let aliasNameEntry =  conv.membersAliasname.first { (aliasname) -> Bool in
            return aliasname.remoteIdentifier == userid
        }
        if let aliasName = aliasNameEntry?.aliasName {
            alias?[key] = aliasName
            return aliasName
        }
        return nil
    }
}
