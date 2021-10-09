////
//

import Foundation

public struct PushToken: Equatable, Codable {
    public let deviceToken: Data
    public let appIdentifier: String
    public let transportType: String
    public var isRegistered: Bool
    public var randomCode: Int
    public var isMarkedForDeletion: Bool = false
    public var isMarkedForDownload: Bool = false
   
    public var isiOS13Registered: Bool = false
  
    public var isUpdateiOS13: Bool = false
}

public struct ApnsPushToken: Equatable, Codable {
    public let deviceToken: String
    public let appIdentifier: String
    public let transportType: String
    public var isRegistered: Bool
    public var randomCode: Int
    public var isMarkedForDeletion: Bool = false
    public var isMarkedForDownload: Bool = false
    
}

extension PushToken {

    public init(deviceToken: Data, appIdentifier: String, transportType: String, isRegistered: Bool, randomCode: Int = 0) {
        self.init(deviceToken: deviceToken, appIdentifier: appIdentifier, transportType: transportType, isRegistered: isRegistered, randomCode: randomCode, isMarkedForDeletion: false, isMarkedForDownload: false)
    }

    public var deviceTokenString: String {
        return deviceToken.zmHexEncodedString()
    }

    public func resetFlags() -> PushToken {
        var token = self
        token.isMarkedForDownload = false
        token.isMarkedForDeletion = false
        return token
    }

    public func markToDownload() -> PushToken {
        var token = self
        token.isMarkedForDownload = true
        return token
    }

    public func markToDelete() -> PushToken {
        var token = self
        token.isMarkedForDeletion = true
        return token
    }

}


extension ApnsPushToken {

    public init(deviceToken: String, appIdentifier: String, transportType: String, isRegistered: Bool, randomCode: Int = 0) {
        self.init(deviceToken: deviceToken, appIdentifier: appIdentifier, transportType: transportType, isRegistered: isRegistered, randomCode: randomCode, isMarkedForDeletion: false, isMarkedForDownload: false)
    }
    
    public var deviceTokenString: String {
        return deviceToken
    }

    public func resetFlags() -> ApnsPushToken {
        var token = self
        token.isMarkedForDownload = false
        token.isMarkedForDeletion = false
        return token
    }

    public func markToDownload() -> ApnsPushToken {
        var token = self
        token.isMarkedForDownload = true
        return token
    }

    public func markToDelete() -> ApnsPushToken {
        var token = self
        token.isMarkedForDeletion = true
        return token
    }

}
