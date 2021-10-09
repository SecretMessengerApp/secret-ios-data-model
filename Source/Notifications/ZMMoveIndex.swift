//
//

@objcMembers public class ZMMovedIndex: NSObject {
    
    public let from: UInt
    public let to: UInt
    
    public init(from: UInt, to: UInt) {
        self.from = from
        self.to = to
        super.init()
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? ZMMovedIndex else { return false }
        return other.from == self.from && other.to == self.to
    }

    /// - seealso: https://en.wikipedia.org/wiki/Pairing_function#Cantor_pairing_function
    public override var hash: Int {
        return Int(((from + to) * (from + to + 1) / 2) + to)
    }
}
