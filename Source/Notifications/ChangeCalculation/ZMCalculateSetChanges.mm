// 
// 


#import "ZMCalculateSetChanges.h"
#import <WireSystem/WireSystem.h>


bool ZMCalculateSetChangesWithType(std::vector<intptr_t> const &startState, std::vector<intptr_t> const &endState, std::vector<intptr_t> const &updatedState,
                                   std::vector<size_t> &deletedIndexes, std::vector<intptr_t> &deletedObjects, std::vector<size_t> &insertedIndexes, std::vector<size_t> &updatedIndexes,
        std::vector<std::pair<size_t, size_t>> &movedIndexes, ZMSetChangeMoveType const moveType)
{
    RequireC(deletedIndexes.size() == 0);
    RequireC(insertedIndexes.size() == 0);
    RequireC(updatedIndexes.size() == 0);
    RequireC(movedIndexes.size() == 0);
    RequireC(deletedObjects.size() == 0);
    
    
    // This keeps track of the state as we go through and modify it (delete, move...)
    std::vector<intptr_t> state(startState.cbegin(), startState.cend());

    // Create a sorted list of states that we can use binary search on to check if items have been deleted:
    std::vector<intptr_t> sortedEndState(endState.cbegin(), endState.cend());
    std::sort(sortedEndState.begin(), sortedEndState.end());
    auto containedInEnd = [&sortedEndState](intptr_t value) {
        return std::binary_search(sortedEndState.cbegin(), sortedEndState.cend(), value);
    };

    // First check which indexes have been deleted:
    {
        size_t idx = 0;
        auto stateIt = state.begin();
        std::for_each(startState.cbegin(), startState.cend(), [&](const intptr_t &value) {
            if (! containedInEnd(value)) {
                deletedIndexes.emplace_back(idx);
                deletedObjects.emplace_back(value);
                stateIt = state.erase(stateIt);
            } else {
                ++ stateIt;
            }
            ++ idx;
        });
    }

    // Create a sorted list of states that we can use binary search on to check if items have been inserted:
    std::vector<intptr_t> sortedStartState(startState.cbegin(), startState.cend());
    std::sort(sortedStartState.begin(), sortedStartState.end());
    auto containedInStart = [&sortedStartState](intptr_t value) {
        return std::binary_search(sortedStartState.cbegin(), sortedStartState.cend(), value);
    };

    // Check which indexes have been inserted:
    {
        size_t idx = 0;
        auto stateIt = state.begin();
        std::for_each(endState.cbegin(), endState.cend(), [&](const intptr_t &value) {
            if (! containedInStart(value)) {
                insertedIndexes.emplace_back(idx);
                stateIt = state.insert(stateIt, value);
            }
            ++ stateIt;
            ++ idx;
        });
    }

    // Check for moves
    if (moveType == ZMSetChangeMoveTypeNSTableView) {
        size_t idx = 0;
        auto endIt = endState.cbegin();
        for (auto stateIt = state.begin(); stateIt != state.end(); ++ stateIt, ++ endIt) {
            intptr_t const value = *stateIt;
            intptr_t const endValue = *endIt;
            if (endValue != value) {
                // Find new location:
                auto const loc = std::find(stateIt, state.end(), endValue);
                if (loc != state.cend()) {
                    ssize_t const otherIdx = loc - state.cbegin();
                    movedIndexes.emplace_back(otherIdx, idx);
                    state.erase(loc);
                    state.insert(stateIt, endValue);
                }
            }
            ++ idx;
        }
    } else if (moveType == ZMSetChangeMoveTypeUICollectionView) {
        auto endIt = endState.cbegin();
        for (ssize_t idx = 0; idx < (ssize_t) state.size(); ++ idx, ++ endIt) {
            //auto stateIt = state.begin(); stateIt != state.end(); ++stateIt, ++endIt) {
            auto stateIt = state.begin() + idx;
            intptr_t const value = *stateIt;
            intptr_t const endValue = *endIt;
            if (endValue != value) {
                // Find index in original set:
                auto loc = std::find(startState.cbegin(), startState.cend(), endValue);
                if (loc != startState.cend()) {
                    // Find location in current set and update:
                    auto loc2 = std::find(state.begin(), state.end(), endValue);
                    if (loc2 != state.end()) {
                        ssize_t const fromIdx = loc - startState.begin();
                        ssize_t const toIdx = stateIt - state.begin();
                        movedIndexes.emplace_back(fromIdx, toIdx);
                        //NSLog(@"%u -> %u   %u (%u)", (unsigned) fromIdx, (unsigned) idx, (unsigned) (loc - state.begin()), (unsigned) (state.end() - state.begin()));

                        state.erase(loc2);
                        state.insert(stateIt, endValue);
                    }
                }
            }
        }
    }

    // Indexes of updated:
    std::for_each(updatedState.cbegin(), updatedState.cend(), [&](const intptr_t &value) {
        auto loc = std::find(endState.cbegin(), endState.cend(), value);
        if (loc != endState.cend()) {
            ssize_t const idx = loc - endState.cbegin();
            updatedIndexes.emplace_back(idx);
        }
    });

    return true;
}
