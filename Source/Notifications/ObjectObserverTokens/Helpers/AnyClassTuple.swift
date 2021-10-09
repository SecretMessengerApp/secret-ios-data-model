// 
// 


import Foundation

public struct AnyClassTuple<T : Hashable> : Hashable {
    
    public let classOfObject : AnyClass
    public let secondElement : T

    public init(classOfObject: AnyClass, secondElement: T) {
        self.classOfObject = classOfObject
        self.secondElement = secondElement
    }

    public func hash(into hasher: inout Hasher) {
        let classHash = "\(classOfObject)".hashValue
        let elementHash = secondElement.hashValue

        hasher.combine(classHash)
        hasher.combine(elementHash)
    }

}

public func ==<T>(lhs: AnyClassTuple<T>, rhs: AnyClassTuple<T>) -> Bool {
    // We store the hash which makes comparison very cheap.
    return (lhs.hashValue == rhs.hashValue)
        && (lhs.secondElement == rhs.secondElement)
        && (lhs.classOfObject === rhs.classOfObject)
}
