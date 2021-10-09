//
//

import XCTest

extension ZMSearchUserTests_ProfileImages: ZMManagedObjectContextProvider {
    
    var managedObjectContext: NSManagedObjectContext! {
        return uiMOC
    }
    
    var syncManagedObjectContext: NSManagedObjectContext! {
        return syncMOC
    }
    
}

class ZMSearchUserTests_ProfileImages: ZMBaseManagedObjectTest {
    
    func testThatItReturnsPreviewsProfileImageIfItWasPreviouslyUpdated() {
        // given
        let imageData = verySmallJPEGData()
        let searchUser = ZMSearchUser(contextProvider: self, name: "John", handle: "john", accentColor: .brightOrange, remoteIdentifier: UUID())
        
        // when
        searchUser.updateImageData(for: .preview, imageData: imageData)
        
        // then
        XCTAssertEqual(searchUser.previewImageData, imageData)
    }
    
    func testThatItReturnsCompleteProfileImageIfItWasPreviouslyUpdated() {
        // given
        let imageData = verySmallJPEGData()
        let searchUser = ZMSearchUser(contextProvider: self, name: "John", handle: "john", accentColor: .brightOrange, remoteIdentifier: UUID())
        
        // when
        searchUser.updateImageData(for: .complete, imageData: imageData)
        
        // then
        XCTAssertEqual(searchUser.completeImageData, imageData)
    }
    
    func testThatItReturnsPreviewsProfileImageFromAssociatedUserIfPossible() {
        // given
        let imageData = verySmallJPEGData()
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.remoteIdentifier = UUID.create()
        user.previewProfileAssetIdentifier = UUID.create().transportString()
        user.setImage(data: imageData, size: .preview)
        uiMOC.saveOrRollback()
        
        // when
        let searchUser = ZMSearchUser(contextProvider: self, user: user)
        
        // then
        XCTAssertEqual(searchUser.previewImageData, imageData)
    }
    
    func testThatItReturnsPreviewsCompleteImageFromAssociatedUserIfPossible() {
        // given
        let imageData = verySmallJPEGData()
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.remoteIdentifier = UUID.create()
        user.completeProfileAssetIdentifier = UUID.create().transportString()
        user.setImage(data: imageData, size: .complete)
        uiMOC.saveOrRollback()
        
        // when
        let searchUser = ZMSearchUser(contextProvider: self, user: user)
        
        // then
        XCTAssertEqual(searchUser.completeImageData, imageData)
    }
    
    func testThatItReturnsPreviewImageProfileCacheKey() {
        // given
        let searchUser = ZMSearchUser(contextProvider: self, name: "John", handle: "john", accentColor: .brightOrange, remoteIdentifier: UUID.create())
        
        // then
        XCTAssertNotNil(searchUser.smallProfileImageCacheKey)
    }
    
    func testThatItReturnsCompleteImageProfileCacheKey() {
        // given
        let searchUser = ZMSearchUser(contextProvider: self, name: "John", handle: "john", accentColor: .brightOrange, remoteIdentifier: UUID.create())
        
        // then
        XCTAssertNotNil(searchUser.mediumProfileImageCacheKey)
    }
    
    func testThatItPreviewAndCompleteImageProfileCacheKeyIsDifferent() {
        // given
        let searchUser = ZMSearchUser(contextProvider: self, name: "John", handle: "john", accentColor: .brightOrange, remoteIdentifier: UUID.create())
        
        // then
        XCTAssertNotEqual(searchUser.smallProfileImageCacheKey, searchUser.mediumProfileImageCacheKey)
    }
    
    func testThatItReturnsPreviewImageProfileCacheKeyFromUserIfPossible() {
        // given
        let imageData = verySmallJPEGData()
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.remoteIdentifier = UUID.create()
        user.previewProfileAssetIdentifier = UUID.create().transportString()
        user.setImage(data: imageData, size: .preview)
        uiMOC.saveOrRollback()
        
        // given
        let searchUser = ZMSearchUser(contextProvider: self, user: user)
        
        // then
        XCTAssertNotNil(searchUser.smallProfileImageCacheKey)
        XCTAssertEqual(user.smallProfileImageCacheKey, searchUser.smallProfileImageCacheKey)
    }
    
    func testThatItReturnsCompleteImageProfileCacheKeyFromUserIfPossible() {
        // given
        let imageData = verySmallJPEGData()
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.remoteIdentifier = UUID.create()
        user.completeProfileAssetIdentifier = UUID.create().transportString()
        user.setImage(data: imageData, size: .complete)
        uiMOC.saveOrRollback()
        
        // given
        let searchUser = ZMSearchUser(contextProvider: self, user: user)
        
        // then
        XCTAssertNotNil(searchUser.mediumProfileImageCacheKey)
        XCTAssertEqual(user.mediumProfileImageCacheKey, searchUser.mediumProfileImageCacheKey)
    }
    
    func testThatItCanFetchPreviewProfileImageOnAQueue() {
        // given
        let imageData = verySmallJPEGData()
        let searchUser = ZMSearchUser(contextProvider: self, name: "John", handle: "john", accentColor: .brightOrange, remoteIdentifier: UUID())
        
        // when
        searchUser.updateImageData(for: .preview, imageData: imageData)
        
        // then
        let imageDataArrived = expectation(description: "completion handler called")
        searchUser.imageData(for: .preview, queue: .global()) { (imageDataResult) in
            XCTAssertEqual(imageData, imageDataResult)
            imageDataArrived.fulfill()
        }
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        
    }
    func testThatItCanFetchCompleteProfileImageOnAQueue() {
        // given
        let imageData = verySmallJPEGData()
        let searchUser = ZMSearchUser(contextProvider: self, name: "John", handle: "john", accentColor: .brightOrange, remoteIdentifier: UUID())
        
        // when
        searchUser.updateImageData(for: .complete, imageData: imageData)
        
        // then
        let imageDataArrived = expectation(description: "completion handler called")
        searchUser.imageData(for: .complete, queue: .global()) { (imageDataResult) in
            XCTAssertEqual(imageData, imageDataResult)
            imageDataArrived.fulfill()
        }
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }
    
}
