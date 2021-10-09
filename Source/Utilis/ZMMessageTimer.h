//
//

#import <Foundation/Foundation.h>

@class ZMMessage;


@interface ZMMessageTimer : NSObject <TearDownCapable>

@property (nonatomic, readonly) BOOL hasMessageTimersRunning;
@property (nonatomic, readonly) NSUInteger runningTimersCount;
@property (nonatomic, weak, readonly) NSManagedObjectContext *moc;

///  The block to be executed when the timer fires. The block is executed in a performBlock of the specified context. The message returned from this block is guaranteed to exist.
@property (nonatomic, copy) void(^timerCompletionBlock)(ZMMessage *, NSDictionary*);

/// Creates an object that can create timers for messages. It handles timer creation, firing and teardown
/// @managedObjectContext The context on which changes are supposed to be performed on timer firing.
- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;



/// Starts a new timer if there is no existing one
/// @param fireDate The date at which the timer should fire
/// @param userInfo Additional info that should be added to the timer
- (void)startTimerForMessageIfNeeded:(ZMMessage*)message fireDate:(NSDate *)fireDate userInfo:(NSDictionary *)userInfo;


/// Stops an existing timer
- (void)stopTimerForMessage:(ZMMessage *)message;

/// You need to call tearDown, otherwise the object will never be deallocated
- (void)tearDown;

/// Returns YES if there is a timer for this message
- (BOOL)isTimerRunningForMessage:(ZMMessage *)message;

/// Returns the timer created for this message
- (ZMTimer *)timerForMessage:(ZMMessage *)message;

@end
