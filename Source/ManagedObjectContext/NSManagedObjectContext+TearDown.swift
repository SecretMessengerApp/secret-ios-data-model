//
//

import Foundation
import WireUtilities;

extension NSManagedObjectContext: TearDownCapable {
    
    /// Tear down the context. Using the context after this call results in
    /// undefined behavior.
    public func tearDown() {
        self.performGroupedBlockAndWait {
            self.tearDownUserInfo()
            let objects = self.registeredObjects
            objects.forEach {
                if let tearDownCapable = $0 as? TearDownCapable {
                    tearDownCapable.tearDown()
                }
                self.refresh($0, mergeChanges: false)
            }
        }
    }
    
    public func tearDownObject() {
        self.performGroupedBlockAndWait {
            let objects = self.registeredObjects
            objects.forEach {
                if let tearDownCapable = $0 as? TearDownCapable {
                    tearDownCapable.tearDown()
                }
                self.refresh($0, mergeChanges: false)
            }
        }
    }

    private func tearDownUserInfo() {
        let allKeys = userInfo.allKeys
        for value in userInfo.allValues {
            if let tearDownCapable = value as? TearDownCapable {
                tearDownCapable.tearDown()
            }
        }
        userInfo.removeObjects(forKeys: Array(allKeys))
    }
}
