//
//

import Foundation

extension ZMClientMessage {
    
    override func updateQuoteRelationships() {
        guard let text = genericMessage?.textData, text.hasQuote() else {
            return
        }
        
        establishRelationshipsForInsertedQuote(text.quote)
    }
    
}
