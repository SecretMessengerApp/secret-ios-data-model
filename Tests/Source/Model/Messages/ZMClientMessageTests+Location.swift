// 
// 


import Foundation
import CoreLocation
@testable import WireDataModel

class ClientMessageTests_Location: BaseZMMessageTests {
 
    func testThatItReturnsLocationMessageDataWhenPresent() throws {
        // given
        let (latitude, longitude): (Float, Float) = (48.53775, 9.041169)
        let (name, zoom) = ("Tuebingen, Deutschland", Int32(3))
        let location = Location.with() {
            $0.latitude = latitude
            $0.longitude = longitude
            $0.name = name
            $0.zoom = zoom
        }
        let message = GenericMessage.message(content: location)
        
        // when
        let clientMessage = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        clientMessage.add(try message.serializedData())
        
        // then
        let locationMessageData = clientMessage.locationMessageData
        XCTAssertNotNil(locationMessageData)
        XCTAssertEqual(locationMessageData?.latitude, latitude)
        XCTAssertEqual(locationMessageData?.longitude, longitude)
        XCTAssertEqual(locationMessageData?.name, name)
        XCTAssertEqual(locationMessageData?.zoomLevel, zoom)
    }
    
    func testThatItDoesNotReturnLocationMessageDataWhenNotPresent() {
        // given
        let clientMessage = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        
        // then
        XCTAssertNil(clientMessage.locationMessageData)
    }
    
}
