//
//

import Foundation
import Contacts
import AddressBook

@objcMembers public class AddressBookEntry : ZMManagedObject {
    
    public enum Fields : String {
        case localIdentifier = "localIdentifier"
        case user = "user"
        case cachedName = "cachedName"
    }
    
    @NSManaged public var localIdentifier : String?
    @NSManaged public var user : ZMUser?
    @NSManaged public var cachedName : String?
    
    public override func keysTrackedForLocalModifications() -> Set<String> {
        return []
    }
    
    public override static func entityName() -> String {
        return "AddressBookEntry"
    }
    
    public override static func sortKey() -> String? {
        return Fields.localIdentifier.rawValue
    }

    public override static func isTrackingLocalModifications() -> Bool {
        return false
    }
    
}

extension AddressBookEntry {
    
    @available(iOSApplicationExtension 9.0, *)
    @objc(createFromContact:managedObjectContext:user:)
    static public func create(from contact: CNContact, managedObjectContext: NSManagedObjectContext, user: ZMUser? = nil) -> AddressBookEntry {
        let entry = AddressBookEntry.insertNewObject(in: managedObjectContext)
        entry.localIdentifier = contact.identifier
        entry.cachedName = CNContactFormatter.string(from: contact, style: .fullName)
        entry.user = user
        return entry
    }
}

