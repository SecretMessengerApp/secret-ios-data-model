// 
// 


#import "NSString+RandomString.h"

@implementation NSString (RandomString)

+ (NSString *)createAlphanumericalString;
{
    u_int64_t number = 0;
    arc4random_buf(&number, sizeof(u_int64_t));
    NSString *string = [NSString stringWithFormat:@"%llx", number % LONG_LONG_MAX];
    return string;
}

@end
