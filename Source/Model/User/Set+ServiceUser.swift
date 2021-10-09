//
//

import Foundation

extension Set where Element == ZMUser {

    var serviceUsers: Set<ZMUser> {
        return self.filter { $0.isServiceUser }
    }

    func categorize() -> (services: Set<ZMUser>, users: Set<ZMUser>) {
        let services = self.serviceUsers
        let users = self.subtracting(services)
        return (services, users)
    }

}
