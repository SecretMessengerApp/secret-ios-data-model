// 
// 


@import WireSystem;

#import "NSNotification+ManagedObjectContextSave.h"


@implementation NSNotification (ManagedObjectContextSave)

- (void)enumerateInsertedObjectsWithEntityName:(NSString *)entityName withBlock:(void(^)(id mo))block;
{
    RequireString([self.name isEqualToString:NSManagedObjectContextDidSaveNotification],
                  "Wrong notification type.");
    
    if(!block) {
        return;
    }
    NSManagedObjectContext *moc = self.object;
    NSEntityDescription *entity = moc.persistentStoreCoordinator.managedObjectModel.entitiesByName[entityName];
    for(NSManagedObject* mo in self.userInfo[NSInsertedObjectsKey]) {
        if(mo.entity == entity) {
            block(mo);
        }
    }
}

- (void)enumerateUpdatedObjectsWithEntityName:(NSString *)entityName withBlock:(void(^)(id mo))block;
{
    NSAssert([self.name isEqualToString:NSManagedObjectContextDidSaveNotification], @"Wrong notification type: %@", self.name);

    if(!block) {
        return;
    }
    NSManagedObjectContext *moc = self.object;
    NSEntityDescription *entity = moc.persistentStoreCoordinator.managedObjectModel.entitiesByName[entityName];
    for(NSManagedObject* mo in self.userInfo[NSUpdatedObjectsKey]) {
        if(mo.entity == entity) {
            block(mo);
        }
    }
}

@end
