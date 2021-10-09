//
// 


import Foundation
import WireCryptobox
import CoreLocation
import WireUtilities

public let ZMUserClientNumberOfKeysRemainingKey = "numberOfKeysRemaining"
public let ZMUserClientNeedsToUpdateSignalingKeysKey = "needsToUploadSignalingKeys"

public let ZMUserClientMarkedToDeleteKey = "markedToDelete"
public let ZMUserClientMissingKey = "missingClients"
public let ZMUserClientUserKey = "user"
let ZMUserClientLabelKey = "label"
public let ZMUserClientTrusted_ByKey = "trustedByClients"
public let ZMUserClientIgnored_ByKey = "ignoredByClients"
public let ZMUserClientTrustedKey = "trustedClients"
public let ZMUserClientIgnoredKey = "ignoredClients"
public let ZMUserClientNeedsToNotifyUserKey = "needsToNotifyUser"
public let ZMUserClientFingerprintKey = "fingerprint"
public let ZMUserClientRemoteIdentifierKey = "remoteIdentifier"

private let zmLog = ZMSLog(tag: "UserClient")

@objcMembers public class UserClient: ZMManagedObject, UserClientType {
    public var activationLatitude: Double {
        get {
            return activationLocationLatitude?.doubleValue ?? 0.0
        }
        set {
            activationLocationLatitude = NSNumber(value: activationLatitude)
        }
    }

    public var activationLongitude: Double {
        get {
            return activationLocationLongitude?.doubleValue ?? 0.0
        }
        set {
            activationLocationLongitude = NSNumber(value: activationLongitude)
        }
    }
    
    @NSManaged public var type: DeviceType
    @NSManaged public var label: String?
    @NSManaged public var markedToDelete: Bool
    @NSManaged public var preKeysRangeMax: Int64
    @NSManaged public var remoteIdentifier: String?
    @NSManaged public var user: ZMUser?
    @NSManaged public var missingClients: Set<UserClient>?
    @NSManaged public var missedByClient: UserClient?
    @NSManaged public var addedOrRemovedInSystemMessages: Set<ZMSystemMessage>
    @NSManaged public var messagesMissingRecipient: Set<ZMMessage>
    @NSManaged public var numberOfKeysRemaining: Int32
    @NSManaged public var activationAddress: String?
    @NSManaged public var activationDate: Date?
    @NSManaged public var discoveryDate: Date?
    @NSManaged public var model: String?
    @NSManaged public var deviceClass: DeviceClass?
    @NSManaged public var activationLocationLatitude: NSNumber?
    @NSManaged public var activationLocationLongitude: NSNumber?
    @NSManaged public var needsToNotifyUser: Bool
    @NSManaged public var fingerprint: Data?
    @NSManaged public var apsVerificationKey: Data?
    @NSManaged public var apsDecryptionKey: Data?
    @NSManaged public var needsToUploadSignalingKeys: Bool
    @NSManaged public var discoveredByMessage: ZMOTRMessage?
    @NSManaged public var triggerCode: Int16
    @NSManaged public var authKey: Data?

    private enum Keys {
        static let PushToken = "pushToken"
        static let ApnsPushToken = "apnsPushToken"
        static let DeviceClass = "deviceClass"
        static let AuthKeyId = "authKeyId"
    }
    
    @NSManaged public var primitiveAuthKeyId: String?
    public var authKeyId: UInt64? {
        set {
            if newValue != authKeyId {
                self.willChangeValue(forKey: Keys.AuthKeyId)
                if let n = newValue {
                    primitiveAuthKeyId = "\(n)"
                }
                self.didChangeValue(forKey: Keys.AuthKeyId)
            }
        }
        
        get {
            self.willAccessValue(forKey: Keys.AuthKeyId)
            var id: UInt64?
            if let pid = primitiveAuthKeyId {
                id = UInt64(pid)
            } else {
                id = nil
            }
            self.didAccessValue(forKey: Keys.AuthKeyId)
            return id
        }
    }
    
