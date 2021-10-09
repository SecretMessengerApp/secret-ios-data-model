//
//

import Foundation

class ConversationObserverToken : NSObject, ZMConversationObserver {
    
    let block : () -> Void
    let filter : (ConversationChangeInfo) -> Bool
    var token : NSObjectProtocol? = nil
    
    init(filter:  @escaping (ConversationChangeInfo) -> Bool, block: @escaping () -> Void ) {
        self.block = block
        self.filter = filter
    }
    
    func conversationDidChange(_ changeInfo: ConversationChangeInfo) {
        if filter(changeInfo) {
            block()
        }
    }
    
}

public extension ZMConversation {
    
    func onCreatedRemotely(_ block : @escaping () -> Void) -> NSObjectProtocol? {
        guard remoteIdentifier == nil else { block(); return nil }
        
        let observer = ConversationObserverToken(filter: { $0.createdRemotelyChanged }, block: block)
        observer.token = ConversationChangeInfo.add(observer: observer, for: self)
        return observer
    }
    
}
