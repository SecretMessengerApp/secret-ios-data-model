

@objc
@objcMembers public class ServiceMessage: ZMManagedObject {
    
    @NSManaged public var type: String
    @NSManaged public var text: String?
    @NSManaged public var url: String?
    @NSManaged public var appid: String?
    @NSManaged public var isRead: Bool
    @NSManaged public var isAnimated: Bool
    
    @NSManaged public var systemMessage: ZMSystemMessage?
    
    public override static func entityName() -> String {
        return "ServiceMessage"
    }
    
    public override static func isTrackingLocalModifications() -> Bool {
        return false
    }
    
    public func configData(with json: [String: Any]) {
        if let msgType = json["msgType"] as? Int {
            self.type = "\(msgType)"
        } else {
            self.type = ""
        }
        if let msgData = json["msgData"] as? [String: Any] {
            self.text = msgData["text"] as? String
            self.url = msgData["url"] as? String
            self.appid = msgData["appid"] as? String
        }
    }
}
