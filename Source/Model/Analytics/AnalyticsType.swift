//
//


import Foundation

@objc public protocol AnalyticsType: NSObjectProtocol {

    func tagEvent(_ event: String)
    func tagEvent(_ event: String, attributes: [String: NSObject])

    @objc(setPersistedAttributes:forEvent:)
    func setPersistedAttributes(_ attributes: [String: NSObject]?, for event: String)
    @objc(persistedAttributesForEvent:)
    func persistedAttributes(for event: String) -> [String: NSObject]?
}

// Used for debugging only
@objc public final class DebugAnalytics: NSObject, AnalyticsType {

    public func tagEvent(_ event: String) {
        print(Date(), "[ANALYTICS]", #function, event)
    }

    public func tagEvent(_ event: String, attributes: [String : NSObject]) {
        print(Date(), "[ANALYTICS]", #function, event, attributes)
    }

    var eventAttributes = [String : [String : NSObject]]()

    public func setPersistedAttributes(_ attributes: [String : NSObject]?, for event: String) {
        if let attributes = attributes {
            eventAttributes[event] = attributes
        } else {
            eventAttributes.removeValue(forKey: event)
        }
        print(Date(), "[ANALYTICS]", #function, event, eventAttributes[event] ?? [:])
    }

    public func persistedAttributes(for event: String) -> [String : NSObject]? {
        let value = eventAttributes[event] ?? [:]
        print(Date(), "[ANALYTICS]", #function, event, value)
        return value
    }
}
