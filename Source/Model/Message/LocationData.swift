// 
// 

import WireUtilities

@objc (ZMLocationData) @objcMembers
final public class LocationData: NSObject {

    public let latitude, longitude: Float
    public let name: String?
    public let zoomLevel: Int32
    
    public class func locationData(withLatitude latitude: Float, longitude: Float, name: String?, zoomLevel: Int32) -> LocationData {
        return LocationData(latitude: latitude, longitude: longitude, name: name, zoomLevel: zoomLevel)
    }
    
    init(latitude: Float, longitude: Float, name: String?, zoomLevel: Int32) {
        self.latitude = latitude
        self.longitude = longitude
        self.name = name?.removingExtremeCombiningCharacters
        self.zoomLevel = zoomLevel
        super.init()
    }
}
