//
//

import Foundation

@objc public enum MessageReaction: UInt16 {
    case like
    case audioPlayed

    public var unicodeValue: String {
        switch self {
        case .like: return "❤️"
        case .audioPlayed: return "audio_played"
        }
    }
}

extension ZMMessage {
    
    static func append(reaction: MessageReaction, to message: ZMConversationMessage) -> ZMClientMessage? {
        guard
            let message = message as? ZMMessage,
            let context = message.managedObjectContext,
            let messageID = message.nonce,
            message.isSent
            else { return nil }
        let genericMessage = ZMGenericMessage.message(content: ZMReaction(emoji: reaction.unicodeValue, messageID: messageID))
        let clientMessage: ZMClientMessage?
        switch reaction {
        case .like:
            clientMessage = message.conversation?.appendClientMessage(with: genericMessage, expires: false, hidden: true)
        case .audioPlayed:
            let selfConversation = ZMConversation.selfConversation(in: context)
            clientMessage = selfConversation.appendClientMessage(with: genericMessage, expires: false, hidden: true)
        }
        message.addReaction(reaction.unicodeValue, forUser: .selfUser(in: context))
        return clientMessage
    }
    
    @discardableResult
    @objc public static func addReaction(_ reaction: MessageReaction, toMessage message: ZMConversationMessage) -> ZMClientMessage? {
        // confirmation that we understand the emoji
        // the UI should never send an emoji we dont handle
        if Reaction.transportReaction(from: reaction.unicodeValue) == .none {
            fatal("We can't append this reaction \(reaction.unicodeValue), this is a programmer error.")
        }
        return append(reaction: reaction, to: message)
    }
    
    @objc public static func removeReaction(onMessage message: ZMConversationMessage) -> ZMClientMessage? {
        guard
            let message = message as? ZMMessage,
            let context = message.managedObjectContext,
            let messageID = message.nonce,
            message.isSent
            else { return nil }

        let emoji = ""
        let genericMessage = ZMGenericMessage.message(content: ZMReaction(emoji: emoji, messageID: messageID))
        let clientMessage = message.conversation?.appendClientMessage(with: genericMessage, expires: false, hidden: true)
        message.addReaction(emoji, forUser: .selfUser(in: context))
        return clientMessage
    }
    
    private func mapToMessageReaction(unicodeValue: String?) -> MessageReaction {
        return unicodeValue == MessageReaction.audioPlayed.unicodeValue ? .audioPlayed : .like
    }
    
    @objc public func addReaction(_ unicodeValue: String?, forUser user: ZMUser) {
        remove(reaction: mapToMessageReaction(unicodeValue: unicodeValue), forUser: user)
        if let unicodeValue = unicodeValue , unicodeValue.count > 0 {
            for reaction in self.reactions {
                if reaction.unicodeValue! == unicodeValue {
                    reaction.mutableSetValue(forKey: ZMReactionUsersValueKey).add(user)
                    return
                }
            }
            
            //we didn't find a reaction, need to add a new one
            let newReaction = Reaction.insertReaction(unicodeValue, users: [user], inMessage: self)
            self.mutableSetValue(forKey: "reactions").add(newReaction)
        }
        updateCategoryCache()
    }
    
    fileprivate func remove(reaction: MessageReaction, forUser user: ZMUser) {
        for react in reactions where react.unicodeValue == reaction.unicodeValue {
            if react.users.contains(user) {
                react.mutableSetValue(forKey: ZMReactionUsersValueKey).remove(user)
                break;
            }
        }
    }

    @objc public func clearAllReactions() {
        let oldReactions = self.reactions
        reactions.removeAll()
        guard let moc = managedObjectContext else { return }
        oldReactions.forEach(moc.delete)
    }
}
