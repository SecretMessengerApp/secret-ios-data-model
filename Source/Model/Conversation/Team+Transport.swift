//
//


private enum TeamTransportKey: String {
    case name, creator, icon, iconKey = "icon_key"
}


extension Team {

    public func update(with payload: [String: Any]) {
        if let teamName = payload[TeamTransportKey.name.rawValue] as? String {
            name = teamName
        }

        if let creatorId = (payload[TeamTransportKey.creator.rawValue] as? String).flatMap(UUID.init) {
            creator = ZMUser.fetchAndMerge(with: creatorId, createIfNeeded: true, in: managedObjectContext!)
            creator?.needsToBeUpdatedFromBackend = true
        }

        if let icon = payload[TeamTransportKey.icon.rawValue] as? String {
            pictureAssetId = icon
        }

        if let iconKey = payload[TeamTransportKey.iconKey.rawValue] as? String {
            pictureAssetKey = iconKey
        }
    }

}
