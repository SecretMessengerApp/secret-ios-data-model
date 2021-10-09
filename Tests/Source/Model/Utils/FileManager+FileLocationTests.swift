//
//


import Foundation

class FileManager_CryptoboxTests : XCTestCase {
    
    func testThatItReturnsTheCryptoboxPath(){
        // given
        let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        
        // when
        let storeURL = FileManager.keyStoreURL(accountDirectory: url, createParentIfNeeded: false)
        
        // then
        var components = storeURL.pathComponents
        
        guard !components.isEmpty else { return XCTFail() }
        let otrComp = components.removeLast()
        XCTAssertEqual(otrComp, FileManager.keyStoreFolderPrefix)
        XCTAssertEqual(components, url.pathComponents)
    }
    
    func testThatItCreatesTheParentDirectoryIfNeededAndExcludesItFromBackup(){
        // given
        let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        
        // when
        let storeURL = FileManager.keyStoreURL(accountDirectory: url, createParentIfNeeded: true)
        
        // then
        let parentURL = storeURL.deletingLastPathComponent()
        var isDirectory : ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: parentURL.path, isDirectory:&isDirectory))
        XCTAssertTrue(isDirectory.boolValue)
        XCTAssertTrue(parentURL.isExcludedFromBackup)
        
        try? FileManager.default.removeItem(at:parentURL)
    }
}


class FileManager_CacheTests : XCTestCase {

    func testThatItReturnsTheCachesDirectory_WithAccountId(){
        // given
        let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let accountId = UUID()
        
        // when
        let cachesURL = FileManager.default.cachesURLForAccount(with: accountId, in: url)
        
        // then
        var components = cachesURL.pathComponents
        
        guard !components.isEmpty else { return XCTFail() }
        let accountIdComp = components.removeLast()
        XCTAssertEqual(accountIdComp, FileManager.cachesFolderPrefix + "-" + accountId.uuidString)
        
        guard !components.isEmpty else { return XCTFail() }
        let cachesComp = components.removeLast()
        XCTAssertEqual(cachesComp, "Caches")
        
        guard !components.isEmpty else { return XCTFail() }
        let libraryComp = components.removeLast()
        XCTAssertEqual(libraryComp, "Library")
        
        XCTAssertEqual(components, url.pathComponents)
    }
    
    
    func testThatItReturnsTheCachesDirectory_WithoutAccountId(){
        // given
        let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        
        // when
        let cachesURL = FileManager.default.cachesURLForAccount(with: nil, in: url)
        
        // then
        var components = cachesURL.pathComponents
        
        guard !components.isEmpty else { return XCTFail() }
        let cachesComp = components.removeLast()
        XCTAssertEqual(cachesComp, "Caches")
        
        guard !components.isEmpty else { return XCTFail() }
        let libraryComp = components.removeLast()
        XCTAssertEqual(libraryComp, "Library")
        
        XCTAssertEqual(components, url.pathComponents)
    }
}
