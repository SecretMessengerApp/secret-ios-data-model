//
//

import Foundation

/**
 * Contains the credentials used by a user to sign into the app.
 */

@objc public class LoginCredentials: NSObject, Codable {

    @objc public let emailAddress: String?
    @objc public let phoneNumber: String?
    @objc public let hasPassword: Bool
    @objc public let usesCompanyLogin: Bool

    public init(emailAddress: String?, phoneNumber: String?, hasPassword: Bool, usesCompanyLogin: Bool) {
        self.emailAddress = emailAddress
        self.phoneNumber = phoneNumber
        self.hasPassword = hasPassword
        self.usesCompanyLogin = usesCompanyLogin
    }

    public override var debugDescription: String {
        return "<LoginCredentials>:\n\temailAddress: \(String(describing: emailAddress))\n\tphoneNumber: \(String(describing: phoneNumber))\n\thasPassword: \(hasPassword)\n\tusesCompanyLogin: \(usesCompanyLogin)"
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let otherCredentials = object as? LoginCredentials else {
            return false
        }

        let emailEquals = self.emailAddress == otherCredentials.emailAddress
        let phoneNumberEquals = self.phoneNumber == otherCredentials.phoneNumber
        let passwordEquals = self.hasPassword == otherCredentials.hasPassword
        let companyLoginEquals = self.usesCompanyLogin == otherCredentials.usesCompanyLogin

        return emailEquals && phoneNumberEquals && passwordEquals && companyLoginEquals
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(emailAddress)
        hasher.combine(phoneNumber)
        hasher.combine(hasPassword)
        hasher.combine(usesCompanyLogin)
        return hasher.finalize()
    }

}
