//
//


import Foundation

extension ZMConversation {
    
    @objc public func deleteOlderMessages() {
        
        guard let managedObjectContext = self.managedObjectContext,
              let clearedTimeStamp = self.clearedTimeStamp,
              !managedObjectContext.zm_isUserInterfaceContext else {
            return
        }
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ZMMessage.entityName())
        fetchRequest.predicate = NSPredicate(format: "(%K == %@ OR %K == %@) AND %K <= %@",
                                             ZMMessageConversationKey, self,
                                             ZMMessageHiddenInConversationKey, self,
                                             #keyPath(ZMMessage.serverTimestamp),
                                             clearedTimeStamp as CVarArg)
        
        let result = try! managedObjectContext.fetch(fetchRequest) as! [ZMMessage]
        
        for element in result {
            managedObjectContext.delete(element)
        }
        
    }
    
    @objc static public func deleteOlderNeedlessMessages(moc: NSManagedObjectContext) {
        
        //1. (selfConversation)
        let selfConversation = ZMConversation.selfConversation(in: moc)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ZMMessage.entityName())
        fetchRequest.predicate = NSPredicate(format: "%K == %@",
                                              ZMMessageConversationKey, selfConversation)
        let request = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        request.resultType = .resultTypeStatusOnly
        try! moc.execute(request)
        
        //2. TODO
        
    }
    
    //TEST
    @objc static public func lookMessages(moc: NSManagedObjectContext) {
        
//        let managedObjectContext = moc
//        guard !managedObjectContext.zm_isUserInterfaceContext else {
//            return
//        }
        
        //        let fetchRequest1 = NSFetchRequest<NSFetchRequestResult>(entityName: ZMMessage.entityName())
        //
        //        let result1 = try! managedObjectContext.fetch(fetchRequest1) as! [ZMMessage]
        //
       
        //
        //
        //        let fetchRequest2 = NSFetchRequest<NSFetchRequestResult>(entityName: ZMMessage.entityName())
        //
        //        fetchRequest2.predicate = NSPredicate(format: "%K != nil",
        //                                             ZMMessageHiddenInConversationKey)
        //
        //        let result2 = try! managedObjectContext.fetch(fetchRequest2) as! [ZMMessage]
        //
        
//                let selfConversation = ZMConversation.selfConversation(in: moc)
//
//                let fetchRequest3 = NSFetchRequest<NSFetchRequestResult>(entityName: ZMMessage.entityName())
//
//                fetchRequest3.predicate = NSPredicate(format: "%K == %@",
//                                                      ZMMessageConversationKey, selfConversation)
//
//                let result3 = try! managedObjectContext.fetch(fetchRequest3) as! [ZMMessage]
//

        
//                let fetchRequest4 = NSFetchRequest<NSFetchRequestResult>(entityName: ZMSystemMessage.entityName())
//
//                let result4 = try! managedObjectContext.fetch(fetchRequest4) as! [ZMSystemMessage]
//

        
        //        let fetchRequest5 = NSFetchRequest<NSFetchRequestResult>(entityName: ZMMessage.entityName())
        //
        //        fetchRequest5.predicate = NSPredicate(format: "%K != nil",
        //                                              ZMMessageConversationKey)
        //
        //        let result5 = try! managedObjectContext.fetch(fetchRequest5) as! [ZMMessage]
        //

        
//        let fetchRequest6 = NSFetchRequest<NSFetchRequestResult>(entityName: ZMMessage.entityName())
//
//        fetchRequest6.predicate = NSPredicate(format: "visibleInConversation.conversationType = 5")
//
//        let result6 = try! managedObjectContext.fetch(fetchRequest6) as! [ZMMessage]
//
        
//        let fetchRequest7 = NSFetchRequest<NSFetchRequestResult>(entityName: ZMSystemMessage.entityName())
//
//        fetchRequest7.predicate = NSPredicate(format: "visibleInConversation.conversationType = 5")
//
//        let result7 = try! managedObjectContext.fetch(fetchRequest7) as! [ZMSystemMessage]
//

    }
}
