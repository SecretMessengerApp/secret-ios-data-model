//
//

import Foundation

@objc public protocol ServiceUser: class, UserType {
    var providerIdentifier: String? { get }
    var serviceIdentifier: String? { get }
}

@objc public protocol SearchServiceUser: ServiceUser {
    var summary: String? { get }
}

extension ZMUser {
    static let servicesMustBeMentioned = false
    static let serviceMentionKeyword = "@bots"
}
