//
//

import Foundation

extension ZMGenericMessageData {
    var underlyingMessage: GenericMessage? {
        do {
            let genericMessage = try GenericMessage(serializedData: data)
            return genericMessage
        } catch {
            return nil
        }
    }
}
