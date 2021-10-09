

@objc
@objcMembers public class UserDisableSendMsgStatus: ZMManagedObject {
    
    @NSManaged public var block_time: Int64
    @NSManaged public var block_duration: Int64
    @NSManaged public var withConversation: ZMConversation?
    @NSManaged public var userid: String?
    @NSManaged public var needUpload: Bool
    
    public override func keysTrackedForLocalModifications() -> Set<String> {
        return [ZMConversationInfoBlockTimeKey]
    }
    
    public override static func entityName() -> String {
        return "UserDisableSendMsgStatus"
    }
    
    public override static func isTrackingLocalModifications() -> Bool {
        return true
    }
    
    public override static func sortKey() -> String? {
        return ZMConversationInfoBlockTimeKey
    }
    
    public override static func predicateForObjectsThatNeedToBeInsertedUpstream() -> NSPredicate? {
        return NSPredicate(format: "%K == YES", #keyPath(UserDisableSendMsgStatus.needUpload))
    }
    
    public override static func predicateForObjectsThatNeedToBeUpdatedUpstream() -> NSPredicate? {
        let baseModifiedPredicate = NSPredicate(format: "modifiedKeys != NULL AND %K == NO", #keyPath(UserDisableSendMsgStatus.needUpload))
        return baseModifiedPredicate
    }
    
}

extension UserDisableSendMsgStatus {
    
    @objc static public func delete(managedObjectContext: NSManagedObjectContext, conversationId: String?, userId: String?) {
        guard let cid = conversationId,
              let uid = userId,
              let uuid = UUID.init(uuidString: cid),
              let conversation = ZMConversation.init(remoteID: uuid, createIfNeeded: false, in: managedObjectContext)
              else {
            return
        }
        for status in conversation.membersSendMsgStatuses {
            if status.userid?.lowercased() == uid.lowercased() {
                managedObjectContext.delete(status)
                return
            }
        }
    }
    
    static public func update(managedObjectContext: NSManagedObjectContext, block_time: NSNumber?, block_duration: NSNumber?, user: String?, conversation: String?, fromPushChannel: Bool = false) {
        guard let block_time = block_time, let duration = block_duration, let u = user, let conv = conversation, let uuid = UUID(uuidString: conv) else {return}
        guard let conver = ZMConversation(remoteID: uuid, createIfNeeded: false, in: managedObjectContext) else {return}
        let insert = {
            let entry = UserDisableSendMsgStatus.insertNewObject(in: managedObjectContext)
            entry.block_time = block_time.int64Value
            entry.block_duration = duration.int64Value
            entry.userid = u
            entry.withConversation = conver
            if !fromPushChannel {
               entry.needUpload = true
            }
            conver.disableSendLastModifiedDate = Date()
        }
        var exist: Bool = false
        conver.membersSendMsgStatuses.forEach { (status) in
            if status.userid == u {
                status.block_time = block_time.int64Value
                status.block_duration = duration.int64Value
                if !fromPushChannel {
                    status.setLocallyModifiedKeys([ZMConversationInfoBlockTimeKey])
                }
                conver.disableSendLastModifiedDate = Date()
                exist = true
                return
            }
        }
        if !exist {
            insert()
        }
    }
    
    static public func getBlockTime(managedObjectContext: NSManagedObjectContext, user: String?, conversation: String?) -> NSNumber? {
        guard let user = user,
            let convString = conversation,
            let uuid = UUID.init(uuidString: convString),
            let conver = ZMConversation.init(remoteID: uuid, createIfNeeded: false, in: managedObjectContext) else {return nil}
        var blockTime: NSNumber?
        for status in conver.membersSendMsgStatuses {
            if status.userid == user {
               
                if status.block_time < Int64(Date().timeIntervalSince1970) && status.block_time != -1 {
                    blockTime = NSNumber(value: 0)
                    status.block_time = 0
                    managedObjectContext.saveOrRollback()
                    break
                }
                blockTime = NSNumber(value: status.block_time)
                break
            }
        }
        return blockTime
    }
    

    static public func create(from transportData: Dictionary<String,Any>?, managedObjectContext: NSManagedObjectContext, inConversation: String?) -> Void {
        guard let transportdata = transportData else {return}
        guard let members = transportdata["members"] as? Dictionary<String,Any> else {return}
        guard let others = members["others"] as? Array<Dictionary<String,Any>> else {return}
        guard let self_ = members["self"] as? Dictionary<String,Any> else {return}
        for other in others {
            guard let id = other["id"] as? String  else {continue}
            guard let block_time = other["block_time"] as? Int64 else {continue}
            guard let block_duration = other["block_duration"] as? Int64 else {continue}
            UserDisableSendMsgStatus.update(managedObjectContext: managedObjectContext, block_time: NSNumber.init(value: block_time), block_duration: NSNumber.init(value: block_duration), user: id, conversation: inConversation, fromPushChannel: true)
        }
        guard let self_blocktime = self_["block_time"] as? Int64 else {return}
        guard let self_blockduration = self_["block_duration"] as? Int64 else {return}
        let selfuser = ZMUser.selfUser(in: managedObjectContext).remoteIdentifier.transportString()
        UserDisableSendMsgStatus.update(managedObjectContext: managedObjectContext, block_time: NSNumber.init(value: self_blocktime), block_duration: NSNumber.init(value: self_blockduration), user: selfuser, conversation: inConversation, fromPushChannel: true)
    }
}
