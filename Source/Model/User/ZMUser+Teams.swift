//
//


public extension ZMUser {

    @objc var hasTeam: Bool {
        /// Other users won't have a team object, but a teamIdentifier.
        return nil != team || nil != teamIdentifier
    }

    @objc var team: Team? {
        return membership?.team
    }
        
    @objc static func keyPathsForValuesAffectingTeam() -> Set<String> {
         return [#keyPath(ZMUser.membership)]
    }

    @objc var isWirelessUser: Bool {
        return self.expiresAt != nil
    }
    
    @objc var isExpired: Bool {
        guard let expiresAt = self.expiresAt else {
            return false
        }
        
        return expiresAt.compare(Date()) != .orderedDescending
    }
    
    @objc var expiresAfter: TimeInterval {
        guard let expiresAt = self.expiresAt else {
            return 0
        }
        
        if expiresAt.timeIntervalSinceNow < 0 {
            return 0
        }
        else {
            return expiresAt.timeIntervalSinceNow
        }
    }
}
