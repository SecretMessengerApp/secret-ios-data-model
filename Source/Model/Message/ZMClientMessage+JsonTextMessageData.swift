

import Foundation

@objc
extension ZMClientMessage: ZMJsonTextMessageData {

    public var jsonMessageText: String? {
        return genericMessage?.jsonTextData?.content
    }
}
