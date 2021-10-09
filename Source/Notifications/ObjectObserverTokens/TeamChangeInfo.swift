//
//


import Foundation
import WireSystem

extension Team : ObjectInSnapshot {
    
    static public var observableKeys : Set<String> {
        return [
            #keyPath(Team.name),
            #keyPath(Team.members),
            #keyPath(Team.imageData),
            #keyPath(Team.pictureAssetId),
        ]
    }
    
    public var notificationName : Notification.Name {
        return .TeamChange
    }
}


@objcMembers public class TeamChangeInfo : ObjectChangeInfo {
    
    static func changeInfo(for team: Team, changes: Changes) -> TeamChangeInfo? {
        guard changes.changedKeys.count > 0 || changes.originalChanges.count > 0 else { return nil }
        let changeInfo = TeamChangeInfo(object: team)
        changeInfo.changeInfos = changes.originalChanges
        changeInfo.changedKeys = changes.changedKeys
        return changeInfo
    }
    
    public required init(object: NSObject) {
        self.team = object as! Team
        super.init(object: object)
    }
    
    public let team: TeamType
    
    public var membersChanged : Bool {
        return changedKeys.contains(#keyPath(Team.members))
    }

    public var nameChanged : Bool {
        return changedKeys.contains(#keyPath(Team.name))
    }
    
    public var imageDataChanged : Bool {
        return changedKeysContain(keys: #keyPath(Team.imageData), #keyPath(Team.pictureAssetId))
    }

}



@objc public protocol TeamObserver : NSObjectProtocol {
    func teamDidChange(_ changeInfo: TeamChangeInfo)
}


extension TeamChangeInfo {
    
    // MARK: Registering TeamObservers
    
    /// Adds an observer for a team
    ///
    /// You must hold on to the token and use it to unregister
    @objc(addTeamObserver:forTeam:)
    public static func add(observer: TeamObserver, for team: Team) -> NSObjectProtocol {
        return add(observer: observer, for: team, managedObjectContext: team.managedObjectContext!)
    }
    
    /// Adds an observer for the team if one specified or to all Teams is none is specified
    ///
    /// You must hold on to the token and use it to unregister
    @objc(addTeamObserver:forTeam:managedObjectContext:)
    public static func add(observer: TeamObserver, for team: Team?, managedObjectContext: NSManagedObjectContext) -> NSObjectProtocol {
        return ManagedObjectObserverToken(name: .TeamChange, managedObjectContext: managedObjectContext, object: team)
        { [weak observer] (note) in
            guard let `observer` = observer,
                let changeInfo = note.changeInfo as? TeamChangeInfo
                else { return }
            
            observer.teamDidChange(changeInfo)
        }
    }
    
}





