//
//


import Foundation
@testable import WireDataModel


final class AccountTests: ZMConversationTestsBase {

    func testThatItCanSerializeAnAccountToDisk() throws {
        // given
        let url = URL(fileURLWithPath: NSTemporaryDirectory() + "/AccountTests")
        defer { try? FileManager.default.removeItem(at: url) }

        let credentials = LoginCredentials(emailAddress: "bruno@example.com", phoneNumber: nil, hasPassword: true, usesCompanyLogin: false)

        let account = Account(
            userName: "Bruno",
            userIdentifier: .create(),
            teamName: "Wire",
            imageData: verySmallJPEGData(),
            teamImageData: verySmallJPEGData(),
            loginCredentials: credentials
        )

        // when
        try account.write(to: url)

        // then the test did not fail
    }

    func testThatItCanLoadAnAccountFromDiskWithoutLoginCredentials() throws {
        // given
        let url = URL(fileURLWithPath: NSTemporaryDirectory() + "/AccountTests")
        defer { try? FileManager.default.removeItem(at: url) }
        let userName = "Bruno", team = "Wire", id = UUID.create(), image = verySmallJPEGData(), count = 14

        // we create and store an account
        do {
            let account = Account(userName: userName,
                                  userIdentifier: id,
                                  teamName: team,
                                  imageData: image,
                                  teamImageData: image,
                                  unreadConversationCount: count,
                                  loginCredentials: nil)
            try account.write(to: url)
        }

        // when
        guard let account = Account.load(from: url) else { return XCTFail("Unable to load account") }

        // then
        XCTAssertEqual(account.userName, userName)
        XCTAssertEqual(account.teamName, team)
        XCTAssertEqual(account.userIdentifier, id)
        XCTAssertEqual(account.imageData, image)
        XCTAssertEqual(account.teamImageData, image)
        XCTAssertEqual(account.unreadConversationCount, count)
        XCTAssertNil(account.loginCredentials)
    }

    func testThatItCanLoadAnAccountFromDiskWithLoginCredentials() throws {
        // given
        let url = URL(fileURLWithPath: NSTemporaryDirectory() + "/AccountTests")
        defer { try? FileManager.default.removeItem(at: url) }
        let userName = "Bruno", team = "Wire", id = UUID.create(), image = verySmallJPEGData(), count = 14
        let credentials = LoginCredentials(emailAddress: "bruno@example.com", phoneNumber: nil, hasPassword: true, usesCompanyLogin: false)

        // we create and store an account
        do {
            let account = Account(userName: userName,
                                  userIdentifier: id,
                                  teamName: team,
                                  imageData: image,
                                  teamImageData: image,
                                  unreadConversationCount: count,
                                  loginCredentials: credentials)
            try account.write(to: url)
        }

        // when
        guard let account = Account.load(from: url) else { return XCTFail("Unable to load account") }

        // then
        XCTAssertEqual(account.userName, userName)
        XCTAssertEqual(account.teamName, team)
        XCTAssertEqual(account.userIdentifier, id)
        XCTAssertEqual(account.imageData, image)
        XCTAssertEqual(account.teamImageData, image)
        XCTAssertEqual(account.unreadConversationCount, count)
        XCTAssertEqual(account.loginCredentials, credentials)
    }


    func testThatAccountsAreEqualWhenNotImportantPropertiesAreDifferent() {
        // given
        let userName = "Bruno", team = "Wire", id = UUID.create(), image = verySmallJPEGData(), count = 14

        let account = Account(userName: userName,
                              userIdentifier: id,
                              teamName: team,
                              imageData: image,
                              teamImageData: image,
                              unreadConversationCount: count)

        let sameAccount = Account(userName: "",
                                  userIdentifier: id,
                                  teamName: "",
                                  imageData: nil,
                                  teamImageData: nil,
                                  unreadConversationCount: 0)

        XCTAssertEqual(account, sameAccount)
    }

}