    @NSManaged private var primitivePushToken: Data?
    public var pushToken: PushToken? {
        set {
            precondition(!managedObjectContext!.zm_isUserInterfaceContext, "Push token should be set only on sync context")
            if newValue != pushToken {
                self.willChangeValue(forKey: Keys.PushToken)
                primitivePushToken = try? JSONEncoder().encode(newValue)
                self.didChangeValue(forKey: Keys.PushToken)
                setLocallyModifiedKeys([Keys.PushToken])
            }
        }
        get {
            self.willAccessValue(forKey: Keys.PushToken)
            let token: PushToken?
            if let data = primitivePushToken {
                token = try? JSONDecoder().decode(PushToken.self, from:data)
            } else {
                token = nil
            }
            self.didAccessValue(forKey: Keys.PushToken)
            return token
        }
    }
    
    @NSManaged private var primitiveApnsPushToken: Data?
    public var apnsPushToken: ApnsPushToken? {
        set {
            precondition(!managedObjectContext!.zm_isUserInterfaceContext, "Apns Push token should be set only on sync context")
            if newValue != apnsPushToken {
                self.willChangeValue(forKey: Keys.ApnsPushToken)
                primitiveApnsPushToken = try? JSONEncoder().encode(newValue)
                self.didChangeValue(forKey: Keys.ApnsPushToken)
                setLocallyModifiedKeys([Keys.ApnsPushToken])
            }
        }
        get {
            self.willAccessValue(forKey: Keys.ApnsPushToken)
            let token: ApnsPushToken?
            if let data = primitiveApnsPushToken {
                token = try? JSONDecoder().decode(ApnsPushToken.self, from:data)
            } else {
                token = nil
            }
            self.didAccessValue(forKey: Keys.ApnsPushToken)
            return token
        }
    }

    /// Clients that are trusted by self client.
    @NSManaged public var trustedClients: Set<UserClient>
    
    /// Clients that trust this client (currently can contain only self client)
    @NSManaged public var trustedByClients: Set<UserClient>
    
    /// Clients which trust is ignored by user
    @NSManaged public var ignoredClients: Set<UserClient>
    
    /// Clients that ignore this client trust (currently can contain only self client)
    @NSManaged public var ignoredByClients: Set<UserClient>
    
    public var keysStore: UserClientKeysStore {
        return managedObjectContext!.zm_cryptKeyStore
    }
    
    public var activationLocation: CLLocation {
        return CLLocation(latitude: self.activationLocationLatitude as! CLLocationDegrees, longitude: self.activationLocationLongitude as! CLLocationDegrees)
    }

    public var isLegalHoldDevice: Bool {
        return deviceClass == .legalHold || type == .legalHold
    }

    public override func awakeFromFetch() {
        super.awakeFromFetch()
        
        // Fetch fingerprint if not there yet (could remain nil after fetch)
        if let managedObjectContext = self.managedObjectContext,
            let _ = self.remoteIdentifier
            , !managedObjectContext.zm_isUserInterfaceContext && self.fingerprint == .none
        {
            self.fingerprint = self.fetchFingerprint()
        }
    }
    
    public var verified: Bool {
        let selfUser = ZMUser.selfUser(in: self.managedObjectContext!)
        guard let selfClient = selfUser.selfClient()
            else { return false }
        return selfClient.remoteIdentifier == self.remoteIdentifier || selfClient.trustedClients.contains(self)
    }
    
    public override static func entityName() -> String {
        return "UserClient"
    }

    public override func keysTrackedForLocalModifications() -> Set<String> {
        return [ZMUserClientMarkedToDeleteKey, ZMUserClientNumberOfKeysRemainingKey, ZMUserClientMissingKey, ZMUserClientNeedsToUpdateSignalingKeysKey, Keys.PushToken, Keys.ApnsPushToken]
    }
    
    public override static func sortKey() -> String {
        return ZMUserClientLabelKey
    }
    
    public override static func predicateForObjectsThatNeedToBeInsertedUpstream() -> NSPredicate {
        return NSPredicate(format: "%K == NULL", ZMUserClientRemoteIdentifierKey)
    }
    
    /// Insert a new client of the local self user.
    
    @discardableResult
    @objc(insertNewSelfClientInManagedObjectContext:selfUser:model:label:)
    public static func insertNewSelfClient(in managedObjectContext: NSManagedObjectContext, selfUser: ZMUser, model: String, label: String) -> UserClient {
        let userClient = UserClient.insertNewObject(in: managedObjectContext)
        userClient.user = selfUser
        userClient.model = model
        userClient.label = label
        userClient.deviceClass = model.hasSuffix("iPad") ? .tablet : .phone
        
        return userClient
    }
    
