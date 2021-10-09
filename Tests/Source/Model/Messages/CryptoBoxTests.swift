//
// 


import XCTest
import WireCryptobox
@testable import WireDataModel

class CryptoBoxTest: OtrBaseTest {
    
    func testThatCryptoBoxFolderIsForbiddenFromBackup() {
        // when
        let accountId = UUID()
        let accountFolder = StorageStack.accountFolder(accountIdentifier: accountId, applicationContainer: OtrBaseTest.sharedContainerURL)
        let keyStore = UserClientKeysStore(accountDirectory: accountFolder, applicationContainer: OtrBaseTest.sharedContainerURL)
        
        // then
        guard let values = try? keyStore.cryptoboxDirectory.resourceValues(forKeys: Set(arrayLiteral: .isExcludedFromBackupKey)) else {return XCTFail()}
        
        XCTAssertTrue(values.isExcludedFromBackup!)
    }
    
    func testThatCryptoBoxFolderIsMarkedForEncryption() {
        #if targetEnvironment(simulator)
            // File protection API is not available on simulator
            XCTAssertTrue(true)
            return
        #else
            // when
            UserClientKeysStore.setupBox()
            
            // then
            let attrs = try! NSFileManager.default.attributesOfItemAtPath(UserClientKeysStore.otrDirectoryURL.path)
            let fileProtectionAttr = (attrs[NSFileProtectionKey]! as! String)
            XCTAssertEqual(fileProtectionAttr, NSFileProtectionCompleteUntilFirstUserAuthentication)
        #endif
    }

}
