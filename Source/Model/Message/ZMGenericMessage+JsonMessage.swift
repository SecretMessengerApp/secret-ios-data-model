

import Foundation


extension ZMGenericMessage {
    
    @objc
    static func serviceGenericMessage(withUpdateEvent updateEvent: ZMUpdateEvent) -> ZMGenericMessage? {
        guard let dataDictionary = updateEvent.payload["data"] as? [String: Any],
            JSONSerialization.isValidJSONObject(dataDictionary),
            let data = try? JSONSerialization.data(withJSONObject: dataDictionary, options: JSONSerialization.WritingOptions.prettyPrinted),
            let jsonString = String.init(data: data, encoding: String.Encoding.utf8),
            let uuid = updateEvent.uuid  else {
            return  nil
        }
        
        
        if let msgType = dataDictionary["msgType"] as? String,
            msgType == "20003",
            let msgData = dataDictionary["msgData"] as? [String: Any]{
            let language = NSLocale.preferredLanguages.first
            var text: String?
            var url: String?
            if language?.hasPrefix("zh-Hans") ?? false {
                text = (msgData["zh"] as? [String: Any])?["text"] as? String
                url = (msgData["zh"] as? [String: Any])?["url"] as? String
            } else {
                text = (msgData["en"] as? [String: Any])?["text"] as? String
                url = (msgData["en"] as? [String: Any])?["url"] as? String
            }
            if let newsText = text, let newsUrl = url{
                let tempMessage = ZMGenericMessage.message(content: ZMText.text(with: "\(newsText)\n\(newsUrl)"), nonce: uuid)
                guard let base64String = tempMessage.data()?.base64String() else {
                    return nil
                }
                return self.init(base64String: base64String, updateEvent: updateEvent)
            } else {
                return nil
            }
        }
        
        let tempMessage = ZMGenericMessage.message(content: ZMTextJson.text(with: jsonString), nonce: uuid)
        guard let base64String = tempMessage.data()?.base64String() else {
            return nil
        }
        return self.init(base64String: base64String, updateEvent: updateEvent)
    }
    
    @objc
    static func memberJoinAskGenericMessage(withUpdateEvent updateEvent: ZMUpdateEvent) -> ZMGenericMessage? {
        guard let dataDictionary = updateEvent.payload["data"] as? [String: Any],
            JSONSerialization.isValidJSONObject(dataDictionary),
            let data = try? JSONSerialization.data(withJSONObject: dataDictionary, options: JSONSerialization.WritingOptions.prettyPrinted),
            let jsonString = String.init(data: data, encoding: String.Encoding.utf8),
            let msgData = dataDictionary["msgData"] as? [String: Any],
            let uuidString = msgData["code"] as? String,
            let messageUuid = UUID.init(uuidString: uuidString) else {
                return  nil
        }
        let tempMessage = ZMGenericMessage.message(content: ZMTextJson.text(with: jsonString), nonce: messageUuid)
        guard let base64String = tempMessage.data()?.base64String() else {
            return nil
        }
        return self.init(base64String: base64String, updateEvent: updateEvent)
    }
    
    @objc
    static func jsonGenericMessage(withUpdateEvent updateEvent: ZMUpdateEvent) -> ZMGenericMessage? {
        guard let dataDictionary = updateEvent.payload["data"] as? [String: Any],
            JSONSerialization.isValidJSONObject(dataDictionary),
            let data = try? JSONSerialization.data(withJSONObject: dataDictionary, options: JSONSerialization.WritingOptions.prettyPrinted),
            let jsonString = String.init(data: data, encoding: String.Encoding.utf8) else {
                return  nil
        }
        let tempMessage = ZMGenericMessage.message(content: ZMTextJson.text(with: jsonString), nonce: UUID())
        guard let base64String = tempMessage.data()?.base64String() else {
            return nil
        }
        return self.init(base64String: base64String, updateEvent: updateEvent)
    }
}
