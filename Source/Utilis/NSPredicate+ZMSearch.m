// 
// 


@import WireUtilities;

#import "NSPredicate+ZMSearch.h"


@implementation NSPredicate (ZMSearch)

+ (instancetype)predicateWithFormatDictionary:(NSDictionary *)formatDictionary matchingSearchString:(NSString *)searchString
{
    NSMutableArray *predicates = [NSMutableArray array];
    
    [searchString enumerateSubstringsInRange:NSMakeRange(0, searchString.length) options:NSStringEnumerationByWords usingBlock:^(NSString *substring, NSRange __unused substringRange, NSRange __unused enclosingRange, BOOL * __unused stop) {
        
        NSString *normalizedString = substring.normalizedString;
        NSString *regExp = [NSString stringWithFormat:@".*\\b%@.*", normalizedString];
        
        NSMutableArray *subPredicates = [NSMutableArray array];
        [formatDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *formatString, BOOL * __unused s) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:formatString, key, regExp];
            [subPredicates addObject:predicate];
        }];
        
        NSCompoundPredicate *predicate = [NSCompoundPredicate orPredicateWithSubpredicates:subPredicates];
        [predicates addObject:predicate];
    }];
    
    NSCompoundPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
    return predicate;
}

@end
