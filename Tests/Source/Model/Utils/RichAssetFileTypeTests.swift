// 
// 

import XCTest
@testable import WireDataModel

class RichAssetFileTypeTests: XCTestCase {

    func testThatItParsesWalletPassCorrectly() {
        assertFileType("application/vnd.apple.pkpass", .walletPass)
    }

    func testThatItParsesVideoMimeTypeCorrectly_Positive() {
        assertFileType("video/mp4", .video)
        assertFileType("video/quicktime", .video)
    }

    func testThatItParsesVideoMimeTypeCorrectly_Negative() {
        assertFileType("foo", nil)
        assertFileType("", nil)
        assertFileType("text/plain", nil)
        assertFileType("application/octet-stream", nil)
        assertFileType(".mp4", nil)
        assertFileType("video/webm", nil)
        assertFileType("video/mpeg", nil) // mpeg files are not supported on iPhone
    }
    
    func testThatItParsesAudioMimeTypeCorrectly_Positive() {
        assertFileType("audio/mp4", .audio)
        assertFileType("audio/mpeg", .audio)
        assertFileType("audio/x-m4a", .audio)
    }
    
    func testThatItParsesAudioMimeTypeCorrectly_Negative() {
        assertFileType("foo", nil)
        assertFileType("", nil)
        assertFileType("text/plain", nil)
        assertFileType("application/octet-stream", nil)
        assertFileType(".mp4", nil)
        assertFileType("video/mpeg", nil)
        assertFileType("video/webm", nil)
        assertFileType("audio/midi", nil)
        assertFileType("audio/x-midi", nil)
    }

    // MARK: - Helpers

    private func assertFileType(_ mimeType: String, _ expectedType: RichAssetFileType?, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(RichAssetFileType(mimeType: mimeType), expectedType, file: file, line: line)
    }

}
