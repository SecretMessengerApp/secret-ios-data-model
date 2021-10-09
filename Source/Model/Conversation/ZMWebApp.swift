

import UIKit

enum WebAppLoadMode: Int {
    case secretUrlLoad = 0
    case zipLoad = 1
    case remoteUrlLoad = 2
}
enum WebAppUpdateMode: Int {
    case noUpdate = 0
    case incrementUpdate = 1
    case allUpdate = 2           
}

public let ZMWebAppIdentifierKey = "appId"

@objcMembers public class ZMWebApp: ZMManagedObject {
    

    
    @NSManaged public var appId: String
    @NSManaged public var name: String
    @NSManaged public var intro: String?
    @NSManaged public var brief: String?
    @NSManaged public var icon: String
    @NSManaged public var url: String
    @NSManaged public var updateUrl: String?
    @NSManaged public var owner: String?
    @NSManaged public var version: String?
    @NSManaged public var type: Int64
    @NSManaged public var index: Int64
    @NSManaged public var loadModel: Int64
    @NSManaged public var conversations: Set<ZMConversation>
    
    public override static func entityName() -> String {
        return "WebApp"
    }
    
    public override static func isTrackingLocalModifications() -> Bool {
        return false
    }
    
}

public extension ZMWebApp {
    
    @objc public static func createOrUpdateWebApp(_ payloadData: [String: AnyObject], context: NSManagedObjectContext) -> ZMWebApp? {
        guard let id = payloadData["app_id"] as? String
            else { return nil }
        let payloadAsDictionary = payloadData as NSDictionary
        let name = payloadAsDictionary.string(forKey: "app_name")
        let intro = payloadAsDictionary.optionalString(forKey: "intro")
        let brief = payloadAsDictionary.optionalString(forKey: "brief")
        let icon = payloadAsDictionary.string(forKey: "app_icon")
        let url = payloadAsDictionary.string(forKey: "app_url")
        let updateUrl = payloadAsDictionary.optionalString(forKey: "update_url")
        let owner = payloadAsDictionary.optionalString(forKey: "owner")
        let version = payloadAsDictionary.optionalString(forKey: "version")
        
        let fetchedWebApp = fetchExistingWebApp(with: id, in: context)
        let webApp = fetchedWebApp ?? ZMWebApp.insertNewObject(in: context)
        webApp.appId = id
        webApp.name = name ?? ""
        webApp.intro = intro
        webApp.brief = brief
        webApp.icon = icon ?? ""
        webApp.url = url ?? ""
        webApp.updateUrl = updateUrl
        webApp.owner = owner
        webApp.version = version
            if let type = payloadAsDictionary.number(forKey: "type")?.intValue {
                webApp.type = Int64(type)
            }
            if let index = payloadAsDictionary.number(forKey: "index")?.intValue {
                webApp.index = Int64(index)
            }
            if let loadModel = payloadAsDictionary.number(forKey: "load_model")?.intValue {
                webApp.loadModel = Int64(loadModel)
            }
        
        return webApp
    }
    
    @objc public static func fetchExistingWebApp(with remoteIdentifier: String, in context: NSManagedObjectContext) -> ZMWebApp? {
        let fetchRequest = NSFetchRequest<ZMWebApp>(entityName: ZMWebApp.entityName())
        fetchRequest.predicate = NSPredicate(format: "%K == %@", ZMWebAppIdentifierKey, remoteIdentifier)
        fetchRequest.fetchLimit = 1
        
        return context.fetchOrAssert(request: fetchRequest).first
    }
    
}
