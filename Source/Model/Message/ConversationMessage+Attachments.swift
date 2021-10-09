//
//

import Foundation

extension ZMConversationMessage {

    /**
     * Requests to refetch the link attachments of messages received prior to
     * the persistent link attachments update.
     */

    public func refetchLinkAttachmentsIfNeeded() {
        guard !needsLinkAttachmentsUpdate && textMessageData != nil else {
            return
        }

        if linkAttachments == nil {
            needsLinkAttachmentsUpdate = true
        }
    }

}
