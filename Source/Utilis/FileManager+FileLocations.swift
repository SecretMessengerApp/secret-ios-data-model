//
//

import Foundation
import WireSystem

private let zmLog = ZMSLog(tag: "FileLocation")

public extension FileManager {
    
    /// Returns the URL for the sharedContainerDirectory of the app
    @objc(sharedContainerDirectoryForAppGroupIdentifier:)
    static func sharedContainerDirectory(for appGroupIdentifier: String) -> URL {
        let fm = FileManager.default
        let sharedContainerURL = fm.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
        
        // Seems like the shared container is not available. This could happen for series of reasons:
        // 1. The app is compiled with with incorrect provisioning profile (for example with 3rd parties)
        // 2. App is running on simulator and there is no correct provisioning profile on the system
        // 3. Bug with signing
        //
        // The app should not allow to run in all those cases.
        
        require(nil != sharedContainerURL, "Unable to create shared container url using app group identifier: \(appGroupIdentifier)")
    
        return sharedContainerURL!
    }
    
    @objc static let cachesFolderPrefix : String = "wire-account"

    /// Returns the URL for caches appending the accountIdentifier if specified
    @objc func cachesURL(forAppGroupIdentifier appGroupIdentifier: String, accountIdentifier: UUID?) -> URL? {
        guard let sharedContainerURL = containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else { return nil }
        return cachesURLForAccount(with: accountIdentifier, in: sharedContainerURL)
    }
    
    /// Returns the URL for caches appending the accountIdentifier if specified
    @objc func cachesURLForAccount(with accountIdentifier: UUID?, in sharedContainerURL: URL) -> URL {
        let url = sharedContainerURL.appendingPathComponent("Library", isDirectory: true)
                                    .appendingPathComponent("Caches", isDirectory: true)
        if let accountIdentifier = accountIdentifier {
            return url.appendingPathComponent("\(type(of:self).cachesFolderPrefix)-\(accountIdentifier.uuidString)", isDirectory: true)
        }
        return url
    }
    
    
}
