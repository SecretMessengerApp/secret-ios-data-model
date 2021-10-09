//
//


public enum MessageDestructionSendDisableValue: RawRepresentable, Hashable {
    
    case none
    case tenSeconds
    case oneHours
    case twelveHours
    case oneDay
    case forever
    
    case custom(TimeInterval)
    
    public init(rawValue: TimeInterval) {
        switch rawValue {
        case 0: self = .none
        case 600: self = .tenSeconds
        case 3600: self = .oneHours
        case 43200: self = .twelveHours
        case 86400: self = .oneDay
        case -1: self = .forever
        default: self = .custom(rawValue)
        }
    }
    
    public var rawValue: TimeInterval {
        switch self {
        case .none: return 0
        case .tenSeconds: return 600
        case .oneHours: return 3600
        case .twelveHours: return 43200
        case .oneDay: return 86400
        case .forever: return -1
        case .custom(let duration): return duration
        }
    }
    
    
}

extension MessageDestructionSendDisableValue: ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral {
    public init(integerLiteral value: TimeInterval) {
        self.init(rawValue: value)
    }
    
    public init(floatLiteral value: TimeInterval) {
        self.init(rawValue: value)
    }
}

public extension MessageDestructionSendDisableValue {
    
    static var all: [MessageDestructionSendDisableValue] {
        return [
            .none,
            .tenSeconds,
            .oneHours,
            .twelveHours,
            .oneDay,
            .forever
        ]
    }
}

public extension MessageDestructionSendDisableValue {
    
    public var isKnownSendDisable: Bool {
        if case .custom = self {
            return false
        }
        return true
    }
    
}

public extension MessageDestructionSendDisableValue {
    
    var displayString: String? {
        guard .none != self else { return NSLocalizedString("input.ephemeral.timeout.none", comment: "") }
        var display: String?
        display = longStyleFormatter.string(from: TimeInterval(rawValue))
        if case .forever = self {
            display = NSLocalizedString("conversation.setting.disableSendMsg.duration.forever", comment: "")
        }
        return display
    }
    
    var shortDisplayString: String? {
        if isSeconds { return String(Int(rawValue)) }
        if isMinutes { return String(Int(rawValue / 60)) }
        if isHours { return String(Int(rawValue / 3600)) }
        if isDays { return String(Int(rawValue / 86400)) }
        if isWeeks { return String(Int(rawValue / 604800)) }
        if isYears { return String(Int(rawValue / TimeInterval.oneYearSinceNow())) }
        return nil
    }
    
}

public extension MessageDestructionSendDisableValue {
    
    var isSeconds: Bool {
        return rawValue < 60 && rawValue > 0
    }
    
    var isMinutes: Bool {
        return 60..<3600 ~= rawValue
    }
    
    var isHours: Bool {
        return 3600..<86400 ~= rawValue
    }
    
    var isDays: Bool {
        return 86400..<604800 ~= rawValue
    }
    
    var isWeeks: Bool {
        return rawValue >= 604800 && !isYears
    }
    
    var isYears: Bool {
        return rawValue >= TimeInterval.oneYearSinceNow()
    }
    
}

extension Int64 {
    
    public var displayString: String {
        var disableValue: MessageDestructionSendDisableValue?
        if 0 == self {
            disableValue = .none
        } else if -1 == self {
            disableValue = .forever
        } else if 600 == self {
            disableValue = .tenSeconds
        } else if 3600 == self {
            disableValue = .oneHours
        } else if 43200 == self {
            disableValue = .twelveHours
        } else if 86400 == self {
            disableValue = .oneDay
        }
        return disableValue?.displayString ?? ""
    }
}

