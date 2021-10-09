//
//

import Foundation

extension Array where Element : Hashable {
    
    public func mapToDictionary<Value>(with block: (Element) -> Value?) -> Dictionary<Element, Value> {
        var dict = Dictionary<Element, Value>()
        forEach {
            if let value = block($0) {
                dict.updateValue(value, forKey: $0)
            }
        }
        return dict
    }
    public func mapToDictionaryWithOptionalValue<Value>(with block: (Element) -> Value?) -> Dictionary<Element, Value?> {
        var dict = Dictionary<Element, Value?>()
        forEach {
            dict.updateValue(block($0), forKey: $0)
        }
        return dict
    }
}

extension Set {
    
    public func mapToDictionary<Value>(with block: (Element) -> Value?) -> Dictionary<Element, Value> {
        var dict = Dictionary<Element, Value>()
        forEach {
            if let value = block($0) {
                dict.updateValue(value, forKey: $0)
            }
        }
        return dict
    }
}

public protocol Mergeable {
    func merged(with other: Self) -> Self
}

extension Dictionary where Value : Mergeable {
    
    public func merged(with other: Dictionary) -> Dictionary {
        var newDict = self
        other.forEach{ (key, value) in
            newDict[key] = newDict[key]?.merged(with: value) ?? value
        }
        return newDict
    }
}
