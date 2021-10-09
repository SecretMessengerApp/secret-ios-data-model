//
//

import XCTest
@testable import WireDataModel

final class PushTokenTests: XCTestCase {

    var sut: PushToken!
    
    override func setUp() {
        sut = PushToken(deviceToken: Data(bytes: [0x01, 0x02, 0x03]), appIdentifier: "some", transportType: "some", isRegistered: true)

        super.setUp()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testThatTokenIsEncodedProperly() {
        XCTAssertEqual(sut.deviceTokenString, "010203")
    }

    func testThatItReturnsCopyMarkedForDownload() {
        let toDownload = sut.markToDownload()
        XCTAssertFalse(sut.isMarkedForDownload)
        XCTAssertTrue(toDownload.isMarkedForDownload)
    }

    func testThatItReturnsCopyMarkedForDelete() {
        let toDelete = sut.markToDelete()
        XCTAssertFalse(sut.isMarkedForDeletion)
        XCTAssertTrue(toDelete.isMarkedForDeletion)
    }

    func testThatItResetsFlags() {
        let toDelete = sut.markToDelete()
        let toDownload = toDelete.markToDownload()
        let reset = toDownload.resetFlags()

        XCTAssertTrue(toDelete.isMarkedForDeletion)
        XCTAssertFalse(toDelete.isMarkedForDownload)

        XCTAssertTrue(toDownload.isMarkedForDownload)
        XCTAssertTrue(toDownload.isMarkedForDownload)

        XCTAssertFalse(reset.isMarkedForDownload)
        XCTAssertFalse(reset.isMarkedForDownload)
    }
}
