//
//

import Foundation

public extension NSManagedObjectContext {
    
    /// Executes a fetch request and asserts in case of error
    func fetchOrAssert<T>(request: NSFetchRequest<T>) -> [T] {
        do {
            let result = try fetch(request)
            return result
        } catch let error {
            fatal("Error in fetching \(error.localizedDescription)")
        }
    }
}