    public static func fetchUserClient(withRemoteId remoteIdentifier: String, forUser user:ZMUser, createIfNeeded: Bool) -> UserClient? {

        if let client = user.managedObjectContext?.getCacheManagedObject(uuidString: remoteIdentifier, clazz: UserClient.self) as? UserClient {
            return client
        }
        
        guard let context = user.managedObjectContext else {
            fatal("User \(user.safeForLoggingDescription) is not a member of a managed object context (deleted object).")
        }
        
        let relationClients = user.clients.filter({$0.remoteIdentifier == remoteIdentifier})
        
//        requireInternal(relationClients.count <= 1, "Detected duplicate clients: \(relationClients.map({ $0.safeForLoggingDescription }))")

        if let client = relationClients.first {
            relationClients.forEach { (c) in
                if c != client {
                    context.delete(c)
                }
            }
            user.managedObjectContext?.setCacheManagedObject(uuidString: remoteIdentifier, object: client)
            return client
        }
        
        if let client = self.fetchExistingUserClient(with: remoteIdentifier, in: context) {
            user.managedObjectContext?.setCacheManagedObject(uuidString: remoteIdentifier, object: client)
            return client
        }
        
        if (createIfNeeded) {
            let newClient = UserClient.insertNewObject(in: context)
            newClient.remoteIdentifier = remoteIdentifier
            newClient.user = user
            newClient.needsToBeUpdatedFromBackend = true
            newClient.discoveryDate = Date()
            // Form reverse relationship
            user.mutableSetValue(forKey: "clients").add(newClient)
            user.managedObjectContext?.setCacheManagedObject(uuidString: remoteIdentifier, object: newClient)
            return newClient
        }
        
        return nil
    }
    
    /// Update a user client with a backend payload
    ///
    /// If called on a client belonging to the self user this method does nothing.
    
    public func update(with payload: [String: Any]) {
        //guard user?.isSelfUser == false, let deviceClass = payload["class"] as? String else { return }
 
        self.needsToBeUpdatedFromBackend = false
        guard let deviceClass = payload["class"] as? String else { return }
        
        self.deviceClass = DeviceClass(rawValue: deviceClass)
    }

    /// Resets releationships and ends an exisiting session before deleting the object
    /// Call this from the syncMOC only
    public func deleteClientAndEndSession() {
        assert(!self.managedObjectContext!.zm_isUserInterfaceContext, "clients can't be deleted on uiContext")
        // hold on to the conversations that are affected by removing this client
        
        self.failedToEstablishSession = false
        // reset the session
        if let sessionIdentifier = self.sessionIdentifier {
            UserClient.deleteSession(for: sessionIdentifier, managedObjectContext: managedObjectContext!)
        }
        // reset the relationship
        self.user = nil

        // delete the object
        managedObjectContext?.delete(self)
    }
    
    /// Checks if there is an existing session with the selfClient
    /// Access this property only from the syncContext
    public var hasSessionWithSelfClient: Bool {
        guard let selfClient = ZMUser.selfUser(in: managedObjectContext!).selfClient()
            else {
                zmLog.error("SelfUser has no selfClient")
                return false
        }
        var hasSession = false
        selfClient.keysStore.encryptionContext.perform { [weak self](sessionsDirectory) in
            guard let strongSelf = self, let sessionIdentifier = strongSelf.sessionIdentifier else {return}
            hasSession = sessionsDirectory.hasSession(for: sessionIdentifier)
        }
        return hasSession
    }
    
