//
//


@import WireSystem;
@import WireUtilities;
@import WireTransport;

#import "ZMMessageTimer.h"
#import "ZMMessage+Internal.h"


@interface ZMMessageTimer () <ZMTimerClient>

@property (nonatomic) NSMapTable *objectToTimerMap;
@property (nonatomic) BOOL tearDownCalled;
@property (nonatomic, weak) NSManagedObjectContext *moc;

@end


@implementation ZMMessageTimer


ZM_EMPTY_ASSERTING_INIT()


- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)moc;
{
    self = [super init];
    if (self) {
        self.objectToTimerMap = [NSMapTable strongToStrongObjectsMapTable];
        self.moc = moc;
    }
    return self;
}

- (void)dealloc
{
    NSAssert(self.tearDownCalled == YES, @"Teardown was not called");
}

- (BOOL)hasMessageTimersRunning
{
    return self.objectToTimerMap.count > 0;
}

- (NSUInteger)runningTimersCount
{
    return [self.objectToTimerMap count];
}

- (void)startTimerForMessageIfNeeded:(ZMMessage*)message fireDate:(NSDate *)fireDate userInfo:(NSDictionary *)userInfo
{
    if ( ![self isTimerRunningForMessage:message] ) {
        ZMTimer *timer = [ZMTimer timerWithTarget:self];
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithDictionary:userInfo ?: @{}];
        info[@"message"] = message;
        timer.userInfo = [NSDictionary dictionaryWithDictionary:info];
        [self.objectToTimerMap setObject:timer forKey:message];
        
        [timer fireAtDate:fireDate];
    }

}

- (BOOL)isTimerRunningForMessage:(ZMMessage *)message
{
    return [self timerForMessage:message] != nil;
}

- (void)timerDidFire:(ZMTimer *)timer
{
    ZMMessage *message = timer.userInfo[@"message"];
    
    NSManagedObjectContext *strongMoc = self.moc;
    RequireString(strongMoc != nil, "MOC is nil");
    
    [message.managedObjectContext performGroupedBlock:^{
        
        if (message == nil || message.isZombieObject) {
            return;
        }
        if (self.timerCompletionBlock != nil) {
            self.timerCompletionBlock(message, timer.userInfo);
        }

        // it's important to remove timer last, b/c in the case we're in the background
        // we want to call endActivity after the completion block finishes.
        [self removeTimerForMessage:message];
    }];
    
}

- (void)stopTimerForMessage:(ZMMessage *)message;
{
    ZMTimer *timer = [self timerForMessage:message];
    if(timer == nil) {
        return;
    }
    
    [timer cancel];
    [self removeTimerForMessage:message];
}


- (void)removeTimerForMessage:(ZMMessage *)message {
    [self.objectToTimerMap removeObjectForKey:message];
}

- (ZMTimer *)timerForMessage:(ZMMessage *)message
{
    return [self.objectToTimerMap objectForKey:message];
}

- (void)tearDown;
{
    for (ZMTimer *timer in self.objectToTimerMap.objectEnumerator) {
        [timer cancel];
    }
    [self.objectToTimerMap removeAllObjects];
    
    self.tearDownCalled = YES;
}

@end
