//
//


import XCTest
@testable import WireDataModel

class UserClientObserverTests: NotificationDispatcherTestBase {
    
    var clientObserver : TestUserClientObserver!
    
    override func setUp() {
        super.setUp()
        clientObserver = TestUserClientObserver()
    }
    
    override func tearDown() {
        clientObserver = nil
        super.tearDown()
    }
    
    let userInfoKeys: Set<String> = [
        UserClientChangeInfoKey.TrustedByClientsChanged.rawValue,
        UserClientChangeInfoKey.IgnoredByClientsChanged.rawValue,
        UserClientChangeInfoKey.FingerprintChanged.rawValue
    ]
    
    func checkThatItNotifiesTheObserverOfAChange(_ userClient : UserClient, modifier: (UserClient) -> Void, expectedChangedFields: Set<String>, customAffectedKeys: AffectedKeys? = nil) {
        
        // given
        self.uiMOC.saveOrRollback()
        
        let token = UserClientChangeInfo.add(observer: clientObserver, for: userClient)
        
        // when
        modifier(userClient)
        self.uiMOC.saveOrRollback()
        
        // then
        let changeCount = clientObserver.receivedChangeInfo.count
        XCTAssertEqual(changeCount, 1)
        
        // and when
        self.uiMOC.saveOrRollback()
        
        // then
        withExtendedLifetime(token) { () -> () in
            XCTAssertEqual(clientObserver.receivedChangeInfo.count, changeCount, "Should not have changed further once")
            
            guard let changes = clientObserver.receivedChangeInfo.first else { return }
            changes.checkForExpectedChangeFields(userInfoKeys: userInfoKeys,
                                                 expectedChangedFields: expectedChangedFields)
        }
    }
    
    func testThatItNotifiesTheObserverOfTrustedByClientsChange() {
        // given
        let client = UserClient.insertNewObject(in: self.uiMOC)
        let otherClient = UserClient.insertNewObject(in: self.uiMOC)
        self.uiMOC.saveOrRollback()
        
        // when
        self.checkThatItNotifiesTheObserverOfAChange(client,
                                                     modifier: { otherClient.trustClient($0) },
                                                     expectedChangedFields: [UserClientChangeInfoKey.TrustedByClientsChanged.rawValue]
        )
        
        XCTAssertTrue(client.trustedByClients.contains(otherClient))
    }
    
    func testThatItNotifiesTheObserverOfIgnoredByClientsChange() {
        // given
        let client = UserClient.insertNewObject(in: self.uiMOC)
        let otherClient = UserClient.insertNewObject(in: self.uiMOC)
        otherClient.trustClient(client)
        self.uiMOC.saveOrRollback()
        
        // when
        self.checkThatItNotifiesTheObserverOfAChange(client,
                                                     modifier: { otherClient.ignoreClient($0) },
                                                     expectedChangedFields: [
                                                        UserClientChangeInfoKey.IgnoredByClientsChanged.rawValue,
                                                        UserClientChangeInfoKey.TrustedByClientsChanged.rawValue
            ]
        )
        
        XCTAssertTrue(client.ignoredByClients.contains(otherClient))
    }
    
    func testThatItNotifiesTheObserverOfFingerprintChange() {
        // given
        let client = UserClient.insertNewObject(in: self.uiMOC)
        client.fingerprint = NSString.createAlphanumerical().data(using: String.Encoding.utf8)
        self.uiMOC.saveOrRollback()
        
        let newFingerprint = NSString.createAlphanumerical().data(using: String.Encoding.utf8)
        
        // when
        self.checkThatItNotifiesTheObserverOfAChange(client,
                                                     modifier: { _ in client.fingerprint = newFingerprint },
                                                     expectedChangedFields: [UserClientChangeInfoKey.FingerprintChanged.rawValue]
        )
        
        XCTAssertTrue(client.fingerprint == newFingerprint)
    }
    
    func testThatItStopsNotifyingAfterUnregisteringTheToken() {
        // given
        let client = UserClient.insertNewObject(in: self.uiMOC)
        let otherClient = UserClient.insertNewObject(in: self.uiMOC)
        otherClient.trustClient(client)
        self.uiMOC.saveOrRollback()
        
        let otherObserver = TestUserClientObserver()
        _ = UserClientChangeInfo.add(observer: otherObserver, for: client) // not storing the token
        
        // when
        otherClient.ignoreClient(client)
        self.uiMOC.saveOrRollback()
        
        XCTAssertEqual(otherObserver.receivedChangeInfo.count, 0)
    }
    
}