    /// Resets the session between the client and the selfClient
    /// Can be called several times without issues
    public func resetSession() {
        guard let sessionIdentifier = self.sessionIdentifier,
              let uiMOC = self.managedObjectContext?.zm_userInterface,
              let syncMOC = uiMOC.zm_sync
        else { return }

        // Delete should happen on sync context since the cryptobox could be accessed only from there
        syncMOC.performGroupedBlock {
            guard let selfClient = ZMUser.selfUser(in: syncMOC).selfClient(),
                  let syncClient = (try? syncMOC.existingObject(with: self.objectID)) as? UserClient
            else { return }

            // Delete session and fingerprint
            UserClient.deleteSession(for: sessionIdentifier, managedObjectContext: syncMOC)
            syncClient.fingerprint = .none
            
            // Mark clients as needing to be refetched
            selfClient.missesClient(syncClient)
            syncMOC.saveOrRollback()
            let userID = self.user!.objectID
            
            uiMOC.performGroupedBlock {
                // Send session reset message so other user can send us messages immediately
                guard
                    let user = (try? uiMOC.existingObject(with: userID)) as? ZMUser,
                    let conversation = self.conversation(for: user) else { return }
                GenericMessageScheduleNotification.post(message: ZMGenericMessage.clientAction(ZMClientAction.RESETSESSION), conversation: conversation)
            }
        }
    }

    private func conversation(for user: ZMUser) -> ZMConversation? {
        if user.isSelfUser {
            guard let moc = user.managedObjectContext else { return nil }
            return ZMConversation.selfConversation(in: moc)
        } else {
            return user.oneToOneConversation
        }
    }

}


// MARK: - SelfUser client methods (selfClient + other clients of the selfUser)
public extension UserClient {

    @objc static func fetchExistingUserClient(with remoteIdentifier: String, in context: NSManagedObjectContext) -> UserClient? {
        let fetchRequest = NSFetchRequest<UserClient>(entityName: UserClient.entityName())
        fetchRequest.predicate = NSPredicate(format: "%K == %@", ZMUserClientRemoteIdentifierKey, remoteIdentifier)
        fetchRequest.fetchLimit = 1
        
        return context.fetchOrAssert(request: fetchRequest).first
    }
    
    /// Use this method only for selfUser clients (selfClient + remote clients)
    @objc static func createOrUpdateSelfUserClient(_ payloadData: [String: AnyObject], context: NSManagedObjectContext) -> UserClient? {
        
        guard let id = payloadData["id"] as? String,
              let type = payloadData["type"] as? String
        else { return nil }
            
        let payloadAsDictionary = payloadData as NSDictionary
        
        let label = payloadAsDictionary.optionalString(forKey: "label")?.removingExtremeCombiningCharacters
        let activationAddress = payloadAsDictionary.optionalString(forKey: "address")?.removingExtremeCombiningCharacters
        let model = payloadAsDictionary.optionalString(forKey: "model")?.removingExtremeCombiningCharacters
        let deviceClass = payloadAsDictionary.optionalString(forKey: "class")
        let activationDate = payloadAsDictionary.date(for: "time")
        
        let locationCoordinates = payloadData["location"] as? [String: Double]
        let latitude = (locationCoordinates?["lat"] as NSNumber?) ?? 0
        let longitude = (locationCoordinates?["lon"] as NSNumber?) ?? 0
        
        // TODO: could optimize: look into self user relationship before executing a fetch request
        let fetchedClient = fetchExistingUserClient(with: id, in: context)
        let client = fetchedClient ?? UserClient.insertNewObject(in: context)
        let isNewClient = fetchedClient == nil
        
        client.label = label
        client.type = DeviceType(rawValue: type)
        client.activationAddress = activationAddress
        client.model = model
        client.deviceClass = deviceClass.map { DeviceClass(rawValue: $0) }
        client.activationDate = activationDate
        client.activationLocationLatitude = latitude
        client.activationLocationLongitude = longitude
        client.remoteIdentifier = id
        
        let selfUser = ZMUser.selfUser(in: context)
        client.user = client.user ?? selfUser

        if client.isLegalHoldDevice, isNewClient {
            selfUser.legalHoldRequest = nil
            selfUser.needsToAcknowledgeLegalHoldStatus = true
        }

        if let selfClient = selfUser.selfClient() {
            if client.remoteIdentifier != selfClient.remoteIdentifier && isNewClient {
                client.fetchFingerprintOrPrekeys()
                
                if let selfClientActivationdate = selfClient.activationDate , client.activationDate?.compare(selfClientActivationdate) == .orderedDescending {
                    client.needsToNotifyUser = true
                }
            }
            
            // We could already set local fingerprint if user is self
            if client.remoteIdentifier == selfClient.remoteIdentifier {
                client.keysStore.encryptionContext.perform({ (sessionsDirectory) in
                    client.fingerprint = sessionsDirectory.localFingerprint
                    if client.fingerprint == nil {
                        zmLog.error("Cannot fetch local fingerprint for \(client)")
                    }
                })
            }
        }
        
        return client
        
    }

