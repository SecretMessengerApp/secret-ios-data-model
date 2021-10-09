// 
// 


import Foundation


/// A key path (as in key-value-coding).
public final class StringKeyPath : Hashable {
    
    public let rawValue: String
    public let count: Int

    static private var KeyPathCache : [String : StringKeyPath] = [:]
    
    public class func keyPathForString(_ string: String) -> StringKeyPath {
        
        if let keyPath = KeyPathCache[string] {
            return keyPath
        }
        else {
            let instance = StringKeyPath(string)
            KeyPathCache[string] = instance
            return instance
        }
    }
    
    private init(_ s: String) {
        rawValue = s
        count = rawValue.filter {
            $0 == "."
        }.count + 1
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue.hashValue)
    }

    
    public var isPath: Bool {
        return 1 < count
    }

    public lazy var decompose : (head: StringKeyPath, tail: StringKeyPath?)? = {
        if 1 <= self.count {
            if let i = self.rawValue.firstIndex(of: ".") {
                let head = self.rawValue[..<i]
                var tail : StringKeyPath?
                if i != self.rawValue.endIndex {
                    let nextIndex = self.rawValue.index(after: i)
                    let result = self.rawValue[nextIndex...]
                    tail = StringKeyPath.keyPathForString(String(result))
                }
                return (StringKeyPath.keyPathForString(String(head)), tail)
            }
            return (self, nil)
        }
        return nil
    }()
}

extension StringKeyPath : Equatable {
}
public func ==(lhs: StringKeyPath, rhs: StringKeyPath) -> Bool {
    // We store the hash which makes comparison very cheap.
    return (lhs.hashValue == rhs.hashValue) && (lhs.rawValue == rhs.rawValue)
}

extension StringKeyPath : CustomDebugStringConvertible {
    public var description: String {
        return rawValue
    }
    public var debugDescription: String {
        return rawValue
    }
}
