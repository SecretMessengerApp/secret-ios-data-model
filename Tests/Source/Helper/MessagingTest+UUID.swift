//
//

import Foundation
import WireTesting

public extension Data {

    static func secureRandomData(ofLength length: UInt) -> Data {
        return NSData.secureRandomData(ofLength: length)!
    }

}