    /// Use this method only for selfUser clients (selfClient + remote clients)
    @objc func markForDeletion() {
        guard let context = self.managedObjectContext else {
            zmLog.error("Object already deleted?")
            return
        }
        let selfUser = ZMUser.selfUser(in: context)
        guard self.user == selfUser else {
            fatal("The method 'markForDeletion()' can only be called for clients that belong to the selfUser (self user is \(selfUser.safeForLoggingDescription))")
        }
        guard selfUser.selfClient() != self else {
            fatal("Attempt to delete the self client. This should never happen!")
        }
        self.markedToDelete = true
        self.setLocallyModifiedKeys(Set(arrayLiteral: ZMUserClientMarkedToDeleteKey))
    }
    
    @available(*, deprecated)
    func markForFetchingPreKeys() {
        self.fetchFingerprintOrPrekeys()
    }
    
    @objc func fetchFingerprintOrPrekeys() {
        guard self.fingerprint == .none,
            let syncMOC = self.managedObjectContext?.zm_sync
            else { return }

        if self.objectID.isTemporaryID {
            do {
                try syncMOC.obtainPermanentIDs(for: [self])
            } catch {
                fatal("Error obtaining permanent id for client")
            }
        }
        
        let selfObjectID = self.objectID
        
        syncMOC.performGroupedBlock({ [unowned syncMOC] () -> Void in
            guard let obj = try? syncMOC.existingObject(with: selfObjectID),
                  let syncClient = obj as? UserClient,
                  let sessionIdentifier = syncClient.sessionIdentifier,
                  let syncSelfClient = ZMUser.selfUser(in: syncMOC).selfClient()
                else { return }
            
            if syncSelfClient == syncClient {
                syncSelfClient.keysStore.encryptionContext.perform({ (sessionsDirectory) in
                    syncClient.fingerprint = sessionsDirectory.localFingerprint
                    syncMOC.saveOrRollback()
                })
            }
            else {
                if !syncClient.hasSessionWithSelfClient {
                    syncSelfClient.missesClient(syncClient)
                    syncSelfClient.setLocallyModifiedKeys(Set(arrayLiteral: ZMUserClientMissingKey))
                    syncMOC.saveOrRollback()
                }
                else {
                    syncSelfClient.keysStore.encryptionContext.perform({ (sessionsDirectory) in
                        syncClient.fingerprint = sessionsDirectory.fingerprint(for: sessionIdentifier)
                        if syncClient.fingerprint == nil {
                            zmLog.error("Cannot fetch fingerprint for client \(syncClient.sessionIdentifier!)")
                        } else {
                            syncMOC.saveOrRollback()
                        }
                    })
                }
            }
        })
    }
}


// MARK: - Corrupted Session

public extension UserClient {
    
    @objc var failedToEstablishSession: Bool {
        set {
            if newValue {
                managedObjectContext?.zm_failedToEstablishSessionStore?.add(self)
            } else {
                managedObjectContext?.zm_failedToEstablishSessionStore?.remove(self)
            }
        }
        
        get {
            return managedObjectContext?.zm_failedToEstablishSessionStore?.contains(self) ?? false
        }
    }
}


// MARK: - SelfClient methods
public extension UserClient {
    
    @objc func isSelfClient() -> Bool {
        guard let managedObjectContext = managedObjectContext,
            let selfClient = ZMUser.selfUser(in: managedObjectContext).selfClient()
            else { return false }
        return self == selfClient
    }
    
    @objc func missesClient(_ client: UserClient) {
        missesClients(Set(arrayLiteral: client))
    }
    
    @objc func missesClients(_ clients: Set<UserClient>) {
        
        zmLog.debug("Adding clients(\( clients.count)) to list of missing clients")

        self.mutableSetValue(forKey: ZMUserClientMissingKey).union(clients)
        if !hasLocalModifications(forKey: ZMUserClientMissingKey) {
            setLocallyModifiedKeys(Set(arrayLiteral: ZMUserClientMissingKey))
        }
        self.triggerCode = Int16(arc4random() % 100)
    }
    
