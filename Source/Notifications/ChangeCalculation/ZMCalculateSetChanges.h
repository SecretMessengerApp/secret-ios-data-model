// 
// 


#import <Foundation/Foundation.h>

#import <vector>
#import "ZMSetChangeMoveType.h"



extern bool ZMCalculateSetChangesWithType(std::vector<intptr_t> const &startState, std::vector<intptr_t> const &endState, std::vector<intptr_t> const &updatedState,
        std::vector<size_t> &deletedIndexes, std::vector<intptr_t> &deletedObjects, std::vector<size_t> &insertedIndexes, std::vector<size_t> &updatedIndexes,
        std::vector<std::pair<size_t, size_t>> &movedIndexes, ZMSetChangeMoveType const moveType);
