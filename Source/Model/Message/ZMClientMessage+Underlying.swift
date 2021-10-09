//
//

import Foundation

extension ZMClientMessage {
    public var underlyingMessage: GenericMessage? {
        let filteredData = self.dataSet
            .compactMap { $0 as? ZMGenericMessageData }
            .compactMap { $0.underlyingMessage }
            .filter { $0.knownMessage && $0.imageAssetData == nil }
            .compactMap { try? $0.serializedData() }
        guard !filteredData.isEmpty else { return nil }
        
        var message = GenericMessage()
        filteredData.forEach { 
            try? message.merge(serializedData: $0)
        }
        return message
    }
    
    public override var locationMessageData: LocationMessageData? {
        switch underlyingMessage?.content {
        case .location(_)?:
            return self
        case .ephemeral(let data)?:
            switch data.content {
            case .location(_)?:
                return self
            default:
                return nil
            }
            
        default:
            return nil
        }
    }
}
