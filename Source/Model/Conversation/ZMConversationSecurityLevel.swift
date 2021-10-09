//
//

import Foundation

extension ZMConversationSecurityLevel: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .notSecure:
            return "notSecure"
        case .secure:
            return "secure"
        case .secureWithIgnored:
            return "secureWithIgnored"
        }
    }
}
