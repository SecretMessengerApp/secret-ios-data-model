//
//

import Foundation
import CoreLocation

@objc(ZMLocationMessageData)
public protocol LocationMessageData: NSObjectProtocol {
    var latitude: Float { get }
    var longitude: Float { get }
    var name: String? { get }
    var zoomLevel: Int32 { get } 
}

extension ZMClientMessage: LocationMessageData {
    @objc public var latitude: Float {
        return self.underlyingMessage?.locationData?.latitude ?? 0
    }
    
    @objc public var longitude: Float {
        return self.underlyingMessage?.locationData?.longitude ?? 0
    }
    
    @objc public var name: String? {
        return self.underlyingMessage?.locationData?.name
    }
    
    @objc public var zoomLevel: Int32 {
        return self.underlyingMessage?.locationData?.zoom ?? 0
    }
}

public extension LocationMessageData {
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(
            latitude: CLLocationDegrees(latitude),
            longitude: CLLocationDegrees(longitude)
        )
    }
    
}

