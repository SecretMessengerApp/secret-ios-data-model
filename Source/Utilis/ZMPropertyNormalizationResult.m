//
//

#import "ZMPropertyNormalizationResult.h"

@interface ZMPropertyNormalizationResult ()

@property (nonatomic, readwrite, getter=isValid) BOOL valid;
@property (nonatomic, readwrite, nullable) id normalizedValue;
@property (nonatomic, readwrite, nullable) NSError* validationError;

@end

@implementation ZMPropertyNormalizationResult

- (instancetype)initWithResult:(BOOL)valid normalizedValue:(id)normalizedValue validationError:(NSError *)validationError
{
    self = [super init];
    if (self) {
        self.valid = valid;
        self.normalizedValue = normalizedValue;
        self.validationError = validationError;
    }
    return self;
}

@end
