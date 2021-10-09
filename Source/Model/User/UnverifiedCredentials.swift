//
//

import Foundation

/**
 * Credentials that needs to be verified; either a phone number or an e-mail address.
 */

public enum UnverifiedCredentials: Equatable {

    /// The e-mail that needs to be verified.
    case email(String)

    /// The phone number that needs to be verified.
    case phone(String)

    /// The label identifying the type of credential, that can be used in backend requests.
    public var type: String {
        switch self {
        case .email: return "email"
        case .phone: return "phone"
        }
    }

    /// The raw value representing the credentials provided by the user.
    public var rawValue: String {
        switch self {
        case .email(let email): return email
        case .phone(let phone): return phone
        }
    }
}