    /// Use this method only for the selfClient
    @objc func removeMissingClient(_ client: UserClient) {
        zmLog.debug("Removing client from list of missing clients")
        
        self.mutableSetValue(forKey: ZMUserClientMissingKey).remove(client)
    }
    
    /// Deletes the session between the selfClient and the given userClient
    /// If there is no session it does nothing
    static func deleteSession(for clientID: EncryptionSessionIdentifier, managedObjectContext: NSManagedObjectContext) {
        guard let selfClient = ZMUser.selfUser(in: managedObjectContext).selfClient() , selfClient.sessionIdentifier != clientID
            else { return }
        
        selfClient.keysStore.encryptionContext.perform { (sessionsDirectory) in
            sessionsDirectory.delete(clientID)
        }
    }
    
    /// Creates a session between the selfClient and the given userClient
    /// Returns false if the session could not be established
    /// Use this method only for the selfClient
    func establishSessionWithClient(_ client: UserClient, usingPreKey preKey: String) -> Bool {
        guard isSelfClient(), let sessionIdentifier = client.sessionIdentifier else { return false }
        
        var didEstablishSession = false
        
        keysStore.encryptionContext.perform { (sessionsDirectory) in
            
            // Session is already established?
            if sessionsDirectory.hasSession(for: sessionIdentifier) {
                zmLog.debug("Session with \(sessionIdentifier) was already established, re-creating")
                sessionsDirectory.delete(sessionIdentifier)
            }
        }
        
        // Because of caching within the `perform` block, it commits to disk only at the end of a block. 
        // I don't think the cache is smart enough to perform the sum of operations (delete + recreate)
        // if at the end of the block the session is still there. Just to be safe, I split the operations
        // in two separate `perform` blocks.
        
        keysStore.encryptionContext.perform { (sessionsDirectory) in
            do {
                try sessionsDirectory.createClientSession(sessionIdentifier, base64PreKeyString: preKey)
                client.fingerprint = sessionsDirectory.fingerprint(for: sessionIdentifier)
                didEstablishSession = true
            } catch {
                zmLog.error("Cannot create session for prekey \(preKey)")
            }
        }
        
        return didEstablishSession;
    }
    
    fileprivate func fetchFingerprint() -> Data? {
        var fingerprint : Data?
        keysStore.encryptionContext.perform { [weak self] (sessionsDirectory) in
            guard let strongSelf = self, let sessionIdentifier = strongSelf.sessionIdentifier else { return }
            fingerprint = sessionsDirectory.fingerprint(for: sessionIdentifier)
        }
        return fingerprint
    }
    
    /// Use this method only for the selfClient
    @objc func decrementNumberOfRemainingKeys() {
        guard isSelfClient() else { fatal("`decrementNumberOfRemainingKeys` should only be called on the self client") }
        
        if numberOfKeysRemaining > 0 {
            numberOfKeysRemaining -= 1
        }
        if numberOfKeysRemaining < 0 { // this will recover from the fact that the number might already be < 0
                                       // from a previous run
            numberOfKeysRemaining = 0
        }
        if numberOfKeysRemaining == 0 {
            self.setLocallyModifiedKeys(Set(arrayLiteral: ZMUserClientNumberOfKeysRemainingKey))
        }
    }
}

enum SecurityChangeType {
    case clientTrusted // a client was trusted by the user on this device
    case clientDiscovered // a client was discovered, either by receiving a missing response, a message, or fetching all clients
    case clientIgnored // a client was ignored by the user on this device
    
    func changeSecurityLevel(_ conversation: ZMConversation, clients: Set<UserClient>, causedBy: ZMOTRMessage?) {
        switch (self) {
        case .clientTrusted:
            conversation.increaseSecurityLevelIfNeededAfterTrusting(clients: clients)
        case .clientIgnored:
            conversation.decreaseSecurityLevelIfNeededAfterIgnoring(clients: clients)
        case .clientDiscovered:
            conversation.decreaseSecurityLevelIfNeededAfterDiscovering(clients: clients, causedBy: causedBy)
        }
    }
}


// MARK: - Trusting
extension UserClient {
    
    @objc public func trustClient(_ client: UserClient) {
        trustClients(Set(arrayLiteral: client))
    }
    
