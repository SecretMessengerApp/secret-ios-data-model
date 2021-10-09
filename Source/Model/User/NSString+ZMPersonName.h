// 
// 


#import <Foundation/Foundation.h>

@interface NSString (ZMPersonName)

/// If the string starts with a number, return that prefix, otherwise return the first composed character.
- ( NSString * _Nullable )zmLeadingNumberOrFirstComposedCharacter;

- ( NSString * _Nullable )zmFirstComposedCharacter;
- ( NSString * _Nullable )zmSecondComposedCharacter;

- (BOOL)zmIsGodName;

@end
