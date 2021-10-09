//
//


public enum SearchUserAsset: ExpressibleByNilLiteral, Hashable {
    case none
    case assetKey(String)

    public init(nilLiteral: ()) {
        self = .none
    }
}


public func ==(lhs: SearchUserAsset, rhs: SearchUserAsset) -> Bool {
    switch (lhs, rhs) {
    case (.none, .none): return true
    case (.assetKey(let leftKey), .assetKey(let rightKey)): return leftKey == rightKey
    default: return false
    }
}
