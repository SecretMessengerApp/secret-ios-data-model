//
//


#import "ZMUser.h"

@class Team;


@interface ZMUser (OneOnOne)

@property (nonatomic, nullable) ZMConversation *oneToOneConversation;

@end
