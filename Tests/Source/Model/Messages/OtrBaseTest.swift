//
// 


import Foundation
import XCTest

class OtrBaseTest: XCTestCase {
    override func setUp() {
        super.setUp()
        
        //clean stored cryptobox files
        if let items =  (try? FileManager.default.contentsOfDirectory(at: OtrBaseTest.sharedContainerURL, includingPropertiesForKeys: nil, options: [])) {
            items.forEach{ try? FileManager.default.removeItem(at: $0) }
        }
    }
    
    static var sharedContainerURL : URL {
        return try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }
    
    static func otrDirectoryURL(accountIdentifier: UUID) -> URL {
        let accountDirectory = StorageStack.accountFolder(accountIdentifier: accountIdentifier, applicationContainer: self.sharedContainerURL)
        return FileManager.keyStoreURL(accountDirectory: accountDirectory, createParentIfNeeded: true)
    }
    
    static var legacyOtrDirectory : URL {
        return FileManager.keyStoreURL(accountDirectory: self.sharedContainerURL, createParentIfNeeded: true)
    }
    
    static func legacyAccountOtrDirectory(accountIdentifier: UUID) -> URL {
        return FileManager.keyStoreURL(accountDirectory: self.sharedContainerURL.appendingPathComponent(accountIdentifier.uuidString), createParentIfNeeded: true)
    }
    
}
