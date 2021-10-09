//
//

import Foundation

@objc
protocol ContentHashing {
    
    /// SHA-256 hash of the message content (text, image, location, ...)
    var hashOfContent: Data? { get }
    
}

@objc
extension ZMMessage: ContentHashing {
    
    var hashOfContent: Data? {
        guard let date = self.serverTimestamp else {
            return nil
        }
        return self.genericMessage?.hashOfContent(with: date)
    }
    
}
