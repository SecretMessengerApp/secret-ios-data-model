//
//

import XCTest
import WireTesting
@testable import WireDataModel

class InvalidGenericMessageDataRemovalTests: DiskDatabaseTest {
    
    func testThatItDoesNotRemoveValidGenericMessageData() throws {
        // Given
        let conversation = createConversation()
        let textMessage = conversation.append(text: "Hello world")! as! ZMClientMessage
        let genericMessageData = textMessage.dataSet.firstObject! as! ZMGenericMessageData
        try self.moc.save()
        
        // When
        WireDataModel.InvalidGenericMessageDataRemoval.removeInvalid(in: self.moc)
        
        // Then
        XCTAssertFalse(genericMessageData.isDeleted)
        XCTAssertFalse(genericMessageData.isZombieObject)
    }
    
    func testThatItDoesRemoveInvalidGenericMessageData() throws {
        // Given
        let conversation = createConversation()
        let textMessage = conversation.append(text: "Hello world")! as! ZMClientMessage
        let genericMessageData = textMessage.dataSet.firstObject! as! ZMGenericMessageData
        try self.moc.save()
        
        // Then
        XCTAssertFalse(genericMessageData.isDeleted)
        XCTAssertFalse(genericMessageData.isZombieObject)
        
        // And when
        genericMessageData.message = nil
        try self.moc.save()

        // When
        WireDataModel.InvalidGenericMessageDataRemoval.removeInvalid(in: self.moc)
        
        // Then
        XCTAssertTrue(genericMessageData.isDeleted)
        XCTAssertTrue(genericMessageData.isZombieObject)
    }
    
    func testThatItDoesNotRemoveValidGenericMessageData_Asset() throws {
        // Given
        let conversation = createConversation()
        let assetMessage = conversation.append(imageFromData: self.verySmallJPEGData()) as! ZMAssetClientMessage
        let genericMessageData = assetMessage.dataSet.firstObject! as! ZMGenericMessageData
        try self.moc.save()

        // When
        WireDataModel.InvalidGenericMessageDataRemoval.removeInvalid(in: self.moc)

        // Then
        XCTAssertFalse(genericMessageData.isDeleted)
        XCTAssertFalse(genericMessageData.isZombieObject)
    }

    func testThatItDoesRemoveInvalidGenericMessageData_Asset() throws {
        // Given
        let conversation = createConversation()
        let assetMessage = conversation.append(imageFromData: self.verySmallJPEGData()) as! ZMAssetClientMessage
        let genericMessageData = assetMessage.dataSet.firstObject! as! ZMGenericMessageData
        try self.moc.save()
        
        // Then
        XCTAssertFalse(genericMessageData.isDeleted)
        XCTAssertFalse(genericMessageData.isZombieObject)
        
        // And when

        genericMessageData.asset = nil
        try self.moc.save()

        // When
        WireDataModel.InvalidGenericMessageDataRemoval.removeInvalid(in: self.moc)

        // Then
        XCTAssertTrue(genericMessageData.isDeleted)
        XCTAssertTrue(genericMessageData.isZombieObject)
    }
    
}
