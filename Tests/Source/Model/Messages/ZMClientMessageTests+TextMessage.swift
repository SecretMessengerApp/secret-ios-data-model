//
// 


import XCTest
import WireLinkPreview

@testable import WireDataModel

class ZMClientMessageTests_TextMessage: BaseZMMessageTests {
    
    override func tearDown() {
        super.tearDown()
        wipeCaches()
    }

    func testThatItHasImageReturnsTrueWhenLinkPreviewWillContainAnImage() {
        // given
        let nonce = UUID()
        let clientMessage = ZMClientMessage(nonce: nonce, managedObjectContext: uiMOC)

        let article = ArticleMetadata(
            originalURLString: "www.example.com/article/original",
            permanentURLString: "http://www.example.com/article/1",
            resolvedURLString: "http://www.example.com/article/1",
            offset: 12
        )
        article.title = "title"
        article.summary = "summary"
        let linkPreview = article.protocolBuffer.update(withOtrKey: Data(), sha256: Data())
        clientMessage.add(ZMGenericMessage.message(content: ZMText.text(with: "sample text", linkPreviews: [linkPreview]), nonce: nonce).data())
        
        // when
        let willHaveAnImage = clientMessage.textMessageData!.linkPreviewHasImage
        
        // then
        XCTAssertTrue(willHaveAnImage)
    }
    
    func testThatItHasImageReturnsFalseWhenLinkPreviewDoesntContainAnImage() {
        
        // given
        let nonce = UUID()
        let clientMessage = ZMClientMessage(nonce: nonce, managedObjectContext: uiMOC)

        let article = ArticleMetadata(
            originalURLString: "example.com/article/original",
            permanentURLString: "http://www.example.com/article/1",
            resolvedURLString: "http://www.example.com/article/1",
            offset: 12
        )
        article.title = "title"
        article.summary = "summary"
        clientMessage.add(ZMGenericMessage.message(content: ZMText.text(with: "sample text", linkPreviews: [article.protocolBuffer]), nonce: nonce).data())
        
        // when
        let willHaveAnImage = clientMessage.textMessageData!.linkPreviewHasImage
        
        // then
        XCTAssertFalse(willHaveAnImage)
    }
    
    func testThatItHasImageReturnsTrueWhenLinkPreviewWillContainAnImage_TwitterStatus() {
        // given
        let nonce = UUID.create()
        let clientMessage = ZMClientMessage(nonce: nonce, managedObjectContext: uiMOC)

        let preview = TwitterStatusMetadata(
            originalURLString: "example.com/article/original",
            permanentURLString: "http://www.example.com/article/1",
            resolvedURLString: "http://www.example.com/article/1",
            offset: 42
        )
        
        preview.author = "Author"
        preview.message = name

        let updated = preview.protocolBuffer.update(withOtrKey: .randomEncryptionKey(), sha256: .zmRandomSHA256Key())
        clientMessage.add(ZMGenericMessage.message(content: ZMText.text(with: "Text", linkPreviews: [updated]), nonce: nonce).data())
        
        // when
        let willHaveAnImage = clientMessage.textMessageData!.linkPreviewHasImage
        
        // then
        XCTAssertTrue(willHaveAnImage)
    }
    
    func testThatItHasImageReturnsFalseWhenLinkPreviewDoesntContainAnImage_TwitterStatus() {
        // given
        let nonce = UUID.create()
        let clientMessage = ZMClientMessage(nonce: nonce, managedObjectContext: uiMOC)
        

        let preview = TwitterStatusMetadata(
            originalURLString: "example.com/article/original",
            permanentURLString: "http://www.example.com/article/1",
            resolvedURLString: "http://www.example.com/article/1",
            offset: 42
        )
        
        preview.author = "Author"
        preview.message = name
        clientMessage.add(ZMGenericMessage.message(content: ZMText.text(with: "Text", linkPreviews: [preview.protocolBuffer]), nonce: nonce).data())
        
        // when
        let willHaveAnImage = clientMessage.textMessageData!.linkPreviewHasImage
        
        // then
        XCTAssertFalse(willHaveAnImage)
    }
    
    func testThatItSendsANotificationToDownloadTheImageWhenRequestImageDownloadIsCalledAndItHasAAssetID() {
        // given
        let preview = TwitterStatusMetadata(
            originalURLString: "example.com/article/original",
            permanentURLString: "http://www.example.com/article/1",
            resolvedURLString: "http://www.example.com/article/1",
            offset: 42
        )
        
        preview.author = "Author"
        preview.message = name
        
        // then
        assertThatItSendsANotificationToDownloadTheImageWhenRequestImageDownloadIsCalled(preview)
    }
    
    func testThatItSendsANotificationToDownloadTheImageWhenRequestImageDownloadIsCalledAndItHasAAssetID_Article() {
        // given
        let preview = ArticleMetadata(
            originalURLString: "example.com/article/original",
            permanentURLString: "http://www.example.com/article/1",
            resolvedURLString: "http://www.example.com/article/1",
            offset: 42
        )
        
        preview.title = "title"
        preview.summary = "summary"
        
        // then
        assertThatItSendsANotificationToDownloadTheImageWhenRequestImageDownloadIsCalled(preview)
    }
    
    func assertThatItSendsANotificationToDownloadTheImageWhenRequestImageDownloadIsCalled(_ preview: LinkMetadata, line: UInt = #line) {
        
        // given
        let nonce = UUID.create()
        let clientMessage = ZMClientMessage(nonce: nonce, managedObjectContext: uiMOC)
        
        let updated = preview.protocolBuffer.update(withOtrKey: .randomEncryptionKey(), sha256: .zmRandomSHA256Key())
        let withID = updated.update(withAssetKey: "id", assetToken: nil)
        clientMessage.add(ZMGenericMessage.message(content: ZMText.text(with: "Text", linkPreviews: [withID]), nonce: nonce).data())
        try! uiMOC.obtainPermanentIDs(for: [clientMessage])

        
        // when
        let expectation = self.expectation(description: "Notified")
        let token: Any? = NotificationInContext.addObserver(name: ZMClientMessage.linkPreviewImageDownloadNotification,
                                          context: self.uiMOC.notificationContext,
                                          object: clientMessage.objectID)
        { _ in
            expectation.fulfill()
        }
        
        clientMessage.textMessageData?.requestLinkPreviewImageDownload()
        
        // then
        withExtendedLifetime(token) { () -> () in
            XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.2), line: line)
        }
    }
    

}
