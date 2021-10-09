// 
// 


#import "ZMOrderedSetState+Internal.h"

#if __has_feature(objc_arc)
#error This file must be compiled without ARC / -fno-objc-arc
#endif



@implementation ZMOrderedSetState

- (instancetype)initWithOrderedSet:(NSOrderedSet *)orderedSet;
{
    self = [super init];
    if (self) {
        _state.resize(orderedSet.count);
        [orderedSet getObjects:(id *) _state.data() range:NSMakeRange(0, orderedSet.count)];
    }
    return self;
}

- (BOOL)isEqual:(id)object;
{
    if (! [object isKindOfClass:ZMOrderedSetState.class]) {
        return NO;
    }
    ZMOrderedSetState *other = object;
    return self->_state == other->_state;
}

- (NSString *)description
{
    NSMutableArray *items = [NSMutableArray array];
    std::for_each(_state.cbegin(), _state.cend(), [items](intptr_t const &v){
        [items addObject:[NSString stringWithFormat:@"%p", (void *) v]];
    });
    return [NSString stringWithFormat:@"<%@: %p> count = %zu, {%@}",
            self.class, self,
            _state.size(), [items componentsJoinedByString:@", "]];
}

@end



@implementation ZMOrderedSetState (ZMTrace)

- (intptr_t)traceSize;
{
    return (intptr_t) self->_state.size();
}

- (intptr_t *)traceState;
{
    return self->_state.data();
}

@end
