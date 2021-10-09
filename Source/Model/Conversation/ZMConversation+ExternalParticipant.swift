//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import Foundation

extension ZMConversation {

    static let externalParticipantsStateKey = "externalParticipantsState"

    /**
     * Represents the possible state of external participants in a conversation.
     */

    public struct ExternalParticipantsState: OptionSet {
        /// The conversation contains guests that we should warn the self user about.
        public static let visibleGuests = ExternalParticipantsState(rawValue: 1 << 0)

        /// The conversation contains services that we should warn the self user about.
        public static let visibleServices = ExternalParticipantsState(rawValue: 1 << 1)

        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }

    @objc class func keyPathsForValuesAffectingExternalParticipantsState() -> Set<String> {
        return ["lastServerSyncedActiveParticipants.isServiceUser", "lastServerSyncedActiveParticipants.hasTeam"]
    }

    /// The state of external participants in the conversation.
    public var externalParticipantsState: ExternalParticipantsState {
        // Exception 1) We don't consider guests/services as external participants in 1:1 conversations
        guard conversationType == .group else { return [] }

        // Exception 2) If there is only one user in the group and it's a service, we don't consider it as external
        let participants = self.activeParticipants
        let selfUser = ZMUser.selfUser(in: managedObjectContext!)
        let otherUsers = participants.subtracting([selfUser])

        if otherUsers.count == 1, otherUsers.first!.isServiceUser {
            return []
        }

        // Calculate the external participants state
        let canDisplayGuests = selfUser.team != nil
        var state = ExternalParticipantsState()

        for user in otherUsers {
            if user.isServiceUser {
                state.insert(.visibleServices)
            } else if canDisplayGuests && user.isGuest(in: self) {
                state.insert(.visibleGuests)
            }

            // Early exit to avoid going through all users if we can avoid it
            if state.contains(.visibleServices) && (state.contains(.visibleGuests) || !canDisplayGuests) {
                break
            }
        }

        return state
    }

    /// Returns whether an services are present, regardless of the display rules.
    public var areServicesPresent: Bool {
        return activeParticipants.any(\.isServiceUser)
    }

    /// Returns whether guests are present, regardless of the display rules.
    public var areGuestsPresent: Bool {
        return activeParticipants.any { $0.isGuest(in: self) }
    }

}