    /// Will change conversations security level as side effect
    @objc public func trustClients(_ clients: Set<UserClient>) {
        guard clients.count > 0 else { return }
        self.mutableSetValue(forKey: ZMUserClientIgnoredKey).minus(clients)
        self.mutableSetValue(forKey: ZMUserClientTrustedKey).union(clients)
        
        clients.forEach { client in client.needsToNotifyUser = false; }
        
        zmLog.debug("Marking client as trusted")
        
        self.changeSecurityLevel(.clientTrusted, clients: clients, causedBy: nil)
    }
    
    /// Ignore a know client
    @objc public func ignoreClient(_ client: UserClient) {
        ignoreClients(Set(arrayLiteral: client))
    }
    
    /// Adds to ignored clients, remove from trusted clients, returns the set with the self client excluded
    fileprivate func addIgnoredClients(_ clients: Set<UserClient>) -> Set<UserClient> {
        let notSelfClients = Set(clients.filter {$0 != self})

        guard notSelfClients.count > 0 else { return notSelfClients }
        
        zmLog.debug("Marking client as ignored")
        
        self.mutableSetValue(forKey: ZMUserClientTrustedKey).minus(notSelfClients)
        self.mutableSetValue(forKey: ZMUserClientIgnoredKey).union(notSelfClients)
        
        return notSelfClients
    }

    /// Ignore known clients
    @objc public func ignoreClients(_ clients: Set<UserClient>) {
        let notSelfClients = self.addIgnoredClients(clients)
        guard notSelfClients.count > 0 else { return}
        self.changeSecurityLevel(.clientIgnored, clients: notSelfClients, causedBy: .none)
    }
    
    /// Adds a new client that was just discovered to the ignored ones
    @objc public func addNewClientToIgnored(_ client: UserClient) {
        addNewClientsToIgnored(Set(arrayLiteral: client))
    }

    /// Add new clients that were just discovered to the ignored ones
    @objc public func addNewClientsToIgnored(_ clients: Set<UserClient>) {
        _ = self.addIgnoredClients(clients)

    }
    
    public func updateSecurityLevelAfterDiscovering(_ clients: Set<UserClient>) {
//        changeSecurityLevel(.clientDiscovered, clients: clients, causedBy: clients.compactMap(\.discoveredByMessage).first)
    }
    
    func activeConversationsForUserOfClients(_ clients: Set<UserClient>) -> Set<ZMConversation> {
        let conversations : Set<ZMConversation> = clients.map(\.user).reduce(into: []) {
            guard let user = $1 else { return }
            guard user.isSelfUser else {
                return $0.formUnion(user.lastServerSyncedActiveConversations.array as! [ZMConversation])
            }
            let fetchRequest = NSFetchRequest<ZMConversation>(entityName: ZMConversation.entityName())
            fetchRequest.predicate = ZMConversation.predicateForConversationsIncludingArchived()
            let conversations = managedObjectContext!.fetchOrAssert(request: fetchRequest)
            return $0.formUnion(conversations)
        }
        return conversations
    }
    
    func changeSecurityLevel(_ securityChangeType: SecurityChangeType, clients: Set<UserClient>, causedBy: ZMOTRMessage?) {
        let conversations = activeConversationsForUserOfClients(clients)
        conversations.forEach { conversation in
            if !conversation.isReadOnly {
                let clientsInConversation = clients.filter() { client in
                    guard let user = client.user else { return false }
                    return conversation.activeParticipants.contains(user)
                }
                securityChangeType.changeSecurityLevel(conversation, clients: Set(clientsInConversation), causedBy: causedBy)
            }
        }
    }
}

// MARK: - APSSignaling
extension UserClient {

    public static func resetSignalingKeysInContext(_ context: NSManagedObjectContext) {
        guard let selfClient = ZMUser.selfUser(in: context).selfClient()
        else { return }
        
        selfClient.apsDecryptionKey = nil
        selfClient.apsVerificationKey = nil
        selfClient.needsToUploadSignalingKeys = true
        selfClient.setLocallyModifiedKeys(Set(arrayLiteral: ZMUserClientNeedsToUpdateSignalingKeysKey))
        
        context.enqueueDelayedSave()
    }

}

