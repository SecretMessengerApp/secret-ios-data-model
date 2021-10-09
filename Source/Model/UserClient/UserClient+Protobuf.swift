//
// 


import Foundation
import WireProtos

extension UserClient {
    
    var hexRemoteIdentifier: UInt64 {
        let pointer = UnsafeMutablePointer<UInt64>.allocate(capacity: 1)
        defer { pointer.deallocate() }
        Scanner(string: self.remoteIdentifier!).scanHexInt64(pointer)
        return UInt64(pointer.pointee)
    }
    
    public var clientId: ZMClientId {
        let builder = ZMClientIdBuilder()
        builder.setClient(self.hexRemoteIdentifier)
        return builder.build()
    }

}
