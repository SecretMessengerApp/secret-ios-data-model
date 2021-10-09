//
//


import Foundation

private var log = ZMSLog(tag: "event-processing")

extension ZMOTRMessage {
    
    func establishRelationshipsForInsertedQuote(_ quote: ZMQuote) {
        
        guard let managedObjectContext = managedObjectContext,
              let conversation = conversation,
              let quotedMessageId = UUID(uuidString: quote.quotedMessageId),
              let quotedMessage = ZMOTRMessage.fetch(withNonce: quotedMessageId, for: conversation, in: managedObjectContext) else { return }
        
        if quotedMessage.hashOfContent == quote.quotedMessageSha256 {
            quotedMessage.replies.insert(self)
        } else {
            log.warn("Rejecting quote since local hash \(quotedMessage.hashOfContent?.zmHexEncodedString() ?? "N/A") doesn't match \(quote.quotedMessageSha256.zmHexEncodedString())")
        }
    }
    
}
