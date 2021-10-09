

import Foundation

@objc public enum MessageOperationStatus: UInt8 {
    case on
    case off
}

@objc public enum MessageOperationType: UInt16 {
    case illegal
    
    public var uniqueValue: String {
        switch self {
        case .illegal: return "illegal"
        }
    }
}

@objcMembers class Operation: ZMManagedObject {

    @NSManaged var state: Bool
    @NSManaged var type: String
    
    @NSManaged var message: ZMMessage?
    @NSManaged var operateUser: ZMUser?
    
    public static func insertOperation(
        _ type: MessageOperationType,
        status: MessageOperationStatus,
        byOperator user: ZMUser,
        onMessage message: ZMMessage
        ) -> Operation {
        
        let obj = insertNewObject(in: message.managedObjectContext!)
        obj.message = message
        obj.type = type.uniqueValue
        obj.state = status == .on
        obj.operateUser = user
        return obj
    }
    
    override class func entityName() -> String {
        return "Operation"
    }
}
