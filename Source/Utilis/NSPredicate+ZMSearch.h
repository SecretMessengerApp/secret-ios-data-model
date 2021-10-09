// 
// 


@import Foundation;

@interface NSPredicate (ZMSearch)

+ (instancetype)predicateWithFormatDictionary:(NSDictionary *)formatDictionary
              matchingSearchString:(NSString *)searchString;

@end
