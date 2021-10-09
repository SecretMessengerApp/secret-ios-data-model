//
//

import XCTest

class BackupMetadataTests: XCTestCase {
    
    var url: URL!
    
    override func setUp() {
        super.setUp()
        let documentsURL = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        url = URL(fileURLWithPath: documentsURL).appendingPathComponent(name)
    }
    
    override func tearDown() {
        try? FileManager.default.removeItem(at: url)
        url = nil
        super.tearDown()
    }
    
    func testThatItWritesMetadataToURL() throws {
        // Given
        let date = Date()
        let userIdentifier = UUID.create()
        let clientIdentifier = UUID.create().transportString()
        let sut = BackupMetadata(
            appVersion: "3.9",
            modelVersion: "24.2.8",
            creationTime: date,
            userIdentifier: userIdentifier,
            clientIdentifier: clientIdentifier
        )
        
        // When & Then
        try sut.write(to: url)
        XCTAssert(FileManager.default.fileExists(atPath: url.path))
    }
    
    func testThatItReadsMetadataFromURL() throws {
        // Given
        let date = Date()
        let userIdentifier = UUID.create()
        let clientIdentifier = UUID.create().transportString()
        let sut = BackupMetadata(
            appVersion: "3.9",
            modelVersion: "24.2.8",
            creationTime: date,
            userIdentifier: userIdentifier,
            clientIdentifier: clientIdentifier
        )
        
        try sut.write(to: url)
        
        // When
        let decoded = try BackupMetadata(url: url)
        
        // Then
        XCTAssert(decoded == sut)
    }
    
    func testThatItVerifiesValidMetadata() {
        // Given
        let userIdentifier = UUID.create()
        
        let sut = BackupMetadata(
            appVersion: "3",
            modelVersion: "3.212",
            userIdentifier: userIdentifier,
            clientIdentifier: UUID.create().transportString()
        )
        
        // When & Then
        let provider = MockProvider(version: "4.1.23")
        XCTAssertNil(sut.verify(using: userIdentifier, modelVersionProvider: provider))
    }
    
    func testThatItReturnsAnErrorForNewerAppVersionBackupVerification() {
        // Given
        let userIdentifier = UUID.create()
        
        let sut = BackupMetadata(
            appVersion: "3.1",
            modelVersion: "24.2.8",
            userIdentifier: userIdentifier,
            clientIdentifier: UUID.create().transportString()
        )
        
        // When
        let provider = MockProvider(version: "2.9.12")
        let error = sut.verify(using: userIdentifier, modelVersionProvider: provider)
        
        // Then
        XCTAssertEqual(error, BackupMetadata.VerificationError.backupFromNewerAppVersion)
    }
    
    func testThatItReturnsAnErrorForWrongUser() {
        // Given
        let userIdentifier = UUID.create()
        
        let sut = BackupMetadata(
            appVersion: "3.1",
            modelVersion: "24.2.8",
            userIdentifier: userIdentifier,
            clientIdentifier: UUID.create().transportString()
        )
        
        // When
        let provider = MockProvider(version: "3.1.0")
        let error = sut.verify(using: .create(), modelVersionProvider: provider)
        
        // Then
        XCTAssertEqual(error, BackupMetadata.VerificationError.userMismatch)
    }
    
}

// MARK: - Helper

fileprivate class MockProvider: VersionProvider {
    
    var version: String
    
    init(version: String) {
        self.version = version
    }
}
