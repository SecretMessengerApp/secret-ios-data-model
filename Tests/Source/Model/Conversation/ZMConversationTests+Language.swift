//
//

import Foundation
@testable import WireDataModel

class ZMConversationTests_Language : BaseZMMessageTests {

    func testThatItAllowsSettingLanguageOnConversation(){
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        let germanLanguage = "de-DE"

        let uuid = UUID.create()
        conversation.remoteIdentifier = uuid
        conversation.language = germanLanguage

        XCTAssert(uiMOC.saveOrRollback())
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))


        // when
        let conversationFetched = ZMConversation.fetch(withRemoteIdentifier: uuid, in: uiMOC)

        // then
        XCTAssertEqual(conversationFetched?.language, germanLanguage)
    }

}
