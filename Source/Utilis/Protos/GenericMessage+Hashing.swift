//
//

import Foundation

extension Location: BigEndianDataConvertible {
    var asBigEndianData: Data {
        var data = latitude.times1000.asBigEndianData
        data.append(longitude.times1000.asBigEndianData)
        return data
    }
}

fileprivate extension Float {
    var times1000: Int {
        return Int(roundf(self * 1000.0))
    }
}
