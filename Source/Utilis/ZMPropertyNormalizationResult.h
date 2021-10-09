//
//

#import <Foundation/Foundation.h>
#import "ZMUser.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * The result of a property normalization operation.
 */

@interface ZMPropertyNormalizationResult<Value> : NSObject

/// Whether the property is valid.
@property (nonatomic, readonly, getter=isValid) BOOL valid;

/// The value that was normalized during the operation.
@property (nonatomic, readonly, nullable) Value normalizedValue;

/// The error that reprsents the reason why the property is not valid.
@property (nonatomic, readonly, nullable) NSError* validationError;

- (instancetype)initWithResult:(BOOL)valid normalizedValue:(Value)normalizedValue validationError:(NSError * _Nullable )validationError;

@end

NS_ASSUME_NONNULL_END
