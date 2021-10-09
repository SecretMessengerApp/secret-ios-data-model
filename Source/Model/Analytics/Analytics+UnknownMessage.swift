//
//


private let unknownMessageEventName = "debug.compatibility_unknown_message"


extension AnalyticsType {

    /// This method should be used to track messages which are not reported to 
    /// be `known`, c.f. `knownMessage` in `ZMGenericMessage+Utils.m`.
    func tagUnknownMessageReceived() {
        tagEvent(unknownMessageEventName)
    }

}


/// Objective-C compatibility wrapper for the unknown message event
class UnknownMessageAnalyticsTracker: NSObject {

    @objc(tagUnknownMessageWithAnalytics:)
    class func tagUnknownMessage(with analytics: AnalyticsType?) {
        analytics?.tagUnknownMessageReceived()
    }

}
