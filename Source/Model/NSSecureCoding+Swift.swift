//
//


import Foundation

/// Helper to conveniently use the `NSSecureCoding` method
/// `decodeObjectOfClass:forKey:` with `String` and `Data` without casting.
extension NSCoder {

    func decodeString(forKey key: String) -> String? {
        return decodeObject(of: NSString.self, forKey: key) as String?
    }

    func decodeData(forKey key: String) -> Data? {
        return decodeObject(of: NSData.self, forKey: key) as Data?
    }

}
