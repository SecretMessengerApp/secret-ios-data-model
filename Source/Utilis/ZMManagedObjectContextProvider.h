// 
// 


#import <Foundation/Foundation.h>

@class NSManagedObjectContext;

@protocol ZMManagedObjectContextProvider <NSObject>

@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readonly) NSManagedObjectContext *syncManagedObjectContext;

@end
