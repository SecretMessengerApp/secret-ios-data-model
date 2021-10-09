////
//

import Foundation
import WireUtilities

private let log = ZMSLog(tag: "Backup")

extension StorageStack {

    private static let metadataFilename = "export.json"
    private static let databaseDirectoryName = "data"
    private static let workQueue = DispatchQueue(label: "database backup", qos: .userInitiated)
    private static let fileManager = FileManager()
    
    // Each backup for any account will be created in a unique subdirectory inside.
    // Calling `clearBackupDirectory` will remove this directory and all backups.
    public static var backupsDirectory: URL {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return tempURL.appendingPathComponent("backups")
    }
    
    // Directory in which unzipped backups should be places.
    // This directory is located inside of `backupsDirectory`.
    // Calling `clearBackupDirectory` will remove this directory.
    public static var importsDirectory: URL {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return tempURL.appendingPathComponent("imports")
    }

    public enum BackupError: Error {
        case failedToRead
        case failedToWrite(Error)
    }
    
    public struct BackupInfo {
        public let url: URL
        public let metadata: BackupMetadata
    }
    
    // Calling this method will delete all backups stored inside `backupsDirectory`
    // as well as inside `importsDirectory` if there are any.
    public static func clearBackupDirectory(dispatchGroup: ZMSDispatchGroup? = nil) {
        func remove(at url: URL) {
            do {
                guard fileManager.fileExists(atPath: url.path) else { return }
                try fileManager.removeItem(at: url)
            } catch {
                log.debug("error removing directory: \(error)")
            }
        }
        
        workQueue.async(group: dispatchGroup) {
            remove(at: backupsDirectory)
            remove(at: importsDirectory)
        }
    }

    /// Will make a copy of account storage and place in a unique directory
    ///
    /// - Parameters:
    ///   - accountIdentifier: identifier of account being backed up
    ///   - applicationContainer: shared application container
    ///   - dispatchGroup: group for testing
    ///   - completion: called on main thread when done. Result will contain the folder where all data was written to.
    public static func backupLocalStorage(
        accountIdentifier: UUID,
        clientIdentifier: String,
        applicationContainer: URL,
        dispatchGroup: ZMSDispatchGroup? = nil,
        completion: @escaping (Result<BackupInfo>) -> Void
        ) {

        func fail(_ error: BackupError) {
            log.debug("error backing up local store: \(error)")
            DispatchQueue.main.async(group: dispatchGroup) {
                completion(.failure(error))
            }
        }
        
        let accountDirectory = StorageStack.accountFolder(accountIdentifier: accountIdentifier, applicationContainer: applicationContainer)
        let storeFile = accountDirectory.appendingPersistentStoreLocation()

        guard fileManager.fileExists(atPath: accountDirectory.path) else { return fail(.failedToRead) }

        let backupDirectory = backupsDirectory.appendingPathComponent(UUID().uuidString)
        let databaseDirectory = backupDirectory.appendingPathComponent(databaseDirectoryName)
        let metadataURL = backupDirectory.appendingPathComponent(metadataFilename)

        workQueue.async(group: dispatchGroup) {
            do {
                let coordinator = NSPersistentStoreCoordinator(managedObjectModel: .loadModel())

                // Create target directory
                try fileManager.createDirectory(at: databaseDirectory, withIntermediateDirectories: true, attributes: nil)
                let backupLocation = databaseDirectory.appendingStoreFile()
                let options = NSPersistentStoreCoordinator.persistentStoreOptions(supportsMigration: false)

                // Recreate the persistent store inside a new location
                try coordinator.replacePersistentStore(
                    at: backupLocation,
                    destinationOptions: options,
                    withPersistentStoreFrom: storeFile,
                    sourceOptions: options,
                    ofType: NSSQLiteStoreType
                )

                // Mark the database as imported from a history backup
                try markAsImported(coordinator: coordinator, location: backupLocation, options: options)

                // Create & write metadata
                let metadata = BackupMetadata(userIdentifier: accountIdentifier, clientIdentifier: clientIdentifier)
                try metadata.write(to: metadataURL)
                log.info("successfully created backup at: \(backupDirectory.path), metadata: \(metadata)")
                
                DispatchQueue.main.async(group: dispatchGroup) {
                    completion(.success(.init(url: backupDirectory, metadata: metadata)))
                }
            } catch {
                fail(.failedToWrite(error))
            }
        }
    }
    
    private static func markAsImported(coordinator: NSPersistentStoreCoordinator, location: URL, options: [String: Any]) throws {
        // Add persistent store at the new location to allow creation of NSManagedObjectContext
        let store = try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: location, options: options)
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        var storeMetadata = store.metadata
        
        // Mark the db as backed up
        storeMetadata?[PersistentMetadataKey.importedFromBackup.rawValue] = NSNumber(booleanLiteral: true)
        store.metadata = storeMetadata

        // Save context & forward error
        try context.performGroupedAndWait { context in
            try context.save()
        }
    }
    
    public enum BackupImportError: Error {
        case incompatibleBackup(Error)
        case failedToCopy(Error)
    }
    
    /// Will import a backup for a given account
    ///
    /// - Parameters:
    ///   - accountIdentifier: account for which to import the backup
    ///   - backupDirectory: root directory of the decrypted and uncompressed backup
    ///   - applicationContainer: shared application container
    ///   - dispatchGroup: group for testing
    ///   - completion: called on main thread when done. Result will contain the folder where all data was written to.
    public static func importLocalStorage(
        accountIdentifier: UUID,
        from backupDirectory: URL,
        applicationContainer: URL,
        dispatchGroup: ZMSDispatchGroup? = nil,
        completion: @escaping ((Result<URL>) -> Void)
        ) {
        
        func fail(_ error: BackupImportError) {
            log.debug("error backing up local store: \(error)")
            DispatchQueue.main.async(group: dispatchGroup) {
                completion(.failure(error))
            }
        }
        
        let accountDirectory = accountFolder(accountIdentifier: accountIdentifier, applicationContainer: applicationContainer)
        let accountStoreFile = accountDirectory.appendingPersistentStoreLocation()
        let backupStoreFile = backupDirectory.appendingPathComponent(databaseDirectoryName).appendingStoreFile()
        let metadataURL = backupDirectory.appendingPathComponent(metadataFilename)
        
        workQueue.async(group: dispatchGroup) {
            do {
                let metadata = try BackupMetadata(url: metadataURL)
                
                let model = NSManagedObjectModel.loadModel()
                if let verificationError = metadata.verify(using: accountIdentifier, modelVersionProvider: model) {
                    return fail(.incompatibleBackup(verificationError))
                }
                
                let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
                
                // Create target directory
                try fileManager.createDirectory(at: accountStoreFile.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
                let options = NSPersistentStoreCoordinator.persistentStoreOptions(supportsMigration: false)
                
                // Import the persistent store to the account data directory
                try coordinator.replacePersistentStore(
                    at: accountStoreFile,
                    destinationOptions: options,
                    withPersistentStoreFrom: backupStoreFile,
                    sourceOptions: options,
                    ofType: NSSQLiteStoreType
                )

                log.info("succesfully imported backup with metadata: \(metadata)")

                DispatchQueue.main.async(group: dispatchGroup) {
                    completion(.success(accountDirectory))
                }
            } catch let error {
                fail(.failedToCopy(error))
            }
        }
    }

}
