//
//


import XCTest
import WireUtilities
import Contacts

class AddressBookEntryTests : ZMBaseManagedObjectTest {

    func testThatItReturnsTrackedKeys() {
        
        // GIVEN
        let entry = AddressBookEntry.insertNewObject(in: self.uiMOC)
        
        // WHEN
        let keys = entry.keysTrackedForLocalModifications()
        
        // THEN
        XCTAssertTrue(keys.isEmpty)
    }
    
    @available(iOS 9.0, *)
    func testThatItCreatesEntryFromContact() {
        
        // GIVEN
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        let contact = CNMutableContact()
        contact.familyName = "TheFamily"
        contact.givenName = "MyName"
        contact.emailAddresses.append(CNLabeledValue(label: "home", value: "foo@example.com"))
        contact.phoneNumbers.append(CNLabeledValue(label: "home", value: CNPhoneNumber(stringValue: "+15557654321")))
        
        // WHEN
        let sut = AddressBookEntry.create(from: contact, managedObjectContext: self.uiMOC, user: user)
        
        // THEN
        XCTAssertEqual(sut.localIdentifier, contact.identifier)
        XCTAssertEqual(sut.cachedName, "MyName TheFamily")
        XCTAssertEqual(sut.user, user)
        
    }
}
