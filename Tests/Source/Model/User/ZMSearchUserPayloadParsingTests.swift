//
//

import XCTest
@testable import WireDataModel

class ZMSearchUserPayloadParsingTests: ZMBaseManagedObjectTest {
    func testThatItParsesTheBasicPayload() {
        // given
        let uuid = UUID()
        let payload: [String: Any] = ["name": "A user that was found",
                                      "handle": "@user",
                                      "accent_id": 5,
                                      "id": uuid.transportString()]
        
        // when
        let user = ZMSearchUser.searchUser(from: payload, contextProvider: self)!
        
        // then
        XCTAssertEqual(user.name, "A user that was found")
        XCTAssertEqual(user.handle, "@user")
        XCTAssertEqual(user.remoteIdentifier, uuid)
        XCTAssertEqual(user.accentColorValue, ZMAccentColor.init(rawValue: 5))
        XCTAssertFalse(user.isServiceUser)
        XCTAssertTrue(user.canBeConnected)
    }
    
    func testThatItParsesService_ProviderIdentifier() throws {
        // given
        let uuid = UUID()
        let provider = UUID()
        let payload: [String: Any] = ["name": "A user that was found",
                                      "handle": "@user",
                                      "accent_id": 5,
                                      "id": uuid.transportString(),
                                      "summary": "Short summary",
                                      "provider": provider.transportString()]
        
        // when
        let user = ZMSearchUser.searchUser(from: payload, contextProvider: self)!
        
        // then
        XCTAssertTrue(user.isServiceUser)
        XCTAssertEqual(user.summary, "Short summary")
        XCTAssertEqual(user.providerIdentifier, provider.transportString())
        XCTAssertEqual(user.serviceIdentifier, uuid.transportString())
        XCTAssertFalse(user.canBeConnected)
    }
    
    func testThatItParsesService_ImageIdentifier() throws {
        // given
        let uuid = UUID()
        let provider = UUID()
        let assetKey = "1234567890-ASSET-KEY"
        let payload: [String: Any] = ["name": "A user that was found",
                                      "handle": "@user",
                                      "accent_id": 5,
                                      "id": uuid.transportString(),
                                      "provider": provider.transportString(),
                                      "assets": [["type": "image",
                                                  "size": "preview",
                                                  "key": assetKey]]]
        
        // when
        let searchUser = ZMSearchUser.searchUser(from: payload, contextProvider: self)!
        
        // then
        XCTAssertEqual(searchUser.assetKeys?.preview, assetKey)
    }
    
    func testThatItParsesService_IgnoresOtherImageIdentifier() throws {
        // given
        let uuid = UUID()
        let provider = UUID()
        let assetKey = "1234567890-ASSET-KEY"
        let payload: [String: Any] = ["name": "A user that was found",
                                      "handle": "@user",
                                      "accent_id": 5,
                                      "id": uuid.transportString(),
                                      "provider": provider.transportString(),
                                      "assets": [["type": "image",
                                                  "size": "full",
                                                  "key": assetKey]]]
        
        // when
        let searchUser = ZMSearchUser.searchUser(from: payload, contextProvider: self)!
        
        // then
        XCTAssertNil(searchUser.assetKeys)
    }
    
    
    func testThatCachedSearchUserIsReturnedFromPayloadConstructor() throws {
        // given
        let uuid = UUID()
        let provider = UUID()
        let assetKey = "1234567890-ASSET-KEY"
        let payload: [String: Any] = ["name": "A user that was found",
                                      "handle": "@user",
                                      "accent_id": 5,
                                      "id": uuid.transportString(),
                                      "provider": provider.transportString(),
                                      "assets": [["type": "image",
                                                  "size": "preview",
                                                  "key": assetKey]]]
        
        let searchUser1 = ZMSearchUser.searchUser(from: payload, contextProvider: self)!
        
        // when
        let searchUser2 = ZMSearchUser.searchUser(from: payload, contextProvider: self)!
        
        // then
        XCTAssertNotNil(searchUser2)
        XCTAssertEqual(searchUser1, searchUser2)
    }
    
    func testThatCachedSearchUserIsUpdatedWithLocalUser() throws {
        // given
        let uuid = UUID()
        let provider = UUID()
        let assetKey = "1234567890-ASSET-KEY"
        let payload: [String: Any] = ["name": "A user that was found",
                                      "handle": "@user",
                                      "accent_id": 5,
                                      "id": uuid.transportString(),
                                      "provider": provider.transportString(),
                                      "assets": [["type": "image",
                                                  "size": "preview",
                                                  "key": assetKey]]]
        
        let searchUser1 = ZMSearchUser.searchUser(from: payload, contextProvider: self)!
        XCTAssertNil(searchUser1.user)
        
        let localUser = ZMUser.insertNewObject(in: uiMOC)
        localUser.remoteIdentifier = uuid
        
        // when
        let searchUser2 = ZMSearchUser.searchUser(from: payload, contextProvider: self)
        
        // then
        XCTAssertNotNil(searchUser2)
        XCTAssertEqual(searchUser1, searchUser2)
        XCTAssertEqual(searchUser2?.user, localUser)
    }
}


extension ZMSearchUserPayloadParsingTests: ZMManagedObjectContextProvider {
    var managedObjectContext: NSManagedObjectContext! {
        return self.uiMOC
    }
    
    var syncManagedObjectContext: NSManagedObjectContext! {
        return self.syncMOC
    }
}
